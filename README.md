# banrepstats

`banrepstats` downloads economic time series from Banco de la República's
(Colombia's central bank) public statistics API — the same data behind its
[SUAMECA](https://suameca.banrep.gov.co/estadisticas-economicas/#/) portal —
and returns them as tidy `data.table` objects, ready to explore or plot.

## Installation

```r
# install.packages("remotes")
remotes::install_github("fersalme/banrepstats")
```

## Usage

### Browse the indicator catalog

Banco de la República organizes its indicators in a menu tree (topic ->
sub-topic -> indicator). `catalogo_banrep()` downloads that tree and
flattens it into a single table:

```r
library(banrepstats)

catalogo <- catalogo_banrep()
head(catalogo)
#>    idGrupo         NombreGrupo idSerie                          NombreSerie       idNombreSerie
#> 1:    1000 Precios e inflación  100001                     Inflación y meta PRECIOS_E_INFLACION
#> 2:    1000 Precios e inflación  100002 IPC_Índice de Precios al Consumidor PRECIOS_E_INFLACION
#> ...
```

The `idNombreSerie` column holds the codes you pass to `banrep_data()`.

### Download a series

```r
precios <- banrep_data(indicator = "PRECIOS_E_INFLACION")
head(precios)
#>                   id     unidad periodicidad       date value
#> 1: Meta de inflación Porcentaje        Anual 1955-07-31    NA
#> ...
```

You can request several indicators at once — the results come back stacked
in a single `data.table`:

```r
datos <- banrep_data(c("PRECIOS_E_INFLACION", "TASAS_INTERES_Y_SECTOR_FINAN"))
```

Fetching the catalog on every call has a network cost. If you don't need
the live catalog, pass the bundled snapshot via `cache` to skip that
request:

```r
precios <- banrep_data("PRECIOS_E_INFLACION", cache = banrep_cache)
```

### Plot a series

```r
series_plot(precios)
```

`series_plot()` draws one line per distinct series (the `id` column),
colored with the package's Banco de la República-inspired palette.

## What's included

- `catalogo_banrep()` — download and flatten the live indicator catalog.
- `banrep_data()` — download one or more indicators as a single `data.table`.
- `series_plot()` — plot a `data.table` returned by `banrep_data()`.
- `banrep_cache` — a bundled snapshot of the catalog, for offline lookups.

## License

MIT
