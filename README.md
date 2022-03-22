# textsearch

A simple framework for searching corpora for text patterns in context.
At present, functions facilitate two types of search: (1) TIF (ie, raw
text) search for **lexical patterns** in context, and (2) annotated
corpus search for **lexico-grammatical constructions** in (sentential)
context.

## Installation

You can download the development version from GitHub with:

``` r
remotes::install_github("jaytimm/textsearch")
```

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
    ## [1] "2022-03-21"
    ## 
    ## $Source
    ## [1] "Cal Coast News"
    ## 
    ## $Title
    ## [1] "Somber departures from war-torn Ukraine"
    ## 
    ## $Article
    ## [1] "For hours upon hours, Ukrainian refugees speak to one"      
    ## [2] "another in Russian while fleeing their cities and towns,"   
    ## [3] "and often, their country. Beside a CalCoastNews reporter, a"
    ## [4] "woman, her mother and her daughter boarded a train"         
    ## [5] "departing the Ukrainian capital Kyiv for Lviv, the leading"

### Extract lexical patterns

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

| doc_id |  id | pattern              | context                                                                                                                                                                                                                                 |
|:-------|----:|:---------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1      |   1 | political ideology   | The military unit has and/or previously had ties to far-right `political ideology` . Whether or not Russia is battling Nazism, as claimed by Putin, its bombs, missiles, mortars                                                        |
| 2      |   2 | political ideologies | financial improprieties, but rather their continuous rape of democratic principles and failure to adhere to known `political ideologies` . Despite their names not appearing on the ballot paper, they believe that once elected, the   |
| 2      |   3 | political parties    | no loyalty whatsoever. Unfortunately, some Senior Advocates of Nigeria (SAN) agree with them, reasoning pedantically that `political parties` stand for nothing and are mere “vehicles” in which aspirants ride to office! Back in 1983 |

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

| doc_id |  id | pattern | context                                                                                                                                                                                                                      |
|:-------|----:|:--------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 62     | 289 | part    | down to moderate versus progressive. But what Pew actually found is that Democrats, for the most `part` , actually agree more so on the issues, which is a change from past years from,                                      |
| 64     | 300 | parts   | the Democratic spectrum. By most standards, he does tack more moderate. He wants to grow some `parts` of the NYPD. He seeks corporate partners like JetBlue. And he discourages higher taxes on the                          |
| 4      |  22 | party   | Jones describes Corbyn as “mulish” in his refusal to follow advice and his leadership of the `party` as “shambolic.” He approvingly cites Labour sources who describe Corbyn’s leadership as “clearly dysfunctional” and say |

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

    ## [1] "For/IN hours/NNS upon/IN hours/NNS ,/, Ukrainian/JJ"       
    ## [2] "refugees/NNS speak/VBP to/IN one/CD another/DT in/IN"      
    ## [3] "Russian/JJ while/IN fleeing/VBG their/PRP$ cities/NNS"     
    ## [4] "and/CC towns/NNS ,/, and/CC often/RB ,/, their/PRP$"       
    ## [5] "country/NN ./. Beside/IN a/DT CalCoastNews/NNP reporter/NN"

### Extract lexico-grammatical constructions

``` r
found <- textsearch::find_gramx(search = '(is|was) (ADV)* VBN by',
                                tif = inline_tif,
                                mapping = textsearch::mapping_generic)

found %>% slice(3:9) %>% knitr::kable()
```

| doc_id | construction                               | start |   end |
|:-------|:-------------------------------------------|------:|------:|
| 4      | was/VBD not/RB founded/VBN by/IN           | 20977 | 21009 |
| 4      | was/VBD regularly/RB used/VBN by/IN        | 22728 | 22763 |
| 4      | was/VBD successfully/RB co-opted/VBN by/IN | 23576 | 23618 |
| 6      | was/VBD hailed/VBN by/IN                   |  3940 |  3964 |
| 6      | was/VBD hailed/VBN by/IN                   |  7523 |  7547 |
| 6      | was/VBD marked/VBN by/IN                   | 22375 | 22399 |
| 6      | was/VBD substituted/VBN by/IN              | 25343 | 25372 |

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

| doc_id | sentence_id | construction                        | text                                                                                                                                                                                                              |
|:-------|------------:|:------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 82     |          34 | was/VBD revealed/VBN by/IN          | The state’s exclusionary purpose and effect `was revealed by` the map .                                                                                                                                           |
| 51     |          23 | is/VBZ thought/VBN by/IN            | Speaking in tongues `is thought by` charismatic or Pentecostal evangelicals to be the ability to speak in different or angelic languages to transmit a message from the divine .                                  |
| 69     |          42 | was/VBD authored/VBN by/IN          | The study , “ The Role of Anti-Establishment Orientations During the Trump Presidency “ , `was authored by` Adam M. Enders and Joseph E. Uscinski .                                                               |
| 29     |          39 | was/VBD followed/VBN by/IN          | Throughout the last two decades , the increase in social support allocations `was followed by` an increase in social demands and more pressure on successive governments to address the issue of social justice . |
| 55     |           4 | is/VBZ usually/RB ignored/VBN by/IN | However , the problematic political ideology that underpins the show `is usually ignored by` viewers and critics alike .                                                                                          |

### Recode construction

``` r
new_annotation <- textsearch::recode_gramx(df = annotation,
                                           gramx = found,
                                           
                                           form = 'token', 
                                           tag = 'xpos',
                                           
                                           recode_col = 'xpos',
                                           recode_cat = 'by_passive')
```

``` r
eg <- new_annotation[, if(any(token %in% 'is_thought_by')) .SD, 
                      by = list(doc_id, sentence_id)]

knitr::kable(eg[, token_id:xpos])
```

| token_id | token         | lemma         | upos  | xpos       |
|:---------|:--------------|:--------------|:------|:-----------|
| 1        | Speaking      | speak         | VERB  | VBG        |
| 2        | in            | in            | ADP   | IN         |
| 3        | tongues       | tongue        | NOUN  | NNS        |
| 4        | is_thought_by | is_thought_by | AUX   | by_passive |
| 5        | charismatic   | charismatic   | ADJ   | JJ         |
| 6        | or            | or            | CCONJ | CC         |
| 7        | Pentecostal   | Pentecostal   | ADJ   | JJ         |
| 8        | evangelicals  | evangelical   | NOUN  | NNS        |
| 9        | to            | to            | PART  | TO         |
| 10       | be            | be            | AUX   | VB         |
| 11       | the           | the           | DET   | DT         |
| 12       | ability       | ability       | NOUN  | NN         |
| 13       | to            | to            | PART  | TO         |
| 14       | speak         | speak         | VERB  | VB         |
| 15       | in            | in            | ADP   | IN         |
| 16       | different     | different     | ADJ   | JJ         |
| 17       | or            | or            | CCONJ | CC         |
| 18       | angelic       | angelic       | ADJ   | JJ         |
| 19       | languages     | language      | NOUN  | NNS        |
| 20       | to            | to            | PART  | TO         |
| 21       | transmit      | transmit      | VERB  | VB         |
| 22       | a             | a             | DET   | DT         |
| 23       | message       | message       | NOUN  | NN         |
| 24       | from          | from          | ADP   | IN         |
| 25       | the           | the           | DET   | DT         |
| 26       | divine        | divine        | NOUN  | NN         |
| 27       | .             | .             | PUNCT | .          |

## Summary
