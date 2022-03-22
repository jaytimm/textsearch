
biber_search_categories <-  read.csv('/home/jtimm/pCloudDrive/GitHub/packages/lxfeatures/data-raw/biber-search-categories1.csv', sep = ',')

data.table::setDT(biber_search_categories)
setwd('/home/jtimm/pCloudDrive/GitHub/packages/lxfeatures/data')
usethis::use_data(biber_search_categories, overwrite=TRUE)
