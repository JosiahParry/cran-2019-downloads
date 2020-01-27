library(tidyverse)

# read in 2019 package downloads
total_cran_downloads <- read_csv("data/cran-2019-total-downloads.csv")

# replace 500 with whatever number of packages you want in your environment
top_500_cran <- top_n(total_cran_downloads, 500, total_downloads)

# pull the package dependencies
pkg_deps <- top_500_cran %>% 
  pull(package) %>% 
  tools::package_dependencies(recursive = TRUE)

# write text file for top 500 cran packages
write_lines(pull(top_500_cran, package), "data/top-500-cran.txt")

# write text file for top 500 cran package dependencies
write_lines(unique(unlist(pkg_deps)), "data/top-500-cran-deps.txt")

