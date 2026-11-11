# Precompile the vignette, which downloads data from the live Banrep API.
# Run from the package root after editing vignettes/banrepstats.Rmd.orig:
#   source("vignettes/precompile.R")
old <- setwd("vignettes")
knitr::knit("banrepstats.Rmd.orig", output = "banrepstats.Rmd")
setwd(old)
