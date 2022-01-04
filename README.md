## linguistic features

``` r
library(tidyverse)
```

## Build a corpus from current news

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

## Annotate corpus

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

search
```

    ## [1] "VBG~\\S+ \\S+~the (JJ~\\S+ |JJR~\\S+ |JJS~\\S+ )(NN~\\S+ |NNP~\\S+ |NNPS~\\S+ |NNS~\\S+ )"

### Identify - extract grammatical constructions –

``` r
found <- lxfeatures::find_gramx(tif = inline_tif, query = search)

found %>% head() %>% knitr::kable()
```

| doc_id | construction                                      | start |   end |
|:-------|:--------------------------------------------------|------:|------:|
| 5      | VBG\~suppressing DT\~the JJ\~initial NN\~wave     |  6673 |  6714 |
| 11     | VBG\~involving DT\~the JJ\~economic NNS\~dynamics | 13108 | 13153 |
| 19     | VBG\~plaguing DT\~the JJ\~entire NN\~world        |   112 |   150 |
| 22     | VBG\~posting DT\~the JJS\~best NNS\~returns       |  4893 |  4932 |
| 36     | VBG\~inspiring DT\~the JJ\~next NN\~generation    |  1220 |  1262 |
| 43     | VBG\~ending DT\~the JJ\~abusive NN\~practice      | 10640 | 10680 |

### Add sentential context to a `gramx` object –

``` r
f_sentence <- lxfeatures::add_context(gramx = found,
                          df = anno,
                          form = 'token', 
                          tag = 'xpos',
                          highlight = '`')

f_sentence %>% sample_n(5) %>% knitr::kable()
```

| doc_id | sentence_id | construction                                      | text                                                                                                                                                                                                                                                                            |
|:-------|------------:|:--------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 11     |          77 | VBG\~involving DT\~the JJ\~economic NNS\~dynamics | That changed abruptly in 2021 , for reasons `involving the economic dynamics` discussed above .                                                                                                                                                                                 |
| 43     |          43 | VBG\~ending DT\~the JJ\~abusive NN\~practice      | Arguably , the regulator that gig companies most fear is the Labor Department , which has said it’s “ committed to `ending the abusive practice` of misclassifying employees as independent contractors , which deprives these workers of critical protections and benefits . ” |
| 19     |           2 | VBG\~plaguing DT\~the JJ\~entire NN\~world        | The uncertainties `plaguing the entire world` are enormous .                                                                                                                                                                                                                    |
| 75     |          41 | VBG\~delivering DT\~the JJ\~full NNS\~gains       | They see the economy showing signs of what liberal economists have long said is the recipe for `delivering the full gains` of economic growth to low-paid and middle-class workers , even after factoring in rising prices .                                                    |
| 22     |          21 | VBG\~posting DT\~the JJS\~best NNS\~returns       | All 11 sectors finished 2021 higher , with energy and real estate `posting the best returns` .                                                                                                                                                                                  |

### Recode constructions – per annotated DF –

``` r
simple_np <- '(DT)?(ADJ|N)+(N)+'

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

Some patterns:

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
