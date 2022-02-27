# textsearch

A simple framework for searching corpora for lexical & grammatical
patterns in context. At present, functions facilitate two types of
search: (1) TIF search, ie, raw, un-annotated text search, and (2)
annotated corpus search.

For dependency-based search, see [this lovely package]().

## Installation

------------------------------------------------------------------------

You can download the development version from GitHub with:

``` r
remotes::install_github("jaytimm/textsearch")
```

## Usage

------------------------------------------------------------------------

## TIF search

### Build corpus

``` r
library(tidyverse)
```

``` r
rss1 <- quicknews::qnews_build_rss(x = 'political ideology')
meta <- quicknews::qnews_strip_rss(rss1) 
news <- quicknews::qnews_extract_article(url = meta$link, cores = 7)
tif <- merge(news, meta)
tif$doc_id <- c(1:nrow(tif))

list(Date = tif$date[1],
     Source = tif$source[1],
     Title = tif$title[1],
     Article = strwrap(tif$text[1], 
                       width = 60)[1:5])
```

    ## $Date
    ## [1] "2022-02-23"
    ## 
    ## $Source
    ## [1] "Chinadaily USA"
    ## 
    ## $Title
    ## [1] "50 years after Nixon's visit, time for kung fu diplomacy"
    ## 
    ## $Article
    ## [1] "Fifty years ago on February 21, 1972, then-US president"  
    ## [2] "Richard Nixon arrived in Beijing, breaking the ice of the"
    ## [3] "Cold War. By 1979 formal relations were established. A"   
    ## [4] "honeymoon era of China-US relations began paralleling"    
    ## [5] "China's policies of opening its economy and encouraging"

### Queries

``` r
parts <- '\\bpart[a-z]*\\b'
pols <- 'political \\w+'
terms <- c('populism', 'political ideology')
```

``` r
textsearch::find_lex(query = pols,
                     text = tif$text,
                     doc_id = tif$doc_id,
                     window = 15,
                     highlight = c('`', '`')) %>%
  slice(1:3) %>%
  knitr::kable(escape = F)
```

| doc_id |  id | pattern             | context                                                                                                                                                                                                                                                      |
|:-------|----:|:--------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1      |   1 | political system    | thinking of Washington DC politicians. The idea of accepting another viewpoint, much less another economic or `political system` , is intolerable among Washington elites. Today intolerance is deeply imbedded in both Washington’s international relations |
| 1      |   2 | political divisions | Today intolerance is deeply imbedded in both Washington’s international relations and own domestic party politics, where `political divisions` are stark and ideology itself is split along sharp lines of incompatible duality. At a level                  |
| 1      |   3 | political ideology  | and ideology itself is split along sharp lines of incompatible duality. At a level deeper than `political ideology` is philosophy. Among the Washington elite, it is all about opposites, polarities, exclusion, expulsion, and conflicting                  |

``` r
set.seed(99)
textsearch::find_lex(query = parts,
                     text = tif$text,
                     doc_id = tif$doc_id,
                     window = 15,
                     highlight = c('`', '`')) %>%
  sample_n(3) %>%
  knitr::kable(escape = F)
```

| doc_id |  id | pattern  | context                                                                                                                                                                                                                  |
|:-------|----:|:---------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 65     | 432 | part     | time to end the show like we do every week with Can’t Let It Go, the `part` of the show where we talk about things from the week we cannot stop talking about,                                                           |
| 45     | 289 | partisan | political views to pupils. In some circumstances, it may be appropriate for external agencies to express `partisan` political views to pupils. Pupils must understand that these are contested views and still receive a |
| 91     | 534 | parts    | growth and increasing prosperity,” and at the same time “a period of shrinking inequality in many `parts` of the world.” What kept inequality in check, the report notes, was policies that ensured minimum              |

## Annotated corpus search

### Annotate corpus

``` r
setwd(locald)
udmodel <- udpipe::udpipe_load_model('english-ewt-ud-2.3-181115.udpipe')

annotation <- tif %>% 
  text2df::tif2sentence() %>%
  text2df::tif2token() %>%
  text2df::token2annotation(model = udmodel)
```

### Build inline TIF

``` r
inline_tif <- textsearch::build_inline(df = annotation, 
                                       form = 'token', 
                                       tag = 'xpos')

strwrap(inline_tif$text[1], width = 60)[1:5]
```

    ## [1] "CD~Fifty NNS~years RB~ago IN~on NNP~February CD~21 ,~,"    
    ## [2] "CD~1972 ,~, CC~then-US NNP~president NNP~Richard NNP~Nixon"
    ## [3] "VBD~arrived IN~in NNP~Beijing ,~, VBG~breaking DT~the"     
    ## [4] "NN~ice IN~of DT~the NNP~Cold NNP~War .~. IN~By CD~1979"    
    ## [5] "JJ~formal NNS~relations VBD~were VBN~established .~. DT~A"

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

