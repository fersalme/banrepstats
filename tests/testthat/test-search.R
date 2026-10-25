test_that("search_banrep() ignores case and accents", {
  catalogo <- fixture_catalogo()

  sin_tilde <- search_banrep("inflacion", cache = catalogo)
  con_tilde <- search_banrep("Inflación", cache = catalogo)

  expect_equal(sin_tilde, con_tilde)
  expect_true("inflacion_y_meta" %in% sin_tilde$idNombreSerie)
  expect_equal(
    search_banrep("POLITICA", cache = catalogo)$idNombreSerie,
    "tasas_interes_politica_monetaria"
  )
})

test_that("search_banrep() also matches indicator codes", {
  res <- search_banrep("ipvn", cache = fixture_catalogo())
  expect_equal(res$idNombreSerie, "indice_precios_vivienda_nueva_ipvn")
})

test_that("search_banrep() treats the keyword literally unless fixed = FALSE", {
  catalogo <- fixture_catalogo()

  # "(" would be an invalid regular expression.
  expect_equal(nrow(search_banrep("(", cache = catalogo)), 0L)
  expect_equal(
    search_banrep("^tasas", cache = catalogo, fixed = FALSE)$idNombreSerie,
    "tasas_interes_politica_monetaria"
  )
})

test_that("search_banrep() works on the bundled catalog", {
  res <- search_banrep("inflacion", cache = banrep_cache)
  expect_gt(nrow(res), 0L)
  expect_true("inflacion_y_meta" %in% res$idNombreSerie)
})

test_that("search_banrep() validates its keyword", {
  expect_error(search_banrep(c("a", "b"), cache = fixture_catalogo()), "single keyword")
  expect_error(search_banrep(NA_character_, cache = fixture_catalogo()), "single keyword")
})
