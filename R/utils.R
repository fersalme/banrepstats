# Null-coalescing operator (internal)
`%||%` <- function(x, y) if (is.null(x) || is.na(x)) y else x

# Paleta banrep
paleta_banrep <- function(name) {
  pal <- c(
    "azul1" = "#003E6C",
    "azul2" = "#4A90B8",
    "gris1" = "#333333",
    "gris2" = "#4D4F5B",
    "gris3" = "#8A8D93",
    "rojo1" = "#830C0C",
    "dorado1" = "#C9A227",
    "verde1" = "#2E6B4F",
    "naranja1" = "#B5651D",
    "morado1" = "#5B3A6E"
  )
  return(unname(pal[name]))
}

#' Search the Banco de la República indicator catalog by keyword
#'
#' Looks up `x` (case-insensitive, partial match) against the catalog's
#' group and indicator names, so you don't have to browse the whole
#' `catalogo_banrep()` table to find an indicator's `idNombreSerie` code.
#'
#' @param x A keyword to search for.
#' @param cache A data.table as returned by `catalogo_banrep()`, e.g. the
#' bundled `banrep_cache` dataset. If omitted, `catalogo_banrep()` is called
#' to fetch a live catalog.
#'
#' @return A data.table subset of the catalog whose `NombreGrupo` or
#' `NombreSerie` match `x`.
#' @export
#'
#' @examples
#' \dontrun{
#' search_banrep("inflación")
#' search_banrep("tasa", cache = banrep_cache)
#' }
search_banrep <- function(x, cache) {
  catalogo <- if (missing(cache)) catalogo_banrep() else cache

  catalogo[
    grepl(x, NombreGrupo, ignore.case = TRUE) |
      grepl(x, NombreSerie, ignore.case = TRUE)
  ]
}

# id/value/date are ggplot2::aes() columns; `.` is data.table's alias for
# list() (see vignette('datatable-importing')); the rest are data.table
# columns referenced via NSE inside catalogo_banrep() (nombre/idPadre/
# urlAcceso, before they get renamed to NombreSerie/idSerie/idNombreSerie),
# build_url_banrep() (idNombreSerie/idSerie, post-rename) and
# search_banrep() (NombreGrupo/NombreSerie, post-rename)
#' @importFrom utils globalVariables
utils::globalVariables(c(
  ".",
  "id",
  "value",
  "date",
  "nombre",
  "idPadre",
  "nombre_padre",
  "urlAcceso",
  "idNombreSerie",
  "idSerie",
  "NombreGrupo",
  "NombreSerie"
))
