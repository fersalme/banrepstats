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
#' Looks up `x` against the catalog's group names, indicator names and
#' indicator codes, so you don't have to browse the whole
#' `catalogo_banrep()` table to find an indicator's `idNombreSerie` code.
#' The match is partial and ignores both case and Spanish accents, so
#' `"inflacion"` and `"Inflación"` return the same rows.
#'
#' @param x A keyword to search for.
#' @param cache A data.table as returned by `catalogo_banrep()`, e.g. the
#' bundled `banrep_cache` dataset. If omitted, `catalogo_banrep()` is called
#' to fetch a live catalog.
#' @param fixed If `TRUE` (the default), `x` is matched as literal text.
#' Use `FALSE` to treat it as a regular expression.
#'
#' @return A data.table subset of the catalog whose `NombreGrupo`,
#' `NombreSerie` or `idNombreSerie` match `x`.
#' @export
#'
#' @examples
#' search_banrep("inflacion", cache = banrep_cache)
#' search_banrep("tasa", cache = banrep_cache)
#' search_banrep("^IP", cache = banrep_cache, fixed = FALSE)
#' \dontrun{
#' # Live catalog
#' search_banrep("desempleo")
#' }
search_banrep <- function(x, cache, fixed = TRUE) {
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    stop("'x' must be a single keyword (a character string).")
  }
  catalogo <- if (missing(cache)) catalogo_banrep() else cache

  patron <- .normalizar_texto(x)
  coincide <- function(campo) {
    grepl(patron, .normalizar_texto(campo), fixed = fixed)
  }

  catalogo[
    coincide(NombreGrupo) | coincide(NombreSerie) | coincide(idNombreSerie)
  ]
}

# Lower-case and strip Spanish accents. chartr() keeps the result the same
# on every platform, unlike iconv()'s "ASCII//TRANSLIT".
#' @noRd
.normalizar_texto <- function(x) {
  tolower(chartr(
    "\u00e1\u00e9\u00ed\u00f3\u00fa\u00fc\u00f1\u00c1\u00c9\u00cd\u00d3\u00da\u00dc\u00d1",
    "aeiouunAEIOUUN",
    enc2utf8(x)
  ))
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
