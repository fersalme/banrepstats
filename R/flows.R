# ── Catálogo interno de flows disponibles ─────────────────────────────────────
.banrep_flows <- data.frame(
  topic = c(
    "IBR", "IBR", "DTF", "DTF", "TRM", "TRM",
    "CBR", "CBR", "CBR", "CBR", "TIB", "TIB",
    "COLCAP", "COLCAP", "MONAGG", "MONAGG",
    "DTF_TRIM", "DTF_TRIM", "DTF_MONTHLY", "DTF_MONTHLY",
    "UVR", "UVR"
  ),
  description = c(
    "Interbank Reference Rate (IBR)", "Interbank Reference Rate (IBR)",
    "Term Deposit Rate CDT 90 days (DTF)", "Term Deposit Rate CDT 90 days (DTF)",
    "Representative Market Exchange Rate (TRM)", "Representative Market Exchange Rate (TRM)",
    "Monetary Policy Interest Rate (TPM) - Daily", "Monetary Policy Interest Rate (TPM) - Daily",
    "Monetary Policy Interest Rate (TPM) - Monthly", "Monetary Policy Interest Rate (TPM) - Monthly",
    "Interbank Rate (TIB)", "Interbank Rate (TIB)",
    "Stock Market Index (COLCAP)", "Stock Market Index (COLCAP)",
    "Monetary Aggregates M1/M2/M3", "Monetary Aggregates M1/M2/M3",
    "DTF Forward Quarter", "DTF Forward Quarter",
    "DTF Monthly", "DTF Monthly",
    "Real Value Unit (UVR)", "Real Value Unit (UVR)"
  ),
  flow_id = c(
    "DF_IBR_DAILY_LATEST",    "DF_IBR_DAILY_HIST",
    "DF_DTF_DAILY_LATEST",    "DF_DTF_DAILY_HIST",
    "DF_TRM_DAILY_LATEST",    "DF_TRM_DAILY_HIST",
    "DF_CBR_DAILY_LATEST",    "DF_CBR_DAILY_HIST",
    "DF_CBR_MONTHLY_LATEST",  "DF_CBR_MONTHLY_HIST",
    "DF_IR_DAILY_LATEST",     "DF_IR_DAILY_HIST",
    "DF_COLCAP_MONTHLY_LATEST","DF_COLCAP_MONTHLY_HIST",
    "DF_MONAGG_MONTHLY_LATEST","DF_MONAGG_MONTHLY_HIST",
    "DF_DTF_TRIM_ANTICIPADO_LATEST","DF_DTF_TRIM_ANTICIPADO_HIST",
    "DF_DTF_MONTHLY_LATEST",  "DF_DTF_MONTHLY_HIST",
    "DF_UVR_DAILY_LATEST",    "DF_UVR_DAILY_HIST"
  ),
  frequency = c(
    "D","D","D","D","D","D",
    "D","D","M","M","D","D",
    "M","M","M","M",
    "D","D","M","M",
    "D","D"
  ),
  category = rep(c("latest", "hist"), 11),
  unit_measure = c(
    "ER","ER","PA","PA","COP","COP",
    "PA","PA","PA","PA","PA","PA",
    "IX","IX","COP","COP",
    "PA","PA","PA","PA",
    "CRVU","CRVU"
  ),
  stringsAsFactors = FALSE
)


# ── List available flows ───────────────────────────────────────────────────────
#' @export
banrep_flows <- function(topic = NULL, category = NULL) {
  df <- .banrep_flows

  if (!is.null(topic)) {
    topic <- toupper(topic)
    df <- df[df$topic %in% topic, ]
  }

  if (!is.null(category)) {
    category <- tolower(category)
    if (!category %in% c("latest", "hist")) {
      stop("'category' must be either 'latest' or 'hist'.")
    }
    df <- df[df$category == category, ]
  }

  return(df)
}
