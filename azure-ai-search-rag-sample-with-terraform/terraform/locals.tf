locals {
  # azapi_data_plane_resource expects the Search data-plane hostname,
  # without the https:// scheme.
  search_parent_id = "${var.search_service_name}.search.windows.net"

  azure_ai_resource_uri = trimsuffix(var.azure_ai_resource_uri, "/")
}
