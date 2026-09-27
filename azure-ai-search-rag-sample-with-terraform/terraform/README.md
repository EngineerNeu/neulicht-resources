# Terraform: Azure AI Search RAG data plane

This directory manages the Azure AI Search RAG **data-plane objects** used by the sample:

- Blob data source
- Main RAG index
- Split + embedding skillset
- Indexer
- Optional debug index/skillset/indexer for inspecting raw embedding vectors

It uses the `Azure/azapi` provider and `azapi_data_plane_resource`.

## Why AzAPI?

The AzureRM Search resource manages the Search **service** itself (control plane). The RAG objects inside the service are data-plane resources. AzAPI can manage Azure AI Search data sources, indexes, skillsets, indexers, and synonym maps directly through the Search endpoint.

This sample uses `2026-08-01-preview`, matching the preview/Serverless workflow used by the exercise.

## Prerequisites

1. Terraform 1.5+.
2. Azure CLI login or another AzAPI-supported Azure authentication method.
3. An existing Azure AI Search service.
4. An existing Azure Blob container containing source documents.
5. An Azure AI / Azure OpenAI embedding deployment.
6. The Terraform identity needs permission to create and manage Search objects. `Search Service Contributor` is the built-in role for object management.

## Configure

```bash
cp terraform.tfvars.example terraform.tfvars
```

Do not commit real secrets.

Prefer environment variables for secret inputs:

```bash
export TF_VAR_storage_connection_string='DefaultEndpointsProtocol=...'
export TF_VAR_azure_ai_api_key='...'
```

## Deploy

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Creating the indexer resource defines the indexer. Treat **run/reset** as operational actions rather than resources that should execute on every Terraform apply.

## Import manually created Search objects

If the Search objects already exist because they were created in the portal, import them before Terraform starts managing them.

```bash
cp imports.tf.example imports.tf
```

Replace the placeholder service/resource names, then:

```bash
terraform plan
terraform apply
```

Terraform 1.5+ import blocks can adopt those existing data-plane resources.

## Secret and state security

The GitHub sample contains no real secrets, but live deployments still pass a Storage connection string and Azure AI API key into Search object definitions.

Treat Terraform state as sensitive:

- use an encrypted remote backend,
- restrict state access,
- never commit state files,
- use CI/CD secret variables or environment variables,
- prefer Microsoft Entra ID / managed identity where supported.

`ignore_missing_property = true` is used where Azure AI Search can omit secret properties when resources are read back.

## Debug index

With `enable_debug_index = true`, the debug vector field uses:

```hcl
retrievable = true
stored      = true
```

This is intended for learning and inspection so Search Explorer can return the raw 1536-dimensional vector.

The main index uses:

```hcl
retrievable = false
stored      = false
```

because normal RAG retrieval doesn't need to return raw embeddings.

## Architecture

```text
Azure Blob Storage
       |
       v
rag-sample-datasource
       |
       v
rag-sample-indexer
       |
       v
rag-sample-skillset
  | SplitSkill
  | AzureOpenAIEmbeddingSkill
       |
       v
rag-sample-index
  | BM25
  | HNSW vector search
  | query-time Azure OpenAI vectorizer
  v
Hybrid retrieval

Optional debug path:
rag-sample-indexer-debug
       |
       v
rag-sample-skillset-debug
       |
       v
rag-sample-index-debug
(raw vector stored + retrievable)
```
