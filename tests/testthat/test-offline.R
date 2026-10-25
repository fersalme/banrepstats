# Tests that run against the fixtures in tests/testthat/fixtures instead
# of the live API (see helper-mock.R).

test_that("catalogo_banrep() flattens nested menus and drops grouping nodes", {
  httr2::local_mocked_responses(mock_banrep())

  catalogo <- catalogo_banrep()

  expect_named(
    catalogo,
    c("idGrupo", "NombreGrupo", "idSerie", "NombreSerie", "idNombreSerie")
  )
  # Grouping nodes come with urlAcceso "" or " "; neither is an indicator.
  expect_setequal(
    catalogo$idNombreSerie,
    c(
      "inflacion_y_meta",
      "indice_precios_vivienda_nueva_ipvn",
      "tasas_interes_politica_monetaria"
    )
  )
  expect_false(any(trimws(catalogo$idNombreSerie) == ""))
  # A third-level leaf keeps its direct parent as its group.
  expect_equal(
    catalogo[idSerie == 100008L, NombreGrupo],
    "Más datos"
  )
  expect_type(catalogo$idGrupo, "integer")
})

test_that("catalogo_banrep() reports a changed catalog format", {
  httr2::local_mocked_responses(mock_banrep(catalogo = "catalogo_cambiado.json"))

  expect_error(catalogo_banrep(), "API may have changed")
})

test_that("fetch_banrep() parses series, dates and missing values", {
  httr2::local_mocked_responses(mock_banrep())

  dt <- fetch_banrep("https://example.org/consultaMenuXId?idMenu=100001")

  expect_named(dt, c("id", "unidad", "periodicidad", "date", "value"))
  expect_equal(nrow(dt), 6L)
  expect_setequal(unique(dt$id), c("Meta de inflación", "Inflación total anual"))
  # Bogota-midnight epoch ms must land on the intended calendar day, as a
  # whole number of days (no fractional UTC offset left in the Date).
  expect_equal(min(dt$date), as.Date("1955-07-31"))
  expect_true(all(as.numeric(dt$date) == floor(as.numeric(dt$date))))
  expect_equal(
    dt[id == "Inflación total anual" & date == as.Date("2024-02-29"), value],
    7.74
  )
  expect_true(is.na(dt[id == "Meta de inflación" & date == as.Date("1955-07-31"), value]))
})

test_that("fetch_banrep() returns an empty table when there are no series", {
  httr2::local_mocked_responses(mock_banrep(serie = "serie_vacia.json"))

  expect_message(
    dt <- fetch_banrep("https://example.org/consultaMenuXId?idMenu=1"),
    "no observations"
  )
  expect_equal(nrow(dt), 0L)
})

test_that("fetch_banrep() reports a changed series format", {
  httr2::local_mocked_responses(mock_banrep(serie = "serie_cambiada.json"))

  expect_error(
    fetch_banrep("https://example.org/consultaMenuXId?idMenu=1"),
    "missing field\\(s\\) SERIES"
  )
})

test_that("fetch_banrep() reports an empty body instead of failing to parse", {
  httr2::local_mocked_responses(function(req) {
    httr2::response(status_code = 200L, body = charToRaw(""))
  })

  expect_error(
    fetch_banrep("https://example.org/consultaMenuXId?idMenu=1"),
    "empty response"
  )
})

test_that("fetch_banrep() turns HTTP errors into informative messages", {
  httr2::local_mocked_responses(mock_banrep(serie = "serie_vacia.json", status = 500L))

  expect_error(
    fetch_banrep("https://example.org/consultaMenuXId?idMenu=1"),
    "HTTP 500 - Internal server error"
  )
})

test_that("only temporary HTTP statuses are retried", {
  req <- .request_banrep("https://example.org")
  is_transient <- req$policies$retry_is_transient

  expect_true(is_transient(httr2::response(503L)))
  expect_true(is_transient(httr2::response(429L)))
  expect_false(is_transient(httr2::response(500L)))
  expect_false(is_transient(httr2::response(404L)))
})

test_that("an SSL failure is retried with the bundled certificate chain", {
  .banrep_env$use_chain <- NULL
  intentos <- character()
  local_mocked_bindings(
    req_perform = function(req, ...) {
      cainfo <- req$options$cainfo
      intentos <<- c(intentos, if (is.null(cainfo)) "" else cainfo)
      if (is.null(req$options$cainfo)) {
        stop(structure(
          class = c("httr2_failure", "error", "condition"),
          list(
            message = "SSL certificate problem: unable to get local issuer certificate",
            call = NULL
          )
        ))
      }
      httr2::response(200L)
    },
    .package = "httr2"
  )

  resp <- .req_perform_banrep(httr2::request("https://example.org"))

  expect_equal(httr2::resp_status(resp), 200L)
  expect_length(intentos, 2L)
  expect_match(intentos[2], "banrep-chain.pem")
  # Later requests in the session go straight to the bundled chain.
  expect_true(.banrep_env$use_chain)
  .req_perform_banrep(httr2::request("https://example.org"))
  expect_length(intentos, 3L)
  expect_match(intentos[3], "banrep-chain.pem")

  .banrep_env$use_chain <- NULL
})

test_that("non-SSL network failures are not retried with the bundled chain", {
  .banrep_env$use_chain <- NULL
  local_mocked_bindings(
    req_perform = function(req, ...) {
      stop(structure(
        class = c("httr2_failure", "error", "condition"),
        list(message = "Could not resolve host: example.org", call = NULL)
      ))
    },
    .package = "httr2"
  )

  expect_error(
    .req_perform_banrep(httr2::request("https://example.org")),
    "Could not resolve host"
  )
  expect_null(.banrep_env$use_chain)
})

test_that("banrep_data() downloads and filters by date", {
  httr2::local_mocked_responses(mock_banrep())

  todo <- banrep_data("inflacion_y_meta", cache = fixture_catalogo())
  expect_equal(nrow(todo), 6L)

  desde <- banrep_data(
    "inflacion_y_meta",
    cache = fixture_catalogo(),
    start = "2024-01-01"
  )
  expect_true(all(desde$date >= as.Date("2024-01-01")))
  expect_equal(nrow(desde), 4L)

  rango <- banrep_data(
    "inflacion_y_meta",
    cache = fixture_catalogo(),
    start = as.Date("2024-02-01"),
    end = "2024-02-29"
  )
  expect_equal(nrow(rango), 1L)
  expect_equal(rango$value, 7.74)
})

test_that("banrep_data() names the invalid codes", {
  expect_error(
    banrep_data(
      c("inflacion_y_meta", "NO_EXISTE", "TAMPOCO"),
      cache = fixture_catalogo()
    ),
    "'NO_EXISTE', 'TAMPOCO'"
  )
  expect_error(
    banrep_data(" ", cache = fixture_catalogo()),
    "Invalid indicator code"
  )
})

test_that("banrep_data() validates its arguments", {
  expect_error(banrep_data(character(), cache = fixture_catalogo()), "non-empty")
  expect_error(banrep_data(123, cache = fixture_catalogo()), "non-empty")
  expect_error(
    banrep_data("inflacion_y_meta", cache = fixture_catalogo(), start = "ayer"),
    "'start' must be a single date"
  )
  expect_error(
    banrep_data(
      "inflacion_y_meta",
      cache = fixture_catalogo(),
      end = c("2020-01-01", "2021-01-01")
    ),
    "'end' must be a single date"
  )
})
