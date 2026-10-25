# banrepstats 0.1.1

## Bug fixes

* `catalogo_banrep()` no longer returns menu grouping nodes (such as
  "Más datos") as if they were indicators. The API started sending a
  blank `urlAcceso` (`" "`) for them instead of an empty string, which
  added 44 rows with a blank code to the live catalog.
* Examples in `banrep_data()` used codes that do not exist in the catalog.

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
* New offline test suite based on fixtures that mirror the API responses,
  so parsing and error handling are tested without network access.
* Removed an unused internal `%||%` helper that masked base R's.

# banrepstats 0.1

* First version.
