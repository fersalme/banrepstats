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

# id/value/date are ggplot2::aes() columns; `.` is data.table's alias for
# list() (see vignette('datatable-importing')); the rest are data.table
# columns referenced via NSE inside catalogo_banrep() (nombre/idPadre/
# idMenuJson, before they get renamed to NombreSerie/idSerie/idNombreSerie)
# and build_url_banrep() (idNombreSerie/idSerie, post-rename)
#' @importFrom utils globalVariables
utils::globalVariables(c(
  ".",
  "id",
  "value",
  "date",
  "nombre",
  "idPadre",
  "nombre_padre",
  "idMenuJson",
  "idNombreSerie",
  "idSerie"
))
