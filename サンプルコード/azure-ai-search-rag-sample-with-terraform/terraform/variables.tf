variable "search_service_name" {
  description = "Existing Azure AI Search service name. Do not include https:// or .search.windows.net."
  type        = string
}

variable "storage_connection_string" {
  description = "Azure Storage connection string used by the Azure Blob data source. Prefer supplying this through TF_VAR_storage_connection_string or a secret CI variable."
  type        = string
  sensitive   = true
}

variable "storage_container_name" {
  description = "Blob container containing the RAG source documents."
  type        = string
  default     = "rag-documents"
}

variable "azure_ai_resource_uri" {
  description = "Azure AI / Azure OpenAI resource URI used for embeddings, for example https://my-ai-resource.services.ai.azure.com."
  type        = string
}

variable "azure_ai_api_key" {
  description = "API key used by AzureOpenAIEmbeddingSkill and the query-time vectorizer. Prefer managed identity in production where supported."
  type        = string
  sensitive   = true
}

variable "embedding_deployment_name" {
  description = "Embedding deployment name."
  type        = string
  default     = "text-embedding-3-small"
}

variable "embedding_model_name" {
  description = "Embedding model name."
  type        = string
  default     = "text-embedding-3-small"
}

variable "embedding_dimensions" {
  description = "Embedding vector dimensions."
  type        = number
  default     = 1536
}

variable "default_language_code" {
  description = "Language code used by SplitSkill."
  type        = string
  default     = "ja"
}

variable "chunk_length" {
  description = "Maximum chunk length in characters."
  type        = number
  default     = 1000
}

variable "chunk_overlap" {
  description = "Chunk overlap in characters."
  type        = number
  default     = 200
}

variable "data_source_name" {
  type    = string
  default = "rag-sample-datasource"
}

variable "index_name" {
  type    = string
  default = "rag-sample-index"
}

variable "skillset_name" {
  type    = string
  default = "rag-sample-skillset"
}

variable "indexer_name" {
  type    = string
  default = "rag-sample-indexer"
}

variable "enable_debug_index" {
  description = "Create the debug index/skillset/indexer that stores and returns raw embedding vectors."
  type        = bool
  default     = true
}

variable "debug_index_name" {
  type    = string
  default = "rag-sample-index-debug"
}

variable "debug_skillset_name" {
  type    = string
  default = "rag-sample-skillset-debug"
}

variable "debug_indexer_name" {
  type    = string
  default = "rag-sample-indexer-debug"
}
