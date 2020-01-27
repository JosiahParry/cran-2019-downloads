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