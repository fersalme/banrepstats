#' @import data.table
#' @noRd
.flatten_menu <- function(nodes) {
  if (is.null(nodes) || !is.data.frame(nodes) || nrow(nodes) == 0) {
    return(NULL)
  }
  cols <- c("id", "idPadre", "nombre", "idCarguePlan", "idMenuJson")
  actual <- data.table::as.data.table(nodes[cols])
  hijos <- lapply(nodes$menuHijos, .flatten_menu)
  data.table::rbindlist(c(list(actual), hijos))
}

#' Download the Banco de la República indicator catalog
#'
#' Fetches the live indicator menu tree from the Banco de la República
#' statistics API and flattens it into a single table, one row per
#' indicator.
#'
#' @param endpoint Catalog endpoint URL. Only change this for testing.
#'
#' @return A data.table with columns `idGrupo`, `NombreGrupo`, `idSerie`,
#' `NombreSerie` and `idNombreSerie` (the code to pass as `indicator` to
#' [banrep_data()]).
#' @export
#'
#' @examples
#' \dontrun{
#' catalogo <- catalogo_banrep()
#' head(catalogo)
#' }
catalogo_banrep <- function(
  endpoint = "https://suameca.banrep.gov.co/estadisticas-economicas-back/rest/estadisticaEconomicaRestService/consultaMenuXopcion"
) {
  catalogo_raw <- httr2::request(endpoint) |>
    httr2::req_url_query(opcion = "CATALOGO_DATOS") |>
    httr2::req_perform() |>
    httr2::resp_body_string()

  json_catalogo <- jsonlite::fromJSON(catalogo_raw, flatten = FALSE)

  catalogo <- .flatten_menu(json_catalogo)
  catalogo[, nombre_padre := nombre[match(idPadre, id)]]
  catalogo <- catalogo[
    idPadre > 0,
    .(idPadre, nombre_padre, id, nombre, idMenuJson)
  ]
  catalogo[, `:=`(idPadre = as.integer(idPadre), id = as.integer(id))]
  data.table::setorder(catalogo, idPadre)
  colnames(catalogo) <- c(
    "idGrupo",
    "NombreGrupo",
    "idSerie",
    "NombreSerie",
    "idNombreSerie"
  )
  catalogo[]
}

#' @noRd
build_url_banrep <- function(
  indicador,
  catalogo = catalogo_banrep(),
  endpoint = "https://suameca.banrep.gov.co/estadisticas-economicas-back/rest/estadisticaEconomicaRestService/consultaMenuXId"
) {
  if (missing(indicador) || is.null(indicador)) {
    stop(
      "Argument 'indicador' is required. Use catalogo_banrep() to see available options."
    )
  }
  id_indicador <- catalogo[idNombreSerie == indicador, idSerie]
  if (length(id_indicador) == 0L) {
    stop(
      sprintf(
        "'%s' is not a valid indicador name. Use catalogo_banrep() to see available options.",
        indicador
      )
    )
  }

  httr2::request(endpoint) |>
    httr2::req_url_query(idMenu = id_indicador[1]) |>
    (\(r) r$url)()
}

#' @noRd
.limpiar_serie <- function(id, unidad, descripcionPeriodicidad, data) {
  d_datos <- data.table::as.data.table(data)
  data.table::setnames(d_datos, c("date", "value"))
  # Timestamps are midnight Bogotá time (UTC-5) as epoch ms, so the day
  # count carries a fractional UTC offset; floor() recovers the intended
  # calendar day instead of leaving it baked into the Date's numeric value.
  d_datos[, date := as.Date(floor(date / 86400000), origin = "1970-01-01")]
  cbind(
    id = id,
    unidad = unidad,
    periodicidad = descripcionPeriodicidad,
    d_datos
  )
}

# Fetch and parse
#' @noRd
fetch_banrep <- function(url) {
  response <- httr2::request(url) |>
    httr2::req_headers(
      Referer = "https://suameca.banrep.gov.co/estadisticas-economicas/"
    ) |>
    httr2::req_error(is_error = \(r) FALSE) |>
    httr2::req_perform()

  if (httr2::resp_status(response) != 200L) {
    status <- httr2::resp_status(response)
    detail <- switch(
      as.character(status),
      "400" = "Syntax error: check query parameters.",
      "404" = "No results found for the query.",
      "500" = "Internal server error. Try again later.",
      "503" = "Service temporarily unavailable. Try again later.",
      "Unknown error."
    )
    stop(sprintf(
      "HTTP %d - %s\n%s",
      status,
      detail,
      httr2::resp_body_string(response)
    ))
  }

  datos <- jsonlite::fromJSON(
    httr2::resp_body_string(response),
    flatten = FALSE
  )

  if (NROW(datos$SERIES) == 0L) {
    message("The response contains no observations.")
    return(data.table::data.table())
  }

  data.table::rbindlist(Map(
    .limpiar_serie,
    datos$SERIES$nombre,
    datos$SERIES$unidad,
    datos$SERIES$descripcionPeriodicidad,
    datos$SERIES$data
  ))
}
