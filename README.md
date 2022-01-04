# linguistic features

``` r
library(tidyverse)
```

### Build a corpus from current news

``` r
rss1 <- lapply(c('economy', 
                 'covid', 
                 'biden', 
                 'depression', 
                 'merkel', 
                 'trump', 
                 'jobs'),
               
               quicknews::qnews_build_rss)

meta <- lapply(unlist(rss1), quicknews::qnews_strip_rss)
meta <- data.table::rbindlist(meta)
meta <- unique(meta)

news <- quicknews::qnews_extract_article(url = meta$link[1:100], 
                                         cores = 7) %>% 
  left_join(meta) %>%
  mutate(doc_id = row_number() )
```

### Annotate corpus

``` r
setwd(locald)
udmodel <- udpipe::udpipe_load_model('english-ewt-ud-2.3-181115.udpipe')

anno <- news %>% 
  text2df::tif2sentence() %>%
  text2df::tif2token() %>%
  #text2df::token2mwe(mwe = MWE) %>%
  text2df::token2annotation(model = udmodel)
```

## Search process –

### Build inline TIF

``` r
inline_tif <- lxfeatures::build_inline(df = anno, 
                           form = 'token', 
                           tag = 'xpos')
```

### Optionally set tag mappings

``` r
generic_mapping  <- list(V = c('VB', 'VBD', 'VBG', 'VBN', 'VBP', 'VBZ'),
                         N = c('NN', 'NNP', 'NNPS', 'NNS'),
                         ADJ = c('JJ', 'JJR', 'JJS'),
                         ADV = c('RB', 'RBR', 'RBS')
                         )
```

### Build inline query

``` r
## f18 = 'BE (ADV)* VBN by'
search <- lxfeatures::translate_query(x = 'VBG the ADJ N', mapping = generic_mapping)

search %>% head() %>% knitr::kable()
```

| x                                                                            |
|:-----------------------------------------------------------------------------|
| VBG\~+ +\~the (JJ\~+ \|JJR\~+ \|JJS\~+ )(NN\~+ \|NNP\~+ \|NNPS\~+ \|NNS\~+ ) |

### Identify - extract grammatical constructions –

``` r
found <- lxfeatures::find_gramx(tif = inline_tif, query = search)
```

### Add sentential context to a `gramx` object –

``` r
f_sentence <- lxfeatures::add_context(gramx = found,
                          df = anno,
                          form = 'token', 
                          tag = 'xpos',
                          highlight = '|')

f_sentence %>% sample_n(5) %>% knitr::kable()
```

| doc_id | sentence_id | construction                                      | text                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
|:-------|------------:|:--------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 11     |          77 | VBG\~involving DT\~the JJ\~economic NNS\~dynamics | That changed abruptly in 2021 , for reasons \|involving the economic dynamics\| discussed above .                                                                                                                                                                                                                                                                                                                                                                                                                   |
| 36     |           4 | VBG\~inspiring DT\~the JJ\~next NN\~generation    | They include strengthening the global financial safety net , promoting good quality jobs in the face of the “ Great Resignation , ” assessing the future of multilateralism and global governance , reversing COVID-19 ’ s impact on extreme poverty , \|inspiring the next generation\| of women leaders , addressing America’s crisis of despair , transforming and improving education systems , harnessing technology for inclusive growth , developing climate policy for sustainable development , and more . |
| 89     |          22 | VBG\~becoming DT\~the JJ\~next NN\~front          | Capital markets are \|becoming the next front\| in the geopolitical competition between democracies and autocracies .                                                                                                                                                                                                                                                                                                                                                                                               |
| 62     |          20 | VBG\~coming DT\~the JJ\~major NNS\~ports          | Now and in the \|coming the major ports\| of Los Angeles and Long Beach , which account for 40 percent of containerized shipping , along with firms such as Walmart , FedEx and UPS will be operating 24 / 7 .                                                                                                                                                                                                                                                                                                      |
| 19     |           2 | VBG\~plaguing DT\~the JJ\~entire NN\~world        | The uncertainties \|plaguing the entire world\| are enormous .                                                                                                                                                                                                                                                                                                                                                                                                                                                      |

### Recode constructions – per annotated DF –

``` r
simple_np <- '(DT)?(ADJ|N)+(N)+'

# noun_phrases <- '(M|A|N)+N(P+D*(M|A|N)*N)*'

search_np <- lxfeatures::translate_query(x = simple_np, mapping = generic_mapping)
```

``` r
found0 <- lxfeatures::find_gramx(tif = inline_tif, query = search_np)

new_anno <- lxfeatures::recode_gramx(df = anno,
                         gramx = found0,
                         form = 'token', 
                         tag = 'xpos',
                         col = 'xpos',
                         new_cat = 'NPhrase',
                         renumber = T
                         )
```

## Some Biber (1988) odds/ends –

From: Biber, D. (1988). *Variation across speech and writing*. Cambridge
University Press.

### Lexical features

``` r
anno[, biber := lxfeatures::biber_tags(token = anno$token, tag = anno$xpos)]
```

    ## Warning in `[.data.table`(anno, , `:=`(biber, lxfeatures::biber_tags(token =
    ## anno$token, : Invalid .internal.selfref detected and fixed by taking a (shallow)
    ## copy of the data.table so that := can add this new column by reference. At an
    ## earlier point, this data.table has been copied by R (or was created manually
    ## using structure() or similar). Avoid names<- and attr<- which in R currently
    ## (and oddly) may copy the whole data.table. Use set* syntax instead to avoid
    ## copying: ?set, ?setnames and ?setattr. If this message doesn't help, please
    ## report your use case to the data.table issue tracker so the root cause can be
    ## fixed or this message improved.

### Lexico-grammatical features

``` r
biber_mapping  <- list(V = c('VB', 'VBD', 'VBG', 'VBN', 'VBP', 'VBZ'),
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
                       SUA = c('SUA', 'SUAPUB', 'SUAPRV')
                       )
```

``` r
zz <- list(f18 = 'BE (ADV)* VBN by',
           f29 = 'NOUN that (ADV)* VBD', # *
           f19 = 'BE (DET|POSSPRO|PREP|ADJ)',
           f22 = 'ADJ that',
           f30 = 'NOUN that (DET|SUBJPRO|POSSPRO)', # *
           f33 = 'PREP WHP',
           f62 = 'to (ADV)+ VB',
           f61 = 'PREP CL-P',
           cc = 'MODAL V') # *
```
