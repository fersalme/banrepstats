## Submission

This is a new submission.

## Test environments

* local: Ubuntu Linux, R 4.5.2
* GitHub Actions: ubuntu-latest, windows-latest, macos-latest (R release)
* win-builder: R-devel (Windows Server 2022, R 2026-11-07 r90850 ucrt)

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE

  New submission.

  Possibly misspelled words in DESCRIPTION: Banco, de, Republica.
  These are not misspellings: "Banco de la Republica" is the official
  name of Colombia's central bank, the publisher of the data.

  On Linux only, the same NOTE also reports a possibly invalid URL: https://suameca.banrep.gov.co/estadisticas-economicas/
  (libcurl error 60, "unable to get local issuer certificate").
  The URL is valid and reachable (status without verification: OK). The
  server of Banco de la Republica does not send the intermediate
  certificate of its TLS chain, so strict clients such as libcurl cannot
  verify it. Browsers fill in the missing certificate on their own. The
  package handles this at runtime by supplying the missing intermediate
  certificate (inst/extdata/banrep-chain.pem), keeping certificate
  verification enabled.

## Internet resources

The package wraps a public web API. To keep checks independent of
network access:

* Examples that query the API run only in interactive sessions
  (`@examplesIf interactive()`); the remaining examples use the bundled
  `banrep_cache` dataset or synthetic data.
* Tests that query the API are skipped on CRAN (`skip_if_offline()`);
  the rest of the test suite uses offline fixtures.
* The vignette is precomputed, so building it does not access the network.
* API failures raise informative error messages.
