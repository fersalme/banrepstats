# Offline fixtures: small JSON files under tests/testthat/fixtures that
# mirror the shape of the real SUAMECA responses, so parsing and error
# handling can be tested without hitting the network.

fixture_response <- function(file, status = 200L) {
  path <- test_path("fixtures", file)
  httr2::response(
    status_code = status,
    headers = list(`Content-Type` = "application/json"),
    body = readBin(path, "raw", file.size(path))
  )
}

# Routes catalog requests and data requests to their own fixtures.
mock_banrep <- function(
  catalogo = "catalogo.json",
  serie = "serie.json",
  status = 200L
) {
  function(req) {
    if (grepl("consultaMenuXopcion", req$url, fixed = TRUE)) {
      fixture_response(catalogo)
    } else {
      fixture_response(serie, status)
    }
  }
}

fixture_catalogo <- function() {
  data.table::data.table(
    idGrupo = c(1000L, 1000L, 2000L),
    NombreGrupo = c(
      "Precios e inflación",
      "Más datos",
      "Tasas de interés y sector financiero"
    ),
    idSerie = c(100001L, 100008L, 59L),
    NombreSerie = c(
      "Inflación y meta",
      "IPVNBR_Índice de precios de la vivienda nueva",
      "Tasas de interés de política monetaria"
    ),
    idNombreSerie = c(
      "inflacion_y_meta",
      "indice_precios_vivienda_nueva_ipvn",
      "tasas_interes_politica_monetaria"
    )
  )
}
