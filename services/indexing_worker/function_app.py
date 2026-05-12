import json
import logging
import os
import hashlib
import re
import azure.functions as func
from azure.search.documents import SearchClient
from datetime import datetime

app = func.FunctionApp()
logger = logging.getLogger(__name__)

def get_env(key: str) -> str:
    val = os.environ.get(key)
    if not val:
        raise ValueError(f"Missing required environment variable: {key}")
    return val

def strip_html(html: str) -> str:
    from bs4 import BeautifulSoup
    text = BeautifulSoup(html, "html.parser").get_text(separator=" ", strip=True)
    text = re.sub(r"\s+", " ", text)
    return text.strip()

def chunk_text(text: str, chunk_size: int = 500, overlap: int = 50) -> list[str]:
    """
    Split text into overlapping chunks by word count.
    chunk_size: target words per chunk
    overlap:    words shared between consecutive chunks
    """
    words  = text.split()
    chunks = []
    start  = 0
    while start < len(words):
        end = start + chunk_size
        chunks.append(" ".join(words[start:end]))
        start += chunk_size - overlap
    return [c for c in chunks if len(c.strip()) > 50]  # drop tiny trailing chunks

def content_hash(text: str) -> str:
    return hashlib.md5(text.encode()).hexdigest()

def fetch_page(page_id: str) -> dict:
    import requests
    from base64 import b64encode

    base_url  = get_env("CONFLUENCE_BASE_URL")
    email     = get_env("CONFLUENCE_EMAIL")
    api_token = get_env("CONFLUENCE_API_TOKEN")

    token  = b64encode(f"{email}:{api_token}".encode()).decode()
    headers = {
        "Authorization": f"Basic {token}",
        "Accept":        "application/json"
    }

    url = (
        f"{base_url}/wiki/rest/api/content/{page_id}"
        f"?expand=body.storage,version,space"
    )
    response = requests.get(url, headers=headers, timeout=30)
    response.raise_for_status()
    page = response.json()

    return {
        "page_id":   page["id"],
        "title":     page["title"],
        "space_key": page["space"]["key"],
        "version":   page["version"]["number"],
        "url":       f"{base_url}/wiki{page['_links']['webui']}",
        "content":   strip_html(page["body"]["storage"]["value"])
    }

def get_search_client():
    from azure.search.documents import SearchClient
    from azure.identity import DefaultAzureCredential
    return SearchClient(
        endpoint=get_env("SEARCH_ENDPOINT"),
        index_name=get_env("SEARCH_INDEX_NAME"),
        credential=DefaultAzureCredential()
    )

def delete_page_chunks(search_client, page_id: str):
    results = search_client.search(
        search_text="*",
        filter=f"page_id eq '{page_id}'",
        select=["id"]
    )
    chunk_ids = [doc["id"] for doc in results]
    if chunk_ids:
        search_client.delete_documents(
            documents=[{"id": cid} for cid in chunk_ids]
        )
        logger.info(f"Deleted {len(chunk_ids)} chunks for page {page_id}")

def get_stored_hash(search_client, page_id: str) -> str | None:
    """Retrieve the content hash stored from the last indexing run."""
    logger.info(f"Checking existing hash for page {page_id}")
    results = search_client.search(
        search_text="*",
        filter=f"page_id eq '{page_id}'",
        select=["content_hash"],
        top=1
    )
    for doc in results:
        return doc.get("content_hash")
    return None

def embed_chunks(chunks: list[str]) -> list[list[float]]:
    from openai import AzureOpenAI
    from azure.identity import DefaultAzureCredential, get_bearer_token_provider

    token_provider = get_bearer_token_provider(
        DefaultAzureCredential(),
        "https://cognitiveservices.azure.com/.default"   # scope for Azure OpenAI
    )


    logger.info(f"MAKING EMBEDDING API CALL for {len(chunks)} chunks")
    client = AzureOpenAI(
        azure_endpoint=get_env("AZURE_OPENAI_ENDPOINT"),
        azure_ad_token_provider=token_provider,         
        api_version="2024-06-01"
    )

    response = client.embeddings.create(
        model=get_env("AZURE_OPENAI_EMBEDDING_MODEL"),
        input=chunks
    )
    return [item.embedding for item in response.data]

# ── indexing logic ─────────────────────────────────────────────────────────────

def index_page(page_id: str, search_client):
    """Fetch, chunk, embed and upsert a page into Azure AI Search."""

    page = fetch_page(page_id)

    new_hash    = content_hash(page["content"])
    stored_hash = get_stored_hash(search_client, page_id)

    # if new_hash == stored_hash:
    #     logger.info(f"Page {page_id} content unchanged — skipping")
    #     return

    #delete_page_chunks(search_client, page_id)

    chunks = chunk_text(page["content"])
    if not chunks:
        logger.warning(f"Page {page_id} produced no chunks — possibly empty")
        return

    # embed all chunks in one API call
    logger.info(f"Making embedding API call for {page_id}")
    vectors = embed_chunks(chunks)
    logger.info(f"received vectors API call for {len(vectors)} chunks for {page_id}  ")

    # build documents for upsert
    documents = [
        {
            "id":             f"page_{page_id}_chunk_{i}",
            "page_id":        page["page_id"],
            "space_key":      page["space_key"],
            "title":          page["title"],
            "url":            page["url"],
            "content":        chunk,
            "content_hash":   new_hash,     # same hash on all chunks for easy lookup
            "content_vector": vector,
        }
        for i, (chunk, vector) in enumerate(zip(chunks, vectors))
    ]

    search_client.upload_documents(documents=documents)
    logger.info(
        f"Indexed page '{page['title']}' ({page_id}) — "
        f"{len(chunks)} chunks, hash {new_hash[:8]}"
    )

@app.function_name("ConfluenceIndexer") 
@app.service_bus_queue_trigger(
    arg_name="msg",
    queue_name="%SERVICE_BUS_QUEUE_NAME%",
    connection="SERVICE_BUS_CONNECTION_STR"
)
def indexing_worker(msg: func.ServiceBusMessage):
    """
    Triggered automatically when a message arrives on the Service Bus queue.
    Processes page_created, page_updated, page_removed, page_trashed events.
    """

    logging.info(f"{'='*60}")
    logging.info(f"✓ FUNCTION TRIGGERED: {datetime.now()}")
    logging.info(f"{'='*60}")

    try:
        payload    = json.loads(msg.get_body().decode("utf-8"))
        logging.info(f"  Message: {json.dumps(payload, indent=2)}")
        event_type = payload["event_type"]
        page_id    = payload["page_id"]
        title      = payload.get("title", "unknown")

        logger.info(f"Processing {event_type} for page '{title}' ({page_id})")

        search_client: SearchClient = get_search_client()

        if event_type in ("page_removed", "page_trashed"):
            delete_page_chunks(search_client, page_id)

        elif event_type == "page_created":
            index_page(page_id, search_client)

        elif event_type == "page_updated":
            index_page(page_id, search_client)

        else:
            logger.warning(f"Unknown event type: {event_type} — skipping")

    except Exception as e:
        logger.error(f"Failed to process message: {e}", exc_info=True)
        # re-raise so Service Bus knows the message failed
        # it will retry up to max_delivery_count (5) times
        # after that it goes to the dead letter queue
        raise