# Azure AI Search RAG JSON samples

Sanitized sample JSON files for an Azure AI Search RAG pipeline using Azure Blob Storage, chunking, Azure OpenAI embeddings, vector search, and hybrid search.

## Files

- `data-source.sample.json` - Azure Blob Storage data source
- `index.sample.json` - Main RAG index with HNSW and a query-time Azure OpenAI vectorizer
- `skillset.sample.json` - Split + embedding skillset with index projections
- `indexer.sample.json` - Indexer connecting data source, skillset, and index
- `index-debug.sample.json` - Debug index that stores and returns raw embedding vectors
- `skillset-debug.sample.json` - Skillset targeting the debug index
- `indexer-debug.sample.json` - Debug indexer
- `queries/` - Keyword, vector, hybrid, and raw-vector inspection query examples

## Replace these placeholders before use

- `<AZURE_STORAGE_CONNECTION_STRING>`
- `<AZURE_AI_RESOURCE_NAME>`
- `<AZURE_AI_API_KEY>`

Do not commit real keys, connection strings, tokens, subscription IDs, tenant IDs, personal names, email addresses, resource group names, or production endpoints.

## Security note

These files intentionally use placeholders. For production, prefer Microsoft Entra ID / managed identity where supported instead of long-lived keys. Keep secrets in Azure Key Vault or another secret store rather than source control.

## Pipeline

```text
Azure Blob Storage
  -> Data Source
  -> Indexer
  -> Skillset
       -> SplitSkill
       -> AzureOpenAIEmbeddingSkill
  -> Index Projection
  -> Azure AI Search Index
       -> BM25 keyword search
       -> HNSW vector search
       -> Hybrid search (RRF)
```

## Debug index

`index-debug.sample.json` deliberately sets the vector field to:

```json
"retrievable": true,
"stored": true
```

This is useful for learning and inspection because raw embedding values can be returned. For a normal RAG index, the main sample uses `retrievable: false` and `stored: false` to avoid returning raw vectors unnecessarily.

## Notes

- Embedding model: `text-embedding-3-small`
- Vector dimensions: `1536`
- Similarity metric: `cosine`
- HNSW parameters in the sample: `m=4`, `efConstruction=400`, `efSearch=500`
- Chunking sample: `1000` characters with `200` characters overlap

Adjust chunk size, overlap, `k`, metadata filters, semantic ranking, and HNSW parameters based on your own evaluation set and workload.


## Terraform

The `terraform/` directory contains an IaC version of the same RAG data-plane configuration using the Azure AzAPI provider.

See `terraform/README.md` for configuration, deployment, import, and secret/state guidance.
