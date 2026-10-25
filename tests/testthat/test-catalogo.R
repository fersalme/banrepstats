test_that("catalogo_banrep() returns the expected structure", {
  skip_if_offline()

  catalogo <- catalogo_banrep()

  expect_s3_class(catalogo, "data.table")
  expect_named(
    catalogo,
    c("idGrupo", "NombreGrupo", "idSerie", "NombreSerie", "idNombreSerie")
  )
  expect_gt(nrow(catalogo), 0)
  expect_type(catalogo$idGrupo, "integer")
  expect_type(catalogo$idSerie, "integer")
  expect_true(all(catalogo$idGrupo > 0))
  expect_false(anyNA(catalogo$idSerie))
  # Only downloadable indicators: no blank codes left by grouping nodes.
  expect_false(any(trimws(catalogo$idNombreSerie) == ""))
  expect_false(anyDuplicated(catalogo$idNombreSerie) > 0L)
})

test_that("every code in the bundled banrep_cache still exists live", {
  skip_if_offline()

  catalogo <- catalogo_banrep()
  expect_length(setdiff(banrep_cache$idNombreSerie, catalogo$idNombreSerie), 0L)
})

test_that("build_url_banrep() builds the URL from a given catalog", {
  fake_catalogo <- data.table::data.table(
    idNombreSerie = c("FOO", "BAR"),
    idSerie = c(111L, 222L)
  )

  url <- build_url_banrep("FOO", catalogo = fake_catalogo)

  expect_match(url, "consultaMenuXId")
  expect_match(url, "idMenu=111")
})

test_that("build_url_banrep() validates its indicador argument", {
  fake_catalogo <- data.table::data.table(
    idNombreSerie = "FOO",
    idSerie = 111L
  )

  expect_error(
    build_url_banrep(catalogo = fake_catalogo),
    "required"
  )
  expect_error(
    build_url_banrep("NO_EXISTE", catalogo = fake_catalogo),
    "not a valid indicador"
  )
})
