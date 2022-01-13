

mapping_generic  <- list(V = c('VB', 'VBD', 'VBG', 'VBN', 'VBP', 'VBZ'),
                         N = c('NN', 'NNP', 'NNPS', 'NNS'),
                         ADJ = c('JJ', 'JJR', 'JJS'),
                         ADV = c('RB', 'RBR', 'RBS')
)


mapping_biber  <- list(V = c('VB', 'VBD', 'VBG', 'VBN', 'VBP', 'VBZ'),
                       N = c('NN', 'NNP', 'NNPS', 'NNS'),
                       ADJ = c('JJ', 'JJR', 'JJS'),
                       ADV = c('RB', 'RBR', 'RBS'),
                       AUX = c('MODAL', 'HAVE', 'BE', 'DO', 'S'),
                       PRO = c('SUBJPRO', 'OBJPRO', 
                               'POSSPRO', 'REFLEXPRO', 
                               'YOU', 'HER', 'IT'),
                       DET = c('ART', 'DEM', 'QUAN', 'NUM'),
                       ALLP = c('CLP', ','),
                       
                       ## may want to add to verb list -- no ??
                       PRV = c('SUAPRV', 'PRV'),
                       PUB = c('SUAPUB', 'PUB'),
                       SUA = c('SUA', 'SUAPUB', 'SUAPRV'))

setwd('/home/jtimm/pCloudDrive/GitHub/packages/textsearch/data')
usethis::use_data(mapping_biber, overwrite=TRUE)
usethis::use_data(mapping_generic, overwrite=TRUE)

