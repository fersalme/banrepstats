test_that("paleta_banrep() returns the expected hex colors", {
  expect_identical(paleta_banrep("azul1"), "#003E6C")
  expect_identical(paleta_banrep(c("azul1", "rojo1")), c("#003E6C", "#830C0C"))
})

test_that("paleta_banrep() has 10 named colors and returns an unnamed vector", {
  nombres <- c(
    "azul1", "azul2", "gris1", "gris2", "gris3",
    "rojo1", "dorado1", "verde1", "naranja1", "morado1"
  )
  colores <- paleta_banrep(nombres)
  expect_length(colores, 10)
  expect_null(names(colores))
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", colores)))
})
