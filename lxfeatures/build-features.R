
ld <- '/home/jtimm/pCloudDrive/GitHub/packages/lxfeatures/data/'

fs <- read.csv('/home/jtimm/pCloudDrive/GitHub/packages/lxfeatures/data-raw/biber-features1.csv')
fs$label <- paste0('f', fs$fid, '_', fs$feature)

biber_lx_features <- fs
data.table::setDT(biber_lx_features)
biber_lx_features[, X := NULL]
setwd(ld)
usethis::use_data(biber_lx_features, overwrite=TRUE)

fs0 <- subset(fs, type %in% c('lemma', 'lemma_pos'))
uni <- unique(fs0$label)


for (i in 1:length(uni)) {
  x0 <- subset(fs0, label == uni[i])
  x1 <- c(x0$lemma)
  assign(uni[i], x1)
}

filename <- file.path(ld, paste0('features.rda'))
save(list = uni, file = filename)
tools::resaveRdaFiles(filename)
