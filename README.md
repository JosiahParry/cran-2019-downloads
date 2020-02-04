2019 CRAN Downloads
================

The number of downloads that a package has can tell us a number of
things. For example, how much other packages rely on it. A great case of
this is [`rlang`](https://github.com/r-lib/rlang). Not many of use
`rlang`, know what it does, or even bother to dive into it. But in
reality it is the backbone of so many packages that we know and love and
use every day.

The other thing that we can infer from the download numbers is how
trusted a package may be. Packages that have been downloaded time and
time and again have *likely* been scoped out thoroughly for any bugs.
This can be rather comforting for security conscious groups.

With a little
[`rvest`](https://github.com/tidyverse/rvest)-web-scraping-magic we can
obtain the name of every package published to
[CRAN](https://cran.r-project.org/).

``` r
library(rvest)
library(tidyverse)

url <- "https://cran.r-project.org/web/packages/available_packages_by_name.html"

cran_packages <- html_session(url) %>% 
    html_nodes("table a") %>% 
    html_text()
```

RStudio keeps daily logs of packages downloaded from their CRAN mirror.
The package [`cranlogs`](https://r-hub.github.io/cranlogs) makes the
data available via and API and an R package. Below is a lightweight
function which sums the total number of downloads for the entire year.
`furrr` was used to speed up the computation a bit. This takes ~40
minutes to run, as such use the exported data in
`data/cran-2019-total-downloads.csv`.

``` r
get_year_downloads <- function(pkg) {
  cranlogs::cran_downloads(pkg, 
                           from = "2019-01-01",
                           to = "2019-12-31") %>% 
    group_by(package) %>% 
    summarise(total_downloads = sum(count))
}

total_cran_downloads <- furrr::future_map_dfr(
  cran_packages, 
  .f = possibly(get_year_downloads, otherwise = tibble())
  )
```

``` r
total_cran_downloads <- read_csv("data/cran-2019-total-downloads.csv")
glimpse(total_cran_downloads)
```

    ## Observations: 15,361
    ## Variables: 2
    ## $ package         <chr> "A3", "aaSEA", "ABACUS", "abbyyR", "abc", "abc.d…
    ## $ total_downloads <dbl> 13172, 2728, 2071, 9386, 81887, 80547, 5849, 635…

While this is helpful, these packges also have dependencies, and those
dependencies have dependencies. The R core team have built out the
`tools` package which contains, yes, wonderful tools. The function
`tools::package_dependencies()` provides us with the dependencies.

The below code identifies the top 500 downloaded packages and their
dependencies.

``` r
top_500_cran <- top_n(total_cran_downloads, 500, total_downloads)

#pull the package dependencies
pkg_deps <- top_500_cran %>%
  pull(package) %>%
  tools::package_dependencies(recursive = TRUE)
```

``` r
head(pkg_deps)
```

    ## $abind
    ## [1] "methods" "utils"  
    ## 
    ## $acepack
    ## character(0)
    ## 
    ## $ade4
    ## [1] "graphics"  "grDevices" "methods"   "stats"     "utils"     "MASS"     
    ## 
    ## $AER
    ##  [1] "car"          "lmtest"       "sandwich"     "survival"    
    ##  [5] "zoo"          "stats"        "Formula"      "carData"     
    ##  [9] "abind"        "MASS"         "mgcv"         "nnet"        
    ## [13] "pbkrtest"     "quantreg"     "grDevices"    "utils"       
    ## [17] "graphics"     "maptools"     "rio"          "lme4"        
    ## [21] "nlme"         "Matrix"       "methods"      "splines"     
    ## [25] "lattice"      "grid"         "parallel"     "boot"        
    ## [29] "minqa"        "nloptr"       "Rcpp"         "RcppEigen"   
    ## [33] "sp"           "foreign"      "SparseM"      "MatrixModels"
    ## [37] "tools"        "haven"        "curl"         "data.table"  
    ## [41] "readxl"       "openxlsx"     "tibble"       "forcats"     
    ## [45] "hms"          "readr"        "rlang"        "tidyselect"  
    ## [49] "zip"          "stringi"      "cellranger"   "progress"    
    ## [53] "cli"          "crayon"       "fansi"        "pillar"      
    ## [57] "pkgconfig"    "rematch"      "assertthat"   "glue"        
    ## [61] "ellipsis"     "magrittr"     "vctrs"        "utf8"        
    ## [65] "prettyunits"  "R6"           "clipr"        "BH"          
    ## [69] "purrr"        "digest"      
    ## 
    ## $AlgDesign
    ## character(0)
    ## 
    ## $ape
    ##  [1] "nlme"      "lattice"   "graphics"  "methods"   "stats"    
    ##  [6] "tools"     "utils"     "parallel"  "Rcpp"      "grid"     
    ## [11] "grDevices"

## Package Checks

Each package on CRAN goes through a rigorous checking process. The r cmd
check is ran on each package for twelve different flavors from a
combination of Linux and Windows. If you trust the checks that the R
Core team do, I wouldn’t reinvent the wheel.

The data are not provided directly from CRAN though an individual has
provided these data via an API. I recommend using the API as a check
against packages on ingest. I’d also do this process for every time
you’re syncing. Again, this doesn’t mean that there are no
vulnerabilities. But if there are functions that will literally break
the machine, then the checks in general shouldn’t work.

The biggest risk is really in the development and publication of
applications. The greatest risk you are likely to face are going to be
internal or accidental. For example using base R and Shiny, a developer
can make an app unintentionally malicious—i.e. permitting system calls
or creating a SQL injection. Though this would be rather difficult to
build into an app, it is possible. The process here would be to
institute a peer review process for the apps developed. Also, you’re
going to want to sandbox the applications—which Connect does and will
improve with launcher in the future.

## Instituting Checks

We can use the [`cchecks`](https://github.com/ropenscilabs/cchecks)
packge to interact with R-Hub’s CRAN check API. They have done a
wonderful job aggregating package check data. The data it returns,
however, is in a rather deeply nested list. Below is a function
defintion which can tidy up some of the important information produced
from the API query.

``` r
#devtools::install_github("ropenscilabs/cchecks")

library(cchecks)
library(tidyverse)

tidy_checks <- function(checks) {

  check_res <- map(checks, pluck, "data", "checks")
  check_pkg <- map(checks, pluck, "data", "package")
  check_deets <- map(checks, pluck, "data", "check_details")
  
  tibble(pkg = unlist(check_pkg),
         check_results = check_res,
         check_details = check_deets)
  
}
```

``` r
# query the API for packages
checks  <- cch_pkgs(c("spotifyr", "genius"))

# tidy up the checks
clean_checks <- tidy_checks(checks)

# get check results
clean_checks %>% 
  unnest(check_results)
```

    ## # A tibble: 26 x 9
    ##    pkg   flavor version tinstall tcheck ttotal status check_url
    ##    <chr> <chr>  <chr>      <dbl>  <dbl>  <dbl> <chr>  <chr>    
    ##  1 spot… r-dev… 2.1.1      12.3    86.2   98.4 OK     https://…
    ##  2 spot… r-dev… 2.1.1       9.76   64.8   74.6 OK     https://…
    ##  3 spot… r-dev… 2.1.1       0       0    116.  OK     https://…
    ##  4 spot… r-dev… 2.1.1       0       0    112.  OK     https://…
    ##  5 spot… r-dev… 2.1.1      31     102    133   OK     https://…
    ##  6 spot… r-dev… 2.1.1      33      96    129   OK     https://…
    ##  7 spot… r-pat… 2.1.1       9.42   74.4   83.8 OK     https://…
    ##  8 spot… r-pat… 2.1.1       0       0    162.  OK     https://…
    ##  9 spot… r-rel… 2.1.1      10.8    75.8   86.6 OK     https://…
    ## 10 spot… r-rel… 2.1.1      33     120    153   OK     https://…
    ## # … with 16 more rows, and 1 more variable: check_details <list>

``` r
# get check details
clean_checks %>% 
  unnest_wider(check_details)
```

    ## # A tibble: 2 x 7
    ##   pkg    check_results  version check     result output             flavors
    ##   <chr>  <list>         <chr>   <chr>     <chr>  <chr>              <list> 
    ## 1 spoti… <df[,7] [13 ×… <NA>    <NA>      <NA>    <NA>              <???>  
    ## 2 genius <df[,7] [13 ×… 2.2.0   R files … WARN   "Warnings in file… <chr […

You can pull these checks for the top 500 packages and their
dependencies in a rather straightforward manner now. You can iterate
through these all. Note that this is an API and you may see some lag
time. So go make some tea.

``` r
top_checks <- cch_pkgs(head(top_500_cran$package))

tidy_checks(top_checks)
```

    ## # A tibble: 6 x 3
    ##   pkg       check_results     check_details   
    ##   <chr>     <list>            <list>          
    ## 1 abind     <df[,7] [13 × 7]> <NULL>          
    ## 2 acepack   <df[,7] [13 × 7]> <named list [6]>
    ## 3 ade4      <df[,7] [13 × 7]> <named list [6]>
    ## 4 AER       <df[,7] [13 × 7]> <named list [6]>
    ## 5 AlgDesign <df[,7] [13 × 7]> <named list [6]>
    ## 6 ape       <df[,7] [13 × 7]> <named list [6]>

### Resources

  - <https://environments.rstudio.com/validation.html>
  - <https://www.r-bloggers.com/overview-of-the-cran-checks-api/amp>
  - <https://blog.r-hub.io/2019/04/25/r-devel-linux-x86-64-debian-clang/>
