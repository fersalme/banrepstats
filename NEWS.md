# banrepstats 1.1.0

## Bug fixes

* `catalogo_banrep()` no longer returns menu grouping nodes (such as
  "Más datos") as if they were indicators. The API started sending a
  blank `urlAcceso` (`" "`) for them instead of an empty string, which
  added 44 rows with a blank code to the live catalog. `banrep_cache`
  was regenerated.
* Examples in `banrep_data()` used codes that do not exist in the catalog.
* `series_plot()` spaces date breaks up to every 5 or 10 years, so long
  series (e.g. inflation since 1955) no longer get crowded labels, and the
  caption reads "Source:" instead of "Source :".

## New features

* `banrep_data()` gains `start` and `end` arguments to keep only the
  observations in a date range.
* `search_banrep()` now ignores Spanish accents (`"inflacion"` finds
  "Inflación"), also searches the indicator codes, and matches the
  keyword as literal text by default (`fixed = TRUE`).
* `series_plot()` also accepts a plain `data.frame`.

## Robustness

* Requests are retried on temporary HTTP errors (429, 502, 503, 504), time
  out after 60 seconds and identify themselves with a `User-Agent`.
* Responses are checked against the fields the package relies on. If the
  undocumented SUAMECA API changes shape, the error now says so instead
  of failing later with an unrelated message. An empty response body
  (how the server signals a filtered request) is also reported explicitly.
* After the first SSL failure in a session, later requests use the bundled
  certificate chain directly.
* Invalid indicator codes are now named in the error message.
* Removed an unused internal `%||%` helper that masked base R's.

## Testing and infrastructure

* New offline test suite based on fixtures that mirror the API responses,
  so parsing and error handling are tested without network access.
* GitHub Actions run `R CMD check` on every push and pull request, plus a
  weekly job that checks the package against the live API.

## Documentation

* The vignette is now built with knitr and R Markdown instead of Quarto,
  so building it no longer requires a Quarto installation.
* README and vignette document the new arguments and how the package
  copes with changes in the undocumented API.

# banrepstats 0.1

* First version.
