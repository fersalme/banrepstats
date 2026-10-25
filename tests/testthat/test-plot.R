test_that("series_plot() builds a ggplot from a data.table", {
  dt <- data.table::data.table(
    id = "Serie A",
    unidad = "Porcentaje",
    periodicidad = "Mensual",
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 12),
    value = seq_len(12)
  )

  p <- series_plot(dt)

  expect_s3_class(p, "ggplot")
})

test_that("series_plot() also accepts a plain data.frame", {
  df <- data.frame(
    id = rep(c("Serie A", "Serie B"), each = 3),
    unidad = "Porcentaje",
    date = rep(seq(as.Date("2020-01-01"), by = "month", length.out = 3), 2),
    value = 1:6
  )

  expect_s3_class(series_plot(df), "ggplot")
})

test_that("series_plot() errors when there is no data to plot", {
  expect_error(
    series_plot(data.table::data.table()),
    "No observations available to plot"
  )
})

test_that("series_plot() spaces date breaks according to the series span", {
  serie <- function(desde, hasta) {
    fechas <- seq(as.Date(desde), as.Date(hasta), by = "month")
    data.table::data.table(
      id = "Serie A", unidad = "Porcentaje", date = fechas, value = seq_along(fechas)
    )
  }
  cortes <- function(p) {
    b <- ggplot2::ggplot_build(p)$layout$panel_params[[1]]$x$breaks
    b <- b[!is.na(b)]
    as.numeric(diff(b[1:2])) / 365.25
  }

  expect_lt(cortes(series_plot(serie("2020-01-01", "2020-12-01"))), 0.1)
  expect_equal(cortes(series_plot(serie("2000-01-01", "2020-12-01"))), 2, tolerance = 0.01)
  expect_equal(cortes(series_plot(serie("1955-07-01", "2026-09-01"))), 10, tolerance = 0.01)
})
