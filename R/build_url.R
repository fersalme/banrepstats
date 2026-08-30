# ── Build URL ─────────────────────────────────────────────────────────────────
#' @export
build_url_banrep <- function(
    flow,
    start_period     = NULL,
    end_period       = NULL,
    agency           = "ESTAT",
    version          = "1.0",
    key              = "all/ALL",
    dimension_at_obs = "TIME_PERIOD",
    detail           = "full",
    endpoint         = "https://totoro.banrep.gov.co/nsi-jax-ws/rest/data") {

  # Validate flow against catalogue
  valid_flows <- .banrep_flows$flow_id
  if (missing(flow) || is.null(flow)) {
    stop(
      "Argument 'flow' is required. Use banrep_flows() to see available options."
    )
  }
  if (!flow %in% valid_flows) {
    stop(
      sprintf(
        "'%s' is not a valid flow_id. Use banrep_flows() to see available options.",
        flow
      )
    )
  }

  # endPeriod works as a strict less-than operator on year:
  # to include data up to year Y, set end_period = Y + 1
  flow_ref <- paste(agency, flow, version, sep = ",")

  httr2::request(endpoint) |>
    httr2::req_url_path_append(flow_ref, key, "") |>
    httr2::req_url_query(
      startPeriod            = start_period,
      endPeriod              = end_period,
      dimensionAtObservation = dimension_at_obs,
      detail                 = detail
    ) |>
    (\(r) r$url)()
}


# ── Print method ──────────────────────────────────────────────────────────────
#' @export
print.banrep_data <- function(x, ...) {
  h <- x$metadata$header
  s <- x$metadata$series

  cat("── Banrep SDMX Series ──────────────────────────────────────\n")
  cat(sprintf("  ID             : %s\n", h$id))
  cat(sprintf("  Name           : %s\n", h$name))
  cat(sprintf("  Prepared       : %s\n", h$prepared))
  cat(sprintf("  Extracted      : %s\n", h$extracted))
  cat(sprintf("  Sender         : %s (%s)\n", h$sender_name, h$sender_id))
  cat(sprintf("  Department     : %s\n", h$department))
  cat(sprintf("  Email          : %s\n", h$email))
  cat(sprintf("  Timezone       : %s\n", h$timezone))
  cat(sprintf("  Dataset ID     : %s\n", h$dataset_id))
  cat(sprintf("  Dataset action : %s\n", h$dataset_action))
  cat("── Series Key ──────────────────────────────────────────────\n")
  for (nm in names(s)) {
    cat(sprintf("  %-20s : %s\n", nm, s[[nm]]))
  }
  cat("── Data ────────────────────────────────────────────────────\n")
  cat(sprintf("  Observations   : %d rows\n", nrow(x$data)))
  if (nrow(x$data) > 0L) {
    cat(sprintf("  Date range     : %s to %s\n",
                format(min(x$data$date)),
                format(max(x$data$date))))
    cat(sprintf("  Value range    : [%.4f, %.4f]\n",
                min(x$data$value, na.rm = TRUE),
                max(x$data$value, na.rm = TRUE)))
  }
  cat("────────────────────────────────────────────────────────────\n")
  invisible(x)
}

# ── Fetch and parse ───────────────────────────────────────────────────────────
#' @export
fetch_banrep <- function(url) {

  response <- httr2::request(url) |>
    httr2::req_error(is_error = \(r) FALSE) |>
    httr2::req_perform()

  if (httr2::resp_status(response) != 200L) {
    status <- httr2::resp_status(response)
    detail <- switch(as.character(status),
                     "400" = "Syntax error: check query parameters.",
                     "404" = "No results found for the query.",
                     "500" = "Internal server error. Try again later.",
                     "503" = "Service temporarily unavailable. Try again later.",
                     "Unknown error."
    )
    stop(sprintf("HTTP %d - %s\n%s", status,
                 detail, httr2::resp_body_string(response)))
  }

  doc <- httr2::resp_body_string(response) |>
    rvest::read_html(encoding = "UTF-8")

  extract_text <- function(doc, selector) {
    node <- rvest::html_element(doc, selector)
    if (is.na(node)) return(NA_character_)
    rvest::html_text2(node)
  }

  header_meta <- list(
    id             = extract_text(doc, "message\\:id"),
    name           = extract_text(doc, "common\\:name"),
    prepared       = extract_text(doc, "message\\:prepared"),
    extracted      = extract_text(doc, "message\\:extracted"),
    sender_id      = rvest::html_element(doc, "message\\:sender") |>
      rvest::html_attr("id"),
    sender_name    = rvest::html_element(doc, "message\\:sender") |>
      rvest::html_element("common\\:name") |>
      rvest::html_text2(),
    department     = extract_text(doc, "message\\:department"),
    email          = extract_text(doc, "message\\:email"),
    timezone       = extract_text(doc, "message\\:timezone"),
    dataset_id     = extract_text(doc, "message\\:datasetid"),
    dataset_action = extract_text(doc, "message\\:datasetaction")
  )

  series_key_nodes <- rvest::html_elements(
    doc, "generic\\:serieskey generic\\:value"
  )

  series_meta <- stats::setNames(
    rvest::html_attr(series_key_nodes, "value"),
    rvest::html_attr(series_key_nodes, "id")
  ) |>
    as.list()

  obs_nodes <- rvest::html_elements(doc, "generic\\:obs")

  if (length(obs_nodes) == 0L) {
    message("The response contains no observations.")
    return(structure(
      list(
        metadata = list(header = header_meta, series = series_meta),
        data     = data.frame()
      ),
      class = "banrep_data"
    ))
  }

  periods <- obs_nodes |>
    rvest::html_elements("generic\\:obsdimension") |>
    rvest::html_attr("value")

  values <- obs_nodes |>
    rvest::html_elements("generic\\:obsvalue") |>
    rvest::html_attr("value")

  df <- data.frame(
    date  = as.Date(periods, format = "%Y%m%d"),
    value = as.numeric(values),
    stringsAsFactors = FALSE
  )

  structure(
    list(
      metadata = list(header = header_meta, series = series_meta),
      data     = df
    ),
    class = "banrep_data"
  )
}


# ── Null-coalescing operator (internal) ───────────────────────────────────────
`%||%` <- function(x, y) if (is.null(x) || is.na(x)) y else x