| doc_id | construction                         | start |   end |
|:-------|:-------------------------------------|------:|------:|
| 5      | VBD\~was VBN\~murdered IN\~by        | 23938 | 23964 |
| 10     | VBZ\~is VBN\~guided IN\~by           |  2962 |  2985 |
| 11     | VBZ\~is VBN\~controlled IN\~by       | 12602 | 12629 |
| 12     | VBZ\~is VBN\~defined IN\~by          |  4571 |  4595 |
| 16     | VBD\~was VBN\~impacted IN\~by        |  4415 |  4441 |
| 16     | VBZ\~is RB\~not VBN\~retained IN\~by |  7808 |  7840 |
| 20     | VBZ\~is VBN\~espoused IN\~by         | 23339 | 23364 |

### Add sentential context

``` r
f_sentence <- textsearch::add_context(gramx = found,
                                      df = annotation,
                                      form = 'token', 
                                      tag = 'xpos',
                                      highlight = '`')

set.seed(99)
f_sentence %>% sample_n(5) %>% knitr::kable()
```

| doc_id | sentence_id | construction                            | text                                                                                                                                                                                                                                          |
|:-------|------------:|:----------------------------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 69     |          29 | VBZ\~is VBN\~undercut IN\~by            | The argument , she wrote , “ `is undercut by` an utter dearth of absentee fraud . ”                                                                                                                                                           |
| 87     |          18 | VBZ\~is VBN\~driven IN\~by              | “ Since Trump wants to run for office again , the timeline of the app `is driven by` political objectives – not by readiness of the platform , ” said Jennifer Grygiel , a professor of communications at Syracuse University .               |
| 48     |          40 | VBZ\~is VBN\~powered IN\~by             | This clearly shows that CCC `is powered by` foreign powers and they are only puppets waiting for instructions from their masters .                                                                                                            |
| 69     |          69 | VBD\~was VBN\~defined IN\~by            | In a statement , Andrew Bates , a White House spokesman , defended Judge Childs’s record , noting that when she served on South Carolina’s Workers ’ Compensation Commission , “ her tenure `was defined by` fighting for injured workers . ” |
| 80     |          32 | VBD\~was RB\~not VBN\~vanquished IN\~by | Fascism , the political ideology that denies all rights to individuals in their relations with the state , `was not vanquished by` World War II , only subdued temporarily .                                                                  |

### Recode construction

``` r
new_annotation <- textsearch::recode_gramx(df = annotation,
                                     gramx = found,
                                     form = 'token', 
                                     tag = 'xpos',
                                     
                                     col = 'xpos',
                                     new_cat = 'by_passive',
                                     renumber = T)
```

``` r
new_annotation %>%
  group_by(doc_id, sentence_id) %>%
  filter(any(xpos == 'by_passive')) %>%
  mutate(token = ifelse(xpos == 'by_passive', 
                        paste0('`', token, '`'), 
                        token)) %>%
  summarize(example = paste0(token, collapse = ' ')) %>%
  ungroup() %>%
  sample_n(5) %>%
  knitr::kable()
```

    ## `summarise()` has grouped output by 'doc_id'. You can override using the
    ## `.groups` argument.

| doc_id | sentence_id | example                                                                                                                                                                                                                                       |
|:-------|------------:|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 69     |          69 | In a statement , Andrew Bates , a White House spokesman , defended Judge Childs’s record , noting that when she served on South Carolina’s Workers ’ Compensation Commission , “ her tenure `was_defined_by` fighting for injured workers . ” |
| 78     |          16 | The researchers developed a measure of anti-establishment orientation that `was_characterized_by` conspiratorial , populist , and Manichean worldviews .                                                                                      |
| 69     |          29 | The argument , she wrote , “ `is_undercut_by` an utter dearth of absentee fraud . ”                                                                                                                                                           |
| 30     |          39 | As vice president , he became Jackson’s heir apparent , and with Old Hickory’s blessing , he `was_nominated_by` the Democratic Party to be the next president of the United States .                                                          |
| 48     |          55 | The new party ( the old wine in new bottles ) `was_formed_by` Mr Morgan Tsvangirayi and Mr Gibson Sibanda on the back of the labour movement .                                                                                                |

## Summary
