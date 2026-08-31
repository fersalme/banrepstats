# ── Null-coalescing operator (internal) ───────────────────────────────────────
`%||%` <- function(x, y) if (is.null(x) || is.na(x)) y else x

# Paleta banrep
paleta_banrep <- function(name){
  pal <- c(
  "azul1" = "#003E6C",
  "gris1" = "#333333",
  "gris2" = "#4D4F5B",
  "rojo1" = "#830C0C"
  )
   return(unname(pal[name]))
}