# Catálogo interno de indicadores disponibles

library(banrepstats)

banrep_cache <- catalogo_banrep()
banrep_cache

usethis::use_data(banrep_cache, overwrite = TRUE)
