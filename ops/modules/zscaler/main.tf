data "http" "cent" {
  url = "https://api.config.zscaler.com/zscaler.net/cenr/json"

  request_headers = {
    Accept = "application/json"
  }
}

locals {
  body        = jsondecode(data.http.cent.response_body)
  contintents = local.body["zscaler.net"]

  cities = flatten([
    for continent_name, cities in local.contintents : [
      for city_name, range_specs in cities : {
        continent_name = split(" : ", continent_name)[1]
        city_name      = split(" : ", city_name)[1]
        range_specs    = range_specs
      }
    ]
  ])

  processed_cities = [
    for index, city in local.cities : {
      key            = "${city.continent_name}-${city.city_name}"
      continent_name = city.continent_name
      city_name      = city.city_name
      priority       = 200 + index
      prefixes = [
        for range_spec in city.range_specs : range_spec.range

        # Include only IPv4 ranges. Azure doesn't play nice with the IPv6 ranges from ZScaler.
        if length(regexall("[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+/[0-9]+", range_spec.range)) > 0
      ]
    }
  ]

  # For the authoritative list refer to https://config.zscaler.com/zscaler.net/cenr
  allowed_continents = [
    "EMEA",
    "Americas",
    "APAC",
  ]

  filtered_cities = {
    for city in local.processed_cities : city.key => city
    if contains(local.allowed_continents, city.continent_name)
  }
}

output "ranges" {
  value = local.filtered_cities
}
