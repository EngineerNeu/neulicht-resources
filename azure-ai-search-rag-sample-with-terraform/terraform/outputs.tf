output "search_data_plane_endpoint" {
  value = "https://${local.search_parent_id}"
}

output "data_source_name" {
  value = azapi_data_plane_resource.data_source.name
}

output "index_name" {
  value = azapi_data_plane_resource.index.name
}

output "skillset_name" {
  value = azapi_data_plane_resource.skillset.name
}

output "indexer_name" {
  value = azapi_data_plane_resource.indexer.name
}

output "debug_index_name" {
  value = var.enable_debug_index ? azapi_data_plane_resource.debug_index[0].name : null
}
