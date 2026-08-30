#' Download Data from the Banrep API
#'
#' This function downloads the requested information using the Banrep API
#'
#' @param name description


# # 1. Browse available flows
# banrep_flows()
# banrep_flows(topic = "IBR")
# banrep_flows(category = "hist")
#
# # 2. IBR historical series
# url_ibr <- build_url_banrep(
#   flow         = "DF_IBR_DAILY_HIST",
#   start_period = "2023",
#   end_period   = "2025"       # strict less-than on year: includes up to 2024
# )
# ibr <- fetch_banrep(url_ibr)
# ibr                            # triggers print.banrep_data
# series_plot(ibr)
#
# # 3. TRM latest (no period filter needed for _LATEST flows)
# url_trm <- build_url_banrep(flow = "DF_TRM_DAILY_LATEST")
# trm <- fetch_banrep(url_trm)
# trm
#
# # 4. Monetary aggregates historical
# url_m <- build_url_banrep(
#   flow         = "DF_MONAGG_MONTHLY_HIST",
#   start_period = "2020",
#   end_period   = "2025"
# )
# monagg <- fetch_banrep(url_m)
# series_plot(monagg)
