#' @noRd
.banrep_env <- new.env(parent = emptyenv())

#' @noRd
.issues_url <- function() "https://github.com/fersalme/banrepstats/issues"

#' @noRd
.request_banrep <- function(url) {
  httr2::request(url) |>
    httr2::req_user_agent(
      "banrepstats (https://github.com/fersalme/banrepstats)"
    ) |>
    httr2::req_timeout(60) |>
    # Only statuses that signal a temporary condition are retried: a 500
    # from this API usually means the request itself is wrong (e.g. a
    # grouping node with no series), so retrying it just wastes time.
    httr2::req_retry(
      max_tries = 3,
      is_transient = \(resp) {
        httr2::resp_status(resp) %in% c(429L, 502L, 503L, 504L)
      }
    )
}

#' @noRd
.req_perform_banrep <- function(req) {
  chain <- system.file("extdata", "banrep-chain.pem", package = "banrepstats")

  # Once a request in this session has needed the bundled intermediate,
  # use it straight away instead of failing first on every request.
  if (isTRUE(.banrep_env$use_chain) && nzchar(chain)) {
    return(httr2::req_perform(httr2::req_options(req, cainfo = chain)))
  }

  tryCatch(
    httr2::req_perform(req),
    httr2_failure = function(e) {
      if (!grepl("SSL|certificate", conditionMessage(e), ignore.case = TRUE)) {
        stop(e)
      }
      # Banrep's server omits the intermediate certificate that links its
      # leaf certificate to a trusted root, so the chain can't be built
      # from the system CA store alone. Retry supplying that intermediate
      # ourselves: verification stays on, it just gets the missing link.
      if (!nzchar(chain)) {
        stop(e)
      }
      resp <- httr2::req_perform(httr2::req_options(req, cainfo = chain))
      .banrep_env$use_chain <- TRUE
      resp
    }
  )
}

# Stops with an informative error when the (undocumented) API response
# no longer has the shape the package was written against.
#' @noRd
.assert_campos <- function(x, campos, contexto) {
  faltan <- setdiff(campos, names(x))
  if (length(faltan) > 0L) {
    stop(
      sprintf(
        paste0(
          "Unexpected response from the Banrep API (%s): missing field(s) %s.\n",
          "The undocumented SUAMECA API may have changed; please report it at %s"
        ),
        contexto,
        paste(faltan, collapse = ", "),
        .issues_url()
      ),
      call. = FALSE
    )
  }
  invisible(x)
}

#' @noRd
.parse_json_banrep <- function(response, contexto) {
  body <- if (httr2::resp_has_body(response)) {
    httr2::resp_body_string(response)
  } else {
    ""
  }
  # A request the server's proxy rejects comes back as HTTP 200 with an
  # empty body rather than as an error status.
  if (!nzchar(trimws(body))) {
    stop(
      sprintf(
        paste0(
          "The Banrep API returned an empty response (%s). The request ",
          "may have been filtered by the server; please report it at %s"
        ),
        contexto,
        .issues_url()
      ),
      call. = FALSE
    )
  }
  jsonlite::fromJSON(body, flatten = FALSE)
}

#' @import data.table
#' @noRd
.flatten_menu <- function(nodes) {
  if (is.null(nodes) || !is.data.frame(nodes) || nrow(nodes) == 0) {
    return(NULL)
  }
  cols <- c(
    "id",
    "idPadre",
    "nombre",
    "idCarguePlan",
    "idMenuJson",
    "idSubmenuJson",
    "urlAcceso"
  )
  .assert_campos(nodes, c(cols, "menuHijos"), "catalog")
  actual <- data.table::as.data.table(nodes[cols])
  hijos <- lapply(nodes$menuHijos, .flatten_menu)
  data.table::rbindlist(c(list(actual), hijos))
}

#' @noRd
.endpoint_catalogo <- function() {
  "https://suameca.banrep.gov.co/estadisticas-economicas-back/rest/estadisticaEconomicaRestService/consultaMenuXopcion"
}

#' @noRd
.endpoint_datos <- function() {
  "https://suameca.banrep.gov.co/estadisticas-economicas-back/rest/estadisticaEconomicaRestService/consultaMenuXId"
}

#' Download the Banco de la República indicator catalog
#'
#' Fetches the live indicator menu tree from the Banco de la República
#' statistics API and flattens it into a single table, one row per
#' indicator. Grouping nodes of the menu (entries with no data of their
#' own) are dropped.
#'
#' Banrep's server does not send the intermediate certificate needed to
#' build a complete TLS chain, which makes strict clients such as `curl`
#' refuse the connection. This is handled automatically: on an SSL
#' failure the request is retried with the missing intermediate supplied
#' by the package, so certificate verification stays enabled throughout.
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
catalogo_banrep <- function() {
  response <- .request_banrep(.endpoint_catalogo()) |>
    httr2::req_url_query(opcion = "CATALOGO_DATOS") |>
    .req_perform_banrep()

  json_catalogo <- .parse_json_banrep(response, "catalog")

  catalogo <- .flatten_menu(json_catalogo)
  catalogo[, nombre_padre := nombre[match(idPadre, id)]]
  # Grouping nodes carry a blank access code ("" or " ", depending on the
  # API version); only leaves with a real code are downloadable indicators.
  catalogo <- catalogo[
    idPadre > 0 & !is.na(urlAcceso) & trimws(urlAcceso) != "",
    .(idPadre, nombre_padre, id, nombre, urlAcceso)
  ]
  catalogo[, `:=`(
    idPadre = as.integer(idPadre),
    id = as.integer(id)
  )]
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
  endpoint = .endpoint_datos()
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
  if (length(data) == 0L) {
    return(NULL)
  }
  d_datos <- data.table::as.data.table(data)
  if (ncol(d_datos) != 2L) {
    stop(
      sprintf(
        paste0(
          "Unexpected response from the Banrep API: series '%s' has %d ",
          "columns instead of (date, value). Please report it at %s"
        ),
        id,
        ncol(d_datos),
        .issues_url()
      ),
      call. = FALSE
    )
  }
  data.table::setnames(d_datos, c("date", "value"))
  # Timestamps are midnight Bogotá time (UTC-5) as epoch ms, so the day
  # count carries a fractional UTC offset; floor() recovers the intended
  # calendar day instead of leaving it baked into the Date's numeric value.
  d_datos[, `:=`(
    date = as.Date(floor(as.numeric(date) / 86400000), origin = "1970-01-01"),
    value = as.numeric(value)
  )]
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
  response <- .request_banrep(url) |>
    httr2::req_headers(
      Referer = "https://suameca.banrep.gov.co/estadisticas-economicas/"
    ) |>
    httr2::req_error(is_error = \(r) FALSE) |>
    .req_perform_banrep()

  if (httr2::resp_status(response) != 200L) {
    status <- httr2::resp_status(response)
    detail <- switch(
      as.character(status),
      "400" = "Syntax error: check query parameters.",
      "404" = "No results found for the query.",
      "429" = "Too many requests. Try again later.",
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

  datos <- .parse_json_banrep(response, "series data")
  .assert_campos(datos, "SERIES", "series data")

  if (NROW(datos$SERIES) == 0L) {
    message("The response contains no observations.")
    return(data.table::data.table())
  }

  .assert_campos(
    datos$SERIES,
    c("nombre", "unidad", "descripcionPeriodicidad", "data"),
    "series data"
  )

  data.table::rbindlist(Map(
    .limpiar_serie,
    datos$SERIES$nombre,
    datos$SERIES$unidad,
    datos$SERIES$descripcionPeriodicidad,
    datos$SERIES$data
  ))
}
