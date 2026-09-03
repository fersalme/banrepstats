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
#'
#' @return A data.table
#' @export
#'
#' @examples
#' \dontrun{
#' # One category, live catalog
#' precios <- banrep_data(indicator = "PRECIOS_E_INFLACION")
#' head(precios)
#' # More than one category
#' precios <- banrep_data(
#'   indicator = c("PRECIOS_E_INFLACION", "TASAS_INTERES_Y_SECTOR_FINAN")
#' )
#' head(precios)
#' # Using the bundled catalog instead of a live one
#' precios <- banrep_data(indicator = "PRECIOS_E_INFLACION", cache = banrep_cache)
#' head(precios)
#' }
#'
banrep_data <- function(indicator, cache) {
  catalogo <- if (missing(cache)) catalogo_banrep() else cache

  if (!all(indicator %in% catalogo$idNombreSerie)) {
    stop(sprintf(
      "Indicadores permitidos : %s",
      paste0(catalogo$idNombreSerie, collapse = ", ")
    ))
  }

  # build urls
  ind_url <- lapply(indicator, build_url_banrep, catalogo = catalogo)

  # descargar
  data_list <- lapply(ind_url, fetch_banrep)

  data.table::rbindlist(data_list)
}
