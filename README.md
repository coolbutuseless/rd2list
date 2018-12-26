
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rd2list

[![AppVeyor build
status](https://ci.appveyor.com/api/projects/status/github/coolbutuseless/rd2list?branch=master&svg=true)](https://ci.appveyor.com/project/coolbutuseless/rd2list)
[![Travis build
status](https://travis-ci.org/coolbutuseless/rd2list.svg?branch=master)](https://travis-ci.org/coolbutuseless/rd2list)
[![Coverage
status](https://codecov.io/gh/coolbutuseless/rd2list/branch/master/graph/badge.svg)](https://codecov.io/github/coolbutuseless/rd2list?branch=master)

`rd2list` is a package for extracting R documentation into a structured,
human-readable list. Use this package if you’ve ever wanted to get the
help text for a function as a string.

  - `get_doc()` - get a structured, human-readable list of the
    documentation for a function.
  - `get_rd_doc()` - fetch the Rd object for a function from an
    installed package.
  - `rd2list()` - parse an Rd object into a structured, human-readable
    list.

## Installation

You can install from github
with:

``` r
remotes::install_github("coolbutuseless/rd2list")
```

## Example - Getting documentation as a list

``` r
doc <- rd2list::get_doc(function_name = 'geom_path', package = 'ggplot2')

doc$title
#> [1] "Connect observations"
```

``` r
doc$description
```

    #> `geom_path()` connects the observations in the order in which they
    #> appear in the data. `geom_line()` connects them in order of the
    #> variable on the x axis. `geom_step()` creates a stairstep plot,
    #> highlighting exactly when changes occur. The `group` aesthetic
    #> determines which cases are connected together.

``` r
doc$arguments$linejoin
#> [1] "Line join style (round, mitre, bevel)."
```

``` r
doc$alias
#> [1] "geom_path" "geom_line" "geom_step"
```

## Example - Getting documentation as an Rd object

The raw Rd documentation object can be fetched using `get_rd_doc()`.

``` r
rd2list::get_rd_doc(function_name = 'diag', package_name = 'base')
```

``` r
$title
$title[[1]]
[1] "Matrix Diagonals"
attr(,"Rd_tag")
[1] "TEXT"

attr(,"Rd_tag")
[1] "\\title"

$name
$name[[1]]
[1] "diag"
attr(,"Rd_tag")
[1] "VERB"

attr(,"Rd_tag")
[1] "\\name"

$alias
$alias[[1]]
[1] "diag"
attr(,"Rd_tag")
[1] "VERB"

attr(,"Rd_tag")
[1] "\\alias"

[... output trimmed]
```

# Related documents and packages:

  - [Rd parsing](https://developer.r-project.org/parseRd.pdf) -
    developer documentation for parsing and understanding the `Rd`
    format.
  - [Rd2md](https://cran.r-project.org/package=Rd2md) converts Rd
    documentation to a markdown document.
  - [gbRd](https://cran.r-project.org/package=gbRd) which provides
    utilities for processing Rd objects and files.
  - [Rdpack](https://cran.r-project.org/package=Rdpack) which provide
    functions for manipulation of R documentation objects.
  - [fgui](https://cran.r-project.org/package=fgui) used to offer some
    functionality for extracting document. `fgui::parseHelp()` used to
    work, but has been disabled by author.
