.url_menu <- function(id_menu) {
  httr2::request(
    "https://suameca.banrep.gov.co/estadisticas-economicas-back/rest/estadisticaEconomicaRestService/consultaMenuXId"
  ) |>
    httr2::req_url_query(idMenu = id_menu) |>
    (\(r) r$url)()
}

test_that("fetch_banrep() parses dates and values correctly", {
  skip_if_offline()

  # idMenu 100001 is "Inflación y meta", whose earliest series starts
  # on 1955-07-31 - a regression check for the ms-since-epoch date bug.
  dt <- fetch_banrep(.url_menu(100001))

  expect_s3_class(dt, "data.table")
  expect_true(all(c("id", "unidad", "periodicidad", "date", "value") %in% names(dt)))
  expect_s3_class(dt$date, "Date")
  expect_gt(nrow(dt), 0)
  expect_equal(min(dt$date), as.Date("1955-07-31"))
})

test_that("fetch_banrep() handles menu nodes with no series", {
  skip_if_offline()

  # idMenu 100010 is "Más datos", a pure grouping node with no series
  # of its own (SERIES comes back as an empty JSON array).
  expect_message(
    dt <- fetch_banrep(.url_menu(100010)),
    "no observations"
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0)
})
