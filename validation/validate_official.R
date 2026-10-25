# Accuracy check: compares the series returned by banrep_data() with the
# CSV files exported by hand from the SUAMECA portal
# (https://suameca.banrep.gov.co/estadisticas-economicas/), stored in
# suameca_data/.
#
# Run from the package root:
#   Rscript validation/validate_official.R
#
# Each CSV has a date column followed by one column per series, named
# exactly like the `id` column of banrep_data(). Dates are period-end
# dates ("YYYY/MM/DD"), values use a decimal comma and blanks for missing
# observations. The portal rounds the values it exports, so a value
# matches when it agrees with the API value up to the rounding of the
# export (half a unit of the last decimal place shown in that column).

library(banrepstats)
library(data.table)

dir.create("validation/results", showWarnings = FALSE, recursive = TRUE)

# Which indicator each exported file comes from. Two series are published
# under more than one indicator (the TRM and the national regional
# economic pulse), so the mapping is explicit rather than by series name.
exports <- data.table(
  file = c(
    "Inflación y meta.csv",
    "IPC_Índice de Precios al Consumidor.csv",
    "Producto Interno Bruto (PIB).csv",
    "Tasas de interés de política monetaria.csv",
    "Tasas de interés.csv",
    "Tasa de cambio del peso colombiano.csv",
    "Reservas internacionales.csv",
    "Operaciones en el mercado monetario OMA.csv",
    "Remesas de trabajadores.csv",
    "Gobierno Nacional Central.csv",
    "Sector público no financiero.csv",
    "Economía Regional.csv"
  ),
  idNombreSerie = c(
    "inflacion_y_meta",
    "indice_de_precios_al_consumidor_ipc",
    "producto_interno_bruto_pib_trimestral_observado_crecimiento_anual_serie_original",
    "tasas_interes_politica_monetaria",
    "tasas_interes_cdt_dtf",
    "tasa_cambio_peso_colombiano_trm_dolar_usd",
    "reservas_internacionales",
    "operaciones_mercado_monetario_oma_expancion_transitoria",
    "remesas_trabajadores",
    "gobierno_nacional_central",
    "sector_publico_no_financiero",
    "economia_regional_pulso_economico_regional_por_regiones"
  )
)

read_export <- function(file) {
  raw <- fread(
    file.path("suameca_data", file),
    encoding = "UTF-8",
    colClasses = "character",
    na.strings = ""
  )
  setnames(raw, 1L, "date")
  long <- melt(
    raw,
    id.vars = "date",
    variable.name = "id",
    value.name = "texto",
    variable.factor = FALSE
  )
  long[, `:=`(
    date = as.Date(date, format = "%Y/%m/%d"),
    value = as.numeric(sub(",", ".", texto, fixed = TRUE)),
    decimales = nchar(sub("^[^,]*,?", "", texto))
  )]
  long[!is.na(value)]
}

compare_export <- function(file, code) {
  oficial <- read_export(file)
  api <- banrep_data(code, cache = banrep_cache)[!is.na(value)]
  api <- api[id %in% unique(oficial$id)]

  # Rounding precision of the export, per series.
  precision <- oficial[, .(tol = 0.5 * 10^-max(decimales)), by = id]

  juntos <- merge(
    oficial[, .(id, date, oficial = value)],
    api[, .(id, date, api = value, periodicidad)],
    by = c("id", "date"),
    all = TRUE
  )
  juntos <- merge(juntos, precision, by = "id")
  juntos[, diff := abs(api - oficial)]
  # Tiny slack for floating-point noise on top of the export rounding.
  juntos[, coincide := diff <= tol * (1 + 1e-6) + 1e-9]

  juntos[, .(
    file = file,
    idNombreSerie = code,
    periodicidad = periodicidad[!is.na(periodicidad)][1],
    n_official = sum(!is.na(oficial)),
    n_api = sum(!is.na(api)),
    n_common = sum(!is.na(oficial) & !is.na(api)),
    only_official = sum(!is.na(oficial) & is.na(api)),
    only_api = sum(is.na(oficial) & !is.na(api)),
    n_match = sum(coincide, na.rm = TRUE),
    max_abs_diff = max(diff, na.rm = TRUE),
    tolerance = tol[1],
    official_last = max(date[!is.na(oficial)]),
    api_last = max(date[!is.na(api)])
  ), by = id]
}

retrieved_at <- Sys.time()
por_serie <- rbindlist(Map(compare_export, exports$file, exports$idNombreSerie))
por_serie[, pct_match := 100 * n_match / n_common]

# Dates present on only one side are expected at the edges: the portal
# export and the API call were made at slightly different moments, and
# a few daily series publish values ahead (e.g. the TRM for the coming
# weekend). Flag any mismatch that is not at the end of the sample.
por_indicador <- por_serie[, .(
  series = .N,
  periodicidad = paste(unique(periodicidad), collapse = "/"),
  n_official = sum(n_official),
  n_common = sum(n_common),
  n_match = sum(n_match),
  only_official = sum(only_official),
  only_api = sum(only_api),
  max_abs_diff = max(max_abs_diff)
), by = .(file, idNombreSerie)]
por_indicador[, pct_match := 100 * n_match / n_common]

total <- por_serie[, .(
  retrieved_at = format(retrieved_at, "%Y-%m-%d %H:%M:%S %Z"),
  indicators = uniqueN(idNombreSerie),
  series = .N,
  frequencies = uniqueN(periodicidad),
  official_obs = sum(n_official),
  common_obs = sum(n_common),
  matching_obs = sum(n_match),
  pct_match = 100 * sum(n_match) / sum(n_common),
  only_official = sum(only_official),
  only_api = sum(only_api)
)]

fwrite(por_serie, "validation/results/official_by_series.csv")
fwrite(por_indicador, "validation/results/official_by_indicator.csv")
fwrite(total, "validation/results/official_summary.csv")

print(por_indicador[, .(idNombreSerie, series, periodicidad, n_common,
                        pct_match, only_official, only_api, max_abs_diff)])
print(total)
