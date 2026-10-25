# Coverage check: downloads every indicator in the live catalog with
# banrep_data() and records whether it succeeded, how many series and
# observations it returned, and basic integrity checks on the result.
#
# Run from the package root:
#   Rscript validation/validate_coverage.R
#
# Writes validation/results/coverage.csv (one row per indicator) and
# validation/results/coverage_summary.csv, and exits with an error if any
# indicator fails, so it can also be used as a scheduled API monitor.

library(banrepstats)
library(data.table)

dir.create("validation/results", showWarnings = FALSE, recursive = TRUE)

retrieved_at <- Sys.time()
catalogo <- catalogo_banrep()

# Catalog stability: codes in the bundled snapshot that are gone live,
# and new live codes that the snapshot does not have yet.
removed <- setdiff(banrep_cache$idNombreSerie, catalogo$idNombreSerie)
added <- setdiff(catalogo$idNombreSerie, banrep_cache$idNombreSerie)

check_indicator <- function(code) {
  Sys.sleep(0.25) # be gentle with the server
  t0 <- Sys.time()
  out <- tryCatch(
    suppressMessages(banrep_data(code, cache = catalogo)),
    error = function(e) e
  )
  secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

  if (inherits(out, "error")) {
    return(data.table(
      idNombreSerie = code,
      ok = FALSE,
      error = conditionMessage(out),
      seconds = secs
    ))
  }

  data.table(
    idNombreSerie = code,
    ok = nrow(out) > 0L,
    error = if (nrow(out) == 0L) "no observations" else NA_character_,
    seconds = secs,
    n_series = uniqueN(out$id),
    n_obs = nrow(out),
    n_missing = sum(is.na(out$value)),
    periodicidad = paste(sort(unique(out$periodicidad)), collapse = "/"),
    first_date = if (nrow(out)) min(out$date) else as.Date(NA),
    last_date = if (nrow(out)) max(out$date) else as.Date(NA),
    # integrity checks
    duplicated_obs = sum(duplicated(out[, .(id, date)])),
    whole_day_dates = all(as.numeric(out$date) == floor(as.numeric(out$date)))
  )
}

coverage <- rbindlist(
  lapply(catalogo$idNombreSerie, check_indicator),
  fill = TRUE
)
coverage <- merge(
  catalogo[, .(idNombreSerie, NombreGrupo, NombreSerie)],
  coverage,
  by = "idNombreSerie",
  sort = FALSE
)

summary_tbl <- data.table(
  retrieved_at = format(retrieved_at, "%Y-%m-%d %H:%M:%S %Z"),
  banrepstats_version = as.character(packageVersion("banrepstats")),
  indicators = nrow(coverage),
  indicators_ok = sum(coverage$ok),
  series = sum(coverage$n_series, na.rm = TRUE),
  observations = sum(coverage$n_obs, na.rm = TRUE),
  duplicated_obs = sum(coverage$duplicated_obs, na.rm = TRUE),
  all_whole_day_dates = all(coverage$whole_day_dates, na.rm = TRUE),
  snapshot_codes_removed = length(removed),
  live_codes_added = length(added)
)

# Indicators and series by frequency (an indicator can mix frequencies,
# so this counts each indicator under each frequency it contains).
by_freq <- coverage[
  ok == TRUE,
  .(periodicidad = unlist(strsplit(periodicidad, "/"))),
  by = idNombreSerie
][, .(indicators = .N), by = periodicidad][order(-indicators)]

fwrite(coverage, "validation/results/coverage.csv")
fwrite(summary_tbl, "validation/results/coverage_summary.csv")
fwrite(by_freq, "validation/results/coverage_by_frequency.csv")

print(summary_tbl)
print(by_freq)
if (length(removed)) {
  message("Codes in banrep_cache missing from the live catalog: ",
          paste(removed, collapse = ", "))
}
if (length(added)) {
  message("New live codes not in banrep_cache: ", paste(added, collapse = ", "))
}

if (!all(coverage$ok)) {
  print(coverage[ok == FALSE, .(idNombreSerie, error)])
  stop(sum(!coverage$ok), " indicator(s) failed to download.")
}
