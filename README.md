# textsearch

A simple framework for searching corpora for text patterns in context.
At present, functions facilitate two types of search: (1) TIF (ie, raw
text) search for lexical patterns in context, and (2) annotated corpus
search for lexico-grammatical patterns in (sentential) context.

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
    ## [1] "ArtReview"
    ## 
    ## $Title
    ## [1] "Why the Artworld Must Stand with Palestine"
    ## 
    ## $Article
    ## [1] "At the Academy Awards in 1999, Elia Kazan received an"     
    ## [2] "honorary Oscar in recognition of his profound contribution"
    ## [3] "to cinema. As a director, Kazan often broached the brutal" 
    ## [4] "social realities of postwar America – his films narrated"  
    ## [5] "the era’s complex conditions, relations and struggles that"

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

| doc_id |  id | pattern            | context                                                                                                                                                                                                                                       |
|:-------|----:|:-------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1      |   1 | political ideology | Communist Party USA, or for being communist sympathisers. From official literature to the popular press, such `political ideology` was relentlessly depicted as dangerous. And this campaign of leftist suppression never really ended; it is |
| 1      |   2 | political scandal  | noxious atmosphere around expressions of solidarity with Palestine means that an anonymous blog can incite a `political scandal` all the way up to the German minister of culture, spurring reactionary op-eds in respected newspapers,       |
| 2      |   3 | political ideology | The military unit has and/or previously had ties to far-right `political ideology` . Whether or not Russia is battling Nazism, as claimed by Putin, its bombs, missiles, mortars                                                              |

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

| doc_id |  id | pattern  | context                                                                                                                                                                                                                      |
|:-------|----:|:---------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 80     | 432 | partisan | defining partisanship encourages rather than prevents senators from giving their own spin on what counts as `partisan` . “In fact, I think more words on the page means there’s a little bit more                            |
| 53     | 289 | part     | is evangelicalism in the United States today? One place to begin is historian David Bebbington’s four- `part` definition of evangelicalism. In his 1989 book, Bebbington argued that evangelicals share a recognition of the |
| 54     | 300 | Party    | acted as a political ally to the liberals and the Catholics.” During the 1920s the Liberal `Party` relied on political alliances in order to gain a majority in parliament. “The choice was between                          |

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

    ## [1] "At/IN the/DT Academy/NNP Awards/NNP in/IN 1999/CD ,/,"     
    ## [2] "Elia/NNP Kazan/NNP received/VBD an/DT honorary/JJ Oscar/NN"
    ## [3] "in/IN recognition/NN of/IN his/PRP$ profound/JJ"           
    ## [4] "contribution/NN to/IN cinema/NN ./. As/IN a/DT director/NN"
    ## [5] ",/, Kazan/NNP often/RB broached/VBD the/DT brutal/JJ"

### Extract lexico-grammatical constructions

``` r
found <- textsearch::find_gramx(search = '(is|was) (ADV)* VBN by',
                                tif = inline_tif,
                                mapping = textsearch::mapping_generic)

found %>% slice(3:9) %>% knitr::kable()
```

| doc_id | construction                               | start |   end |
|:-------|:-------------------------------------------|------:|------:|
| 5      | was/VBD issued/VBN by/IN                   | 11804 | 11828 |
| 5      | was/VBD not/RB founded/VBN by/IN           | 20977 | 21009 |
| 5      | was/VBD regularly/RB used/VBN by/IN        | 22728 | 22763 |
| 5      | was/VBD successfully/RB co-opted/VBN by/IN | 23576 | 23618 |
| 7      | is/VBZ sponsored/VBN by/IN                 |  3287 |  3313 |
| 7      | was/VBD escorted/VBN by/IN                 |  8210 |  8236 |
| 7      | was/VBD enchanted/VBN by/IN                | 13482 | 13509 |

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

| doc_id | sentence_id | construction                  | text                                                                                                                                                                                                                                                                                                                            |
|:-------|------------:|:------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 72     |          41 | was/VBD authored/VBN by/IN    | The study , “ American Politics in Two Dimensions : Partisan and Ideological Identities versus Anti-Establishment Orientations “ , was authored by Joseph E. Uscinski , Adam M. Enders , Michelle I. Seelig , Casey A. Klofstad , John R. Funchion , Caleb Everett , Stefan Wuchty , Kamal Premaratne , and Manohar N. Murthi . |
| 46     |          18 | was/VBD implemented/VBN by/IN | A new Household Pulse Survey was implemented by the Census Bureau during COVID-19 and contains rich questions on COVID-19 vaccination but does not ask about party identification .                                                                                                                                             |
| 67     |          17 | is/VBZ paid/VBN by/IN         | The teacher is paid by the union and the district is reimbursed for any administrative costs the employee accrues .                                                                                                                                                                                                             |
| 23     |         177 | is/VBZ espoused/VBN by/IN     | What would you say is the actual content of the ideology that is espoused by the Chinese party-state in recent years ?                                                                                                                                                                                                          |
| 84     |          34 | was/VBD revealed/VBN by/IN    | The state’s exclusionary purpose and effect was revealed by the map .                                                                                                                                                                                                                                                           |

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

| doc_id | sentence_id | example                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
|:-------|------------:|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 67     |          17 | The teacher `is_paid_by` the union and the district is reimbursed for any administrative costs the employee accrues .                                                                                                                                                                                                                                                                                                                                                                                             |
| 72     |          41 | The study , “ American Politics in Two Dimensions : Partisan and Ideological Identities versus Anti-Establishment Orientations “ , `was_authored_by` Joseph E. Uscinski , Adam M. Enders , Michelle I. Seelig , Casey A. Klofstad , John R. Funchion , Caleb Everett , Stefan Wuchty , Kamal Premaratne , and Manohar N. Murthi .                                                                                                                                                                                 |
| 67     |          16 | There have been some cases where a teacher `is_temporarily_hired_by` a union and allowed to work from their school building .                                                                                                                                                                                                                                                                                                                                                                                     |
| 7      |          31 | For all the whining they do about cancel culture , republicans invented cancel culture . conservatives try to “ cancel ” people and institutions they disagree with all the time : Nike , Target , Dixie Chicks , NASCAR , keurig , Gillette , and French fries , a tall , yellow bird , mental health programs in schools , and books like “ The Story of Ruby Ridges , ” the true story of a 6-year-old who `was_escorted_by` federal marshals past a vicious white mob to desegregate her New Orleans school . |
| 58     |          32 | This compassionate non-violent response `was_also_taught_by` the Buddha 600 years prior to Christ ; in fact Buddhism , like Jainism , rejects any type of violence to all forms of life .                                                                                                                                                                                                                                                                                                                         |

## Summary
