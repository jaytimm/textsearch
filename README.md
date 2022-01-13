# textsearch

A simple framework for searching annotated corpora for grammatical
constructions in context. With some add-on functionality for featurizing
texts per [Biber
(1988)](https://scholar.google.com/citations?view_op=view_citation&hl=en&user=mdWIU4MAAAAJ&alert_preview_top_rm=2&citation_for_view=mdWIU4MAAAAJ:u-x6o8ySG0sC).

## Installation

You can download the development version from GitHub with:

``` r
remotes::install_github("jaytimm/textsearch")
```

## Usage

## Build a corpus

``` r
library(tidyverse)
```

``` r
rss1 <- lapply(c('economy', 
                 'biden', 
                 'jobs'),
               
               quicknews::qnews_build_rss)

meta <- lapply(unlist(rss1), 
               quicknews::qnews_strip_rss) %>%
  bind_rows() %>% 
  distinct()

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

## Search process

### Build inline TIF

``` r
inline_tif <- textsearch::build_inline(df = anno, 
                                       form = 'token', 
                                       tag = 'xpos')

strwrap(inline_tif$text[1], width = 60)[1:5]
```

    ## [1] "DT~The JJ~economic NNS~numbers IN~that NN~government"      
    ## [2] "NNS~statisticians RB~routinely VB~produce NN~matter .~."   
    ## [3] "NNS~Statistics VBP~are JJ~fundamental IN~to"               
    ## [4] "VBG~understanding WP~what VBZ~is VBG~going RP~on IN~in"    
    ## [5] "DT~the NN~economy ,~, VBG~including DT~the NN~health IN~of"

### Optionally set tag mappings

``` r
textsearch::mapping_generic
```

    ## $V
    ## [1] "VB"  "VBD" "VBG" "VBN" "VBP" "VBZ"
    ## 
    ## $N
    ## [1] "NN"   "NNP"  "NNPS" "NNS" 
    ## 
    ## $ADJ
    ## [1] "JJ"  "JJR" "JJS"
    ## 
    ## $ADV
    ## [1] "RB"  "RBR" "RBS"

### Build inline query

``` r
f18 <- '(is|was) (ADV)* VBN by'
search <- textsearch::translate_query(x = f18,
                                      mapping = textsearch::mapping_generic)

search
```

    ## [1] "\\S+~(is|was) (RB~\\S+ |RBR~\\S+ |RBS~\\S+ )*VBN~\\S+ \\S+~by "

### Identify - extract grammatical constructions

``` r
found <- textsearch::find_gramx(tif = inline_tif, query = search)

found %>% slice(3:9) %>% knitr::kable()
```

| doc_id | construction                           | start |   end |
|:-------|:---------------------------------------|------:|------:|
| 15     | VBD\~was VBN\~beaten IN\~by            | 14082 | 14106 |
| 24     | VBD\~was VBN\~cut IN\~by               |  1499 |  1520 |
| 27     | VBZ\~is VBN\~established IN\~by        |  9483 |  9511 |
| 30     | VBD\~was VBN\~fueled IN\~by            |   737 |   761 |
| 35     | VBZ\~is RB\~not VBN\~authorized IN\~by |    26 |    60 |
| 35     | VBZ\~is RB\~not VBN\~authorized IN\~by |  4777 |  4811 |
| 39     | VBZ\~is RB\~primarily VBN\~held IN\~by |  2123 |  2157 |

### Add sentential context

``` r
f_sentence <- textsearch::add_context(gramx = found,
                                      df = anno,
                                      form = 'token', 
                                      tag = 'xpos',
                                      highlight = '`')

f_sentence %>% slice(3:9) %>% knitr::kable()
```

| doc_id | sentence_id | construction                           | text                                                                                                                                              |
|:-------|------------:|:---------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------|
| 15     |          62 | VBD\~was VBN\~beaten IN\~by            | A gay rights activist `was beaten by` the police in October , showing what activists said was increased targeting by the police since July 25 .   |
| 24     |           5 | VBD\~was VBN\~cut IN\~by               | Similarly , the 2021 forecast for global growth `was cut by` 0.1 percentage points to 5.1 % .                                                     |
| 27     |          43 | VBZ\~is VBN\~established IN\~by        | ” We acknowledge the value of the SME100 Award , which `is established by` a globally-reputed organization .                                      |
| 30     |           4 | VBD\~was VBN\~fueled IN\~by            | Fashion saw a big boost last year with consumer spending that `was fueled by` government stimulus , pent-up demand and a stay-at-home mentality . |
| 35     |           1 | VBZ\~is RB\~not VBN\~authorized IN\~by | This communication `is not authorized by` any candidate or candidate’s committee .                                                                |
| 35     |          20 | VBZ\~is RB\~not VBN\~authorized IN\~by | This communication `is not authorized by` any candidate or candidate’s committee .                                                                |
| 39     |           8 | VBZ\~is RB\~primarily VBN\~held IN\~by | Student loan debt `is primarily held by` borrowers who were raised in higher-income households and now live in higher-income households .         |

### Recode constructions

A simple noun phrase search:

``` r
simple_np <- '(DT)?(ADJ|N)+(N)+'

search_np <- textsearch::translate_query(x = simple_np,
                                         mapping = textsearch::mapping_generic)
```

Concatenate and re-code `find_gramx()` results in annotated data frame:

``` r
found0 <- textsearch::find_gramx(tif = inline_tif, 
                                 query = search_np)

# this needs a sep parameter -- 
new_anno <- textsearch::recode_gramx(df = anno,
                                     gramx = found0,
                                     form = 'token', 
                                     tag = 'xpos',
                                     
                                     col = 'xpos',
                                     new_cat = 'NPhrase',
                                     renumber = T)
```

``` r
new_anno %>% 
  select(doc_id, sentence_id, token_id,
         term_id, token, xpos) %>%
  slice(1:10) %>%
  knitr::kable()
```

| doc_id | sentence_id | token_id | term_id | token                    | xpos    |
|:-------|------------:|:---------|--------:|:-------------------------|:--------|
| 1      |           1 | 1        |       1 | The_economic_numbers     | NPhrase |
| 1      |           1 | 2        |       2 | that                     | IN      |
| 1      |           1 | 3        |       3 | government_statisticians | NPhrase |
| 1      |           1 | 4        |       4 | routinely                | RB      |
| 1      |           1 | 5        |       5 | produce                  | VB      |
| 1      |           1 | 6        |       6 | matter                   | NN      |
| 1      |           1 | 7        |       7 | .                        | .       |
| 1      |           2 | 1        |       8 | Statistics               | NNS     |
| 1      |           2 | 2        |       9 | are                      | VBP     |
| 1      |           2 | 3        |      10 | fundamental              | JJ      |

## Some Biber (1988) odds/ends

From: Biber, D. (1988). *Variation across speech and writing*. Cambridge
University Press.

### Tags

``` r
anno[, biber := textsearch::biber_tags(token = anno$token, 
                                       tag = anno$xpos)]
```

Eg:

``` r
anno %>% 
  select(doc_id, sentence_id, token, 
         xpos, biber) %>%
  slice(1:10) %>%
  knitr::kable()
```

| doc_id | sentence_id | token         | xpos | biber |
|:-------|------------:|:--------------|:-----|:------|
| 1      |           1 | The           | DT   | ART   |
| 1      |           1 | economic      | JJ   | JJ    |
| 1      |           1 | numbers       | NNS  | NNS   |
| 1      |           1 | that          | IN   | DEM   |
| 1      |           1 | government    | NN   | NN    |
| 1      |           1 | statisticians | NNS  | NNS   |
| 1      |           1 | routinely     | RB   | RB    |
| 1      |           1 | produce       | VB   | VB    |
| 1      |           1 | matter        | NN   | NN    |
| 1      |           1 | .             | .    | CLP   |

### Mappings

``` r
textsearch::mapping_biber
```

    ## $V
    ## [1] "VB"  "VBD" "VBG" "VBN" "VBP" "VBZ"
    ## 
    ## $N
    ## [1] "NN"   "NNP"  "NNPS" "NNS" 
    ## 
    ## $ADJ
    ## [1] "JJ"  "JJR" "JJS"
    ## 
    ## $ADV
    ## [1] "RB"  "RBR" "RBS"
    ## 
    ## $AUX
    ## [1] "MODAL" "HAVE"  "BE"    "DO"    "S"    
    ## 
    ## $PRO
    ## [1] "SUBJPRO"   "OBJPRO"    "POSSPRO"   "REFLEXPRO" "YOU"       "HER"      
    ## [7] "IT"       
    ## 
    ## $DET
    ## [1] "ART"  "DEM"  "QUAN" "NUM" 
    ## 
    ## $ALLP
    ## [1] "CLP" ","  
    ## 
    ## $PRV
    ## [1] "SUAPRV" "PRV"   
    ## 
    ## $PUB
    ## [1] "SUAPUB" "PUB"   
    ## 
    ## $SUA
    ## [1] "SUA"    "SUAPUB" "SUAPRV"

### Some features

``` r
zz <- list(f18 = 'BE (ADV)* VBN by',
           f29 = 'NOUN that (ADV)* VBD', # *
           f19 = 'BE (DET|POSSPRO|PREP|ADJ)',
           f22 = 'ADJ that',
           f30 = 'NOUN that (DET|SUBJPRO|POSSPRO)', # *
           f33 = 'PREP WHP',
           f62 = 'to (ADV)+ VB',
           f61 = 'PREP CL-P') # *
```
