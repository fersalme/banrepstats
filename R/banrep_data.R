#' Download Data from the Banrep API
#'
#' This function downloads the requested information using the Banrep API
#'
#' @param indicator Character vector of indicator codes. These codes correspond
#' to the `idNombreSerie` column of `catalogo_banrep()` (or the bundled
#' `banrep_cache` dataset).
#' @param cache A data.table as returned by `catalogo_banrep()`, e.g. the
#' bundled `banrep_cache` dataset. If omitted, `catalogo_banrep()` is called
#' to fetch a live catalog.
#' @param start,end Optional dates (a `Date` or a `"YYYY-MM-DD"` string)
#' delimiting the observations to keep, both inclusive. The API always
#' returns each indicator's full history, so this filter is applied after
#' the download.
#'
#' @return A data.table
#' @export
#'
#' @examples
#' \dontrun{
#' # One indicator, live catalog
#' precios <- banrep_data(indicator = "inflacion_y_meta")
#' head(precios)
#' # More than one indicator
#' precios <- banrep_data(
#'   indicator = c("inflacion_y_meta", "tasas_interes_politica_monetaria")
#' )
#' head(precios)
#' # Using the bundled catalog instead of a live one
#' precios <- banrep_data(indicator = "inflacion_y_meta", cache = banrep_cache)
#' head(precios)
#' # Only the observations from 2020 onwards
#' recientes <- banrep_data("inflacion_y_meta", start = "2020-01-01")
#' }
#'
banrep_data <- function(indicator, cache, start = NULL, end = NULL) {
  if (!is.character(indicator) || length(indicator) == 0L) {
    stop("'indicator' must be a non-empty character vector of indicator codes.")
  }
  start <- .as_fecha(start, "start")
  end <- .as_fecha(end, "end")

  catalogo <- if (missing(cache)) catalogo_banrep() else cache

  invalidos <- setdiff(indicator, catalogo$idNombreSerie)
  if (length(invalidos) > 0L) {
    stop(sprintf(
      paste0(
        "Invalid indicator code(s): %s.\n",
        "Use search_banrep() or catalogo_banrep() to find valid codes ",
        "(column 'idNombreSerie')."
      ),
      paste0("'", invalidos, "'", collapse = ", ")
    ))
  }

  # build urls
  ind_url <- lapply(indicator, build_url_banrep, catalogo = catalogo)

  # descargar
  data_list <- lapply(ind_url, fetch_banrep)

  datos <- data.table::rbindlist(data_list)
  if (nrow(datos) > 0L && !is.null(start)) {
    datos <- datos[date >= start]
  }
  if (nrow(datos) > 0L && !is.null(end)) {
    datos <- datos[date <= end]
  }
  datos
}

#' @noRd
.as_fecha <- function(x, arg) {
  if (is.null(x)) {
    return(NULL)
  }
  fecha <- tryCatch(as.Date(x), error = function(e) NA)
  if (length(fecha) != 1L || is.na(fecha)) {
    stop(sprintf(
      "'%s' must be a single date (a Date or a \"YYYY-MM-DD\" string).",
      arg
    ))
  }
  fecha
}
