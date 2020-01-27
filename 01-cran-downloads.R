library(rvest)
library(tidyverse)

url <- "https://cran.r-project.org/web/packages/available_packages_by_name.html"

cran_packages <- html_session(url) %>% 
    html_nodes("table a") %>% 
    html_text()

get_year_downloads <- function(pkg) {
  cranlogs::cran_downloads(pkg, 
                           from = "2019-01-01",
                           to = "2019-12-31") %>% 
    group_by(package) %>% 
    summarise(total_downloads = sum(count))
}

total_cran_downloads <- furrr::future_map_dfr(cran_packages, 
                                              .f = possibly(get_year_downloads, otherwise = tibble()))
#write_csv(total_cran_downloads, "data/cran-2019-total-downloads.csv")
