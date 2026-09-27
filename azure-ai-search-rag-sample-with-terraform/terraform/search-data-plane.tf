# Azure AI Search data-plane resources are managed with the AzAPI data-plane
# framework. This is useful for indexes, data sources, skillsets, and indexers,
# including preview API versions that aren't modeled by azurerm resources.

resource "azapi_data_plane_resource" "data_source" {
  type      = "Microsoft.Search/searchServices/datasources@2026-08-01-preview"
  parent_id = local.search_parent_id
  name      = var.data_source_name

  body = {
    type = "azureblob"
    credentials = {
      connectionString = var.storage_connection_string
    }
    container = {
      name = var.storage_container_name
    }
  }

  ignore_missing_property = true
}

resource "azapi_data_plane_resource" "index" {
  type      = "Microsoft.Search/searchServices/indexes@2026-08-01-preview"
  parent_id = local.search_parent_id
  name      = var.index_name

  body = {
    fields = [
      {
        name        = "chunk_id"
        type        = "Edm.String"
        key         = true
        searchable  = true
        filterable  = true
        retrievable = true
        analyzer    = "keyword"
      },
      {
        name        = "parent_id"
        type        = "Edm.String"
        searchable  = false
        filterable  = true
        retrievable = true
      },
      {
        name        = "title"
        type        = "Edm.String"
        searchable  = true
        filterable  = true
        sortable    = true
        retrievable = true
        analyzer    = "ja.microsoft"
      },
      {
        name        = "chunk"
        type        = "Edm.String"
        searchable  = true
        retrievable = true
        analyzer    = "ja.microsoft"
      },
      {
        name        = "source_path"
        type        = "Edm.String"
        filterable  = true
        retrievable = true
      },
      {
        name                = "chunk_vector"
        type                = "Collection(Edm.Single)"
        searchable          = true
        retrievable         = false
        stored              = false
        dimensions          = var.embedding_dimensions
        vectorSearchProfile = "rag-hnsw-profile"
      }
    ]

    vectorSearch = {
      algorithms = [
        {
          name = "rag-hnsw"
          kind = "hnsw"
          hnswParameters = {
            metric         = "cosine"
            m              = 4
            efConstruction = 400
            efSearch       = 500
          }
        }
      ]

      profiles = [
        {
          name       = "rag-hnsw-profile"
          algorithm  = "rag-hnsw"
          vectorizer = "rag-openai-vectorizer"
        }
      ]

      vectorizers = [
        {
          name = "rag-openai-vectorizer"
          kind = "azureOpenAI"
          azureOpenAIParameters = {
            resourceUri  = local.azure_ai_resource_uri
            deploymentId = var.embedding_deployment_name
            modelName    = var.embedding_model_name
            apiKey       = var.azure_ai_api_key
          }
        }
      ]
    }
  }

  ignore_missing_property = true
}

resource "azapi_data_plane_resource" "skillset" {
  type      = "Microsoft.Search/searchServices/skillsets@2026-08-01-preview"
  parent_id = local.search_parent_id
  name      = var.skillset_name

  body = {
    description = "Sample skillset that chunks documents and generates embeddings."

    skills = [
      {
        "@odata.type"       = "#Microsoft.Skills.Text.SplitSkill"
        name                = "split-document"
        context             = "/document"
        defaultLanguageCode = var.default_language_code
        textSplitMode       = "pages"
        maximumPageLength   = var.chunk_length
        pageOverlapLength   = var.chunk_overlap
        maximumPagesToTake  = 0
        unit                = "characters"

        inputs = [
          {
            name   = "text"
            source = "/document/content"
          }
        ]

        outputs = [
          {
            name       = "textItems"
            targetName = "pages"
          }
        ]
      },
      {
        "@odata.type" = "#Microsoft.Skills.Text.AzureOpenAIEmbeddingSkill"
        name          = "embed-chunks"
        context       = "/document/pages/*"
        resourceUri   = local.azure_ai_resource_uri
        apiKey        = var.azure_ai_api_key
        deploymentId  = var.embedding_deployment_name
        dimensions    = var.embedding_dimensions
        modelName     = var.embedding_model_name

        inputs = [
          {
            name   = "text"
            source = "/document/pages/*"
          }
        ]

        outputs = [
          {
            name       = "embedding"
            targetName = "chunk_vector"
          }
        ]
      }
    ]

    indexProjections = {
      selectors = [
        {
          targetIndexName    = var.index_name
          parentKeyFieldName = "parent_id"
          sourceContext      = "/document/pages/*"

          mappings = [
            {
              name   = "chunk"
              source = "/document/pages/*"
            },
            {
              name   = "chunk_vector"
              source = "/document/pages/*/chunk_vector"
            },
            {
              name   = "title"
              source = "/document/metadata_storage_name"
            },
            {
              name   = "source_path"
              source = "/document/metadata_storage_path"
            }
          ]
        }
      ]

      parameters = {
        projectionMode = "skipIndexingParentDocuments"
      }
    }
  }

  ignore_missing_property = true

  depends_on = [
    azapi_data_plane_resource.index
  ]
}

