# Event-Driven RAG Agent

Fine-tune an open LLM with enterprise data, host it on Azure, then build a RAG solution that queries it.

## Architecture Overview

This project implements an event-driven RAG pipeline that:
1. **Ingests** data from Confluence Cloud
2. **Indexes** content into Azure AI Search via event-driven workers
3. **Queries** the index for retrieval-augmented generation

---

## Setup & Configuration

### 1. Confluence Cloud Webhook Setup

Configure a webhook using Confluence Automation to trigger on page changes:

1. Go to **Confluence Settings → Automation**
2. Create a new rule
3. Set trigger to "Page updated" (create separate rules for created/deleted)
4. Add action "Send web request"
5. Set your Azure Webhook Function App's URL as the endpoint
   - _The webhook acts as the HTTP adapter between Confluence and Service Bus_

### 2. Provision Azure Service Bus with Terraform

The system uses a **Queue** (not topics) since there's only one consumer (the indexing worker).

See [infra/modules/service_bus/](infra/modules/service_bus/) for configuration.

### 3. Provision Azure Function App with Terraform

See [infra/modules/functions/](infra/modules/functions/) for configuration.

#### Install Azure Functions Core Tools

```bash
npm install -g azure-functions-core-tools@4 --unsafe-perm true
```

#### Deploy Webhook Receiver to Function App
```bash
func azure functionapp publish <azurerm_linux_function_app.label.name>
```

### 4. Provision Azure Search AI with Terraform

Run the create_index.py script to create an index
``` bash
python create_index.py
```
The same can be done via a CI/CD pipeline before deploying the Azure Function App

#### How the Azure AI Search works internally:
One request to "confluence-pages" index
        │
        ├── BM25 search on "content" and "title" fields
        │       → returns keyword-matched results with BM25 scores
        │
        └── Vector search on "content_vector" field
                → returns semantically similar results with cosine scores
                │
                ▼
        RRF (Reciprocal Rank Fusion)
        merges and re-ranks both result sets
                │
                ▼
        Single merged result list returned