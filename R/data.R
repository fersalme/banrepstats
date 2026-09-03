#' Catálogo interno de indicadores disponibles
#'
#' A snapshot of `catalogo_banrep()`, bundled with the package as an offline
#' fallback so `banrep_data()` does not need to hit the network just to
#' validate/look up an indicator code.
#'
#' @format A data.table with five columns
#' 1. `idGrupo`: ID of the parent menu group
#' 2. `NombreGrupo`: Name of the parent menu group
#' 3. `idSerie`: ID of the indicator
#' 4. `NombreSerie`: Name of the indicator
#' 5. `idNombreSerie`: Category code of the indicator (used by `banrep_data()`)
#'
#' @source <https://suameca.banrep.gov.co/estadisticas-economicas/#/>
#'
#' @examples
#' banrep_cache
#'
"banrep_cache"