resource "azapi_data_plane_resource" "indexer" {
  type      = "Microsoft.Search/searchServices/indexers@2026-08-01-preview"
  parent_id = local.search_parent_id
  name      = var.indexer_name

  body = {
    dataSourceName  = var.data_source_name
    targetIndexName = var.index_name
    skillsetName    = var.skillset_name

    parameters = {
      configuration = {
        dataToExtract = "contentAndMetadata"
        parsingMode   = "default"
      }
    }
  }

  depends_on = [
    azapi_data_plane_resource.data_source,
    azapi_data_plane_resource.index,
    azapi_data_plane_resource.skillset
  ]
}

# Optional debug pipeline.
# The debug index intentionally stores and exposes the raw embedding vector.

resource "azapi_data_plane_resource" "debug_index" {
  count = var.enable_debug_index ? 1 : 0

  type      = "Microsoft.Search/searchServices/indexes@2026-08-01-preview"
  parent_id = local.search_parent_id
  name      = var.debug_index_name

  body = {
    fields = [
      {
        name        = "chunk_id"
        type        = "Edm.String"
        key         = true
        searchable  = true
        filterable  = true
        retrievable = true
        analyzer    = "keyword"
      },
      {
        name        = "parent_id"
        type        = "Edm.String"
        searchable  = false
        filterable  = true
        retrievable = true
      },
      {
        name        = "title"
        type        = "Edm.String"
        searchable  = true
        filterable  = true
        retrievable = true
        analyzer    = "ja.microsoft"
      },
      {
        name        = "chunk"
        type        = "Edm.String"
        searchable  = true
        retrievable = true
        analyzer    = "ja.microsoft"
      },
      {
        name        = "source_path"
        type        = "Edm.String"
        filterable  = true
        retrievable = true
      },
      {
        name                = "chunk_vector"
        type                = "Collection(Edm.Single)"
        searchable          = true
        retrievable         = true
        stored              = true
        dimensions          = var.embedding_dimensions
        vectorSearchProfile = "rag-hnsw-profile"
      }
    ]

    vectorSearch = {
      algorithms = [
        {
          name = "rag-hnsw"
          kind = "hnsw"
          hnswParameters = {
            metric         = "cosine"
            m              = 4
            efConstruction = 400
            efSearch       = 500
          }
        }
      ]

      profiles = [
        {
          name      = "rag-hnsw-profile"
          algorithm = "rag-hnsw"
        }
      ]
    }
  }
}

resource "azapi_data_plane_resource" "debug_skillset" {
  count = var.enable_debug_index ? 1 : 0

  type      = "Microsoft.Search/searchServices/skillsets@2026-08-01-preview"
  parent_id = local.search_parent_id
  name      = var.debug_skillset_name

  body = {
    description = "Debug skillset for inspecting raw embedding vectors."

    skills = [
      {
        "@odata.type"       = "#Microsoft.Skills.Text.SplitSkill"
        name                = "split-document"
        context             = "/document"
        defaultLanguageCode = var.default_language_code
        textSplitMode       = "pages"
        maximumPageLength   = var.chunk_length
        pageOverlapLength   = var.chunk_overlap
        maximumPagesToTake  = 0
        unit                = "characters"

        inputs = [
          {
            name   = "text"
            source = "/document/content"
          }
        ]

        outputs = [
          {
            name       = "textItems"
            targetName = "pages"
          }
        ]
      },
      {
        "@odata.type" = "#Microsoft.Skills.Text.AzureOpenAIEmbeddingSkill"
        name          = "embed-chunks"
        context       = "/document/pages/*"
        resourceUri   = local.azure_ai_resource_uri
        apiKey        = var.azure_ai_api_key
        deploymentId  = var.embedding_deployment_name
        dimensions    = var.embedding_dimensions
        modelName     = var.embedding_model_name

        inputs = [
          {
            name   = "text"
            source = "/document/pages/*"
          }
        ]

        outputs = [
          {
            name       = "embedding"
            targetName = "chunk_vector"
          }
        ]
      }
    ]

    indexProjections = {
      selectors = [
        {
          targetIndexName    = var.debug_index_name
          parentKeyFieldName = "parent_id"
          sourceContext      = "/document/pages/*"

          mappings = [
            {
              name   = "chunk"
              source = "/document/pages/*"
            },
            {
              name   = "chunk_vector"
              source = "/document/pages/*/chunk_vector"
            },
            {
              name   = "title"
              source = "/document/metadata_storage_name"
            },
            {
              name   = "source_path"
              source = "/document/metadata_storage_path"
            }
          ]
        }
      ]

      parameters = {
        projectionMode = "skipIndexingParentDocuments"
      }
    }
  }

  ignore_missing_property = true

  depends_on = [
    azapi_data_plane_resource.debug_index
  ]
}

resource "azapi_data_plane_resource" "debug_indexer" {
  count = var.enable_debug_index ? 1 : 0

  type      = "Microsoft.Search/searchServices/indexers@2026-08-01-preview"
  parent_id = local.search_parent_id
  name      = var.debug_indexer_name

  body = {
    dataSourceName  = var.data_source_name
    targetIndexName = var.debug_index_name
    skillsetName    = var.debug_skillset_name

    parameters = {
      configuration = {
        dataToExtract = "contentAndMetadata"
        parsingMode   = "default"
      }
    }
  }

  depends_on = [
    azapi_data_plane_resource.data_source,
    azapi_data_plane_resource.debug_index,
    azapi_data_plane_resource.debug_skillset
  ]
}
