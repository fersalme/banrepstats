test_that("banrep_data() downloads one or more indicators", {
  skip_if_offline()

  one <- banrep_data("PRECIOS_E_INFLACION")
  expect_s3_class(one, "data.table")
  expect_gt(nrow(one), 0)

  two <- banrep_data(c("PRECIOS_E_INFLACION", "TASAS_INTERES_Y_SECTOR_FINAN"))
  expect_gt(
    data.table::uniqueN(two$id),
    data.table::uniqueN(one$id)
  )
})

test_that("banrep_data() reports invalid indicator codes", {
  skip_if_offline()

  expect_error(banrep_data("NO_EXISTE"), "Indicadores permitidos")
})

test_that("banrep_data() accepts a pre-fetched catalog via `cache`", {
  skip_if_offline()

  con_cache <- banrep_data("PRECIOS_E_INFLACION", cache = banrep_cache)
  expect_s3_class(con_cache, "data.table")
  expect_gt(nrow(con_cache), 0)
})
