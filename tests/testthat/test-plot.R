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

test_that("series_plot() errors when there is no data to plot", {
  expect_error(
    series_plot(data.table::data.table()),
    "No observations available to plot"
  )
})
