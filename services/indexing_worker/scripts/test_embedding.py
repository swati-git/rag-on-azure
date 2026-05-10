import os
from dotenv import load_dotenv
from openai import AzureOpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider

load_dotenv()

print(f"Endpoint:         {os.environ.get('azure_openai_endpoint')}")
print(f"Deployment:       {os.environ.get('AZURE_OPENAI_EMBEDDING_MODEL')}")


token_provider = get_bearer_token_provider(
    DefaultAzureCredential(),
    "https://cognitiveservices.azure.com/.default"
)

client = AzureOpenAI(
    azure_endpoint=os.environ["azure_openai_endpoint"],
    azure_ad_token_provider=token_provider,
    api_version="2024-06-01"
)


response = client.embeddings.create(
    model=os.environ["AZURE_OPENAI_EMBEDDING_MODEL"],
    input=["This is a test sentence from a Confluence page."]
)

vector = response.data[0].embedding
print(f"✅ Embedding model works")
print(f"   Vector dimensions: {len(vector)}")   # should be 1536
print(f"   First 5 values:    {vector[:5]}")