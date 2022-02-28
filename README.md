# textsearch

A simple framework for searching corpora for lexical & grammatical
patterns in context. At present, functions facilitate two types of
search: (1) TIF search, ie, raw, un-annotated text search, and (2)
annotated corpus search.

For dependency-based search, see [this lovely package]().

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

| doc_id |  id | pattern | context                                                                                                                                                                                                                                            |
|:-------|----:|:--------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 93     | 432 | Party   | territorial and federal governments march further and faster down the road to full authoritarianism, Yukon Freedom `Party` thinks it is time to check in with Yukoners directly,” a news release from the party                                    |
| 55     | 289 | Parti   | state seats that Opposition parties are defending, which technically excluded Larkin as its incumbent was from `Parti` Pribumi Bersatu Malaysia (Bersatu). Shortly after Muda’s announcement yesterday, however, deputy Johor PKR chief Jimmy Puah |
| 57     | 300 | part    | my family have collected memorabilia, from major sports teams to the American armed forces. It was `part` of the culture I grew up around, especially with my grandfather who was a Civil War                                                      |

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
search <- textsearch::translate_query(
  x = '(is|was) (ADV)* VBN by',
  mapping = textsearch::mapping_generic)

search
```

    ## [1] "\\S+~(is|was) (RB~\\S+ |RBR~\\S+ |RBS~\\S+ )*VBN~\\S+ \\S+~by "

### Identify/extract grammatical constructions

``` r
found <- textsearch::find_gramx(tif = inline_tif, query = search)

found %>% slice(3:9) %>% knitr::kable()
```

| doc_id | construction                          | start |   end |
|:-------|:--------------------------------------|------:|------:|
| 5      | VBD\~was VBN\~murdered IN\~by         | 23938 | 23964 |
| 8      | VBD\~was VBN\~officiated IN\~by       | 19503 | 19531 |
| 9      | VBD\~was VBN\~required IN\~by         |  8182 |  8208 |
| 9      | VBD\~was VBN\~driven IN\~by           | 14181 | 14205 |
| 9      | VBD\~was RB\~all VBN\~designed IN\~by | 16287 | 16320 |
| 12     | VBZ\~is VBN\~guided IN\~by            |  2962 |  2985 |
| 13     | VBZ\~is VBN\~controlled IN\~by        | 12602 | 12629 |

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

| doc_id | sentence_id | construction                              | text                                                                                                                                                                                                                                                                                                                                                                                          |
|:-------|------------:|:------------------------------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 90     |           6 | VBD\~was RB\~also VBN\~celebrated IN\~by  | Despite being harshly criticized by certain sectors , the politician and economist negotiated the end of the guerrilla groups that plagued his country for more than half a century and achieved an agreement , that was not only acclaimed with his receiving the 2016 Nobel Peace Prize , but `was also celebrated by` Pope Francis in his Apostolic Visit to Colombia the following year . |
| 62     |           7 | VBD\~was VBN\~given IN\~by                | The lie `was given by` those in the East German government that the Wall was meant not keep people in , but to keep the taint of Western democracy out , even as guns and binoculars , spies and informants were turned on their own people .                                                                                                                                                 |
| 76     |          42 | VBD\~was VBN\~authored IN\~by             | The study , “ The Role of Anti-Establishment Orientations During the Trump Presidency “ , `was authored by` Adam M. Enders and Joseph E. Uscinski .                                                                                                                                                                                                                                           |
| 48     |           3 | VBZ\~is RB\~often VBN\~perpetuated IN\~by | Critical race theory argues that racism is a part of everyday life and `is often perpetuated by` legal policies and practices .                                                                                                                                                                                                                                                               |
| 68     |           1 | VBZ\~is VBN\~seen IN\~by                  | The judge `is seen by` some as a long shot for the Supreme Court , but supporters say her bipartisan backing and the appeal of her humble ascent should not be overlooked .                                                                                                                                                                                                                   |

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

| doc_id | sentence_id | example                                                                                                                                                                                                                                                                                                                           |
|:-------|------------:|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 82     |          55 | But this `is_counterbalanced_by` perhaps the worst point in Rick Scott’s 60-page agenda : “ All Americans should pay some income tax to have skin in the game , even if a small amount .                                                                                                                                          |
| 69     |          45 | In San Francisco , Mr. Boudin argued that the effort to recall him `was_fueled_by` politics , not voters ’ worries about crime .                                                                                                                                                                                                  |
| 76     |          41 | The study , “ American Politics in Two Dimensions : Partisan and Ideological Identities versus Anti-Establishment Orientations “ , `was_authored_by` Joseph E. Uscinski , Adam M. Enders , Michelle I. Seelig , Casey A. Klofstad , John R. Funchion , Caleb Everett , Stefan Wuchty , Kamal Premaratne , and Manohar N. Murthi . |
| 68     |          43 | Her experience as a trial judge `is_also_cited_by` her supporters as an asset .                                                                                                                                                                                                                                                   |
| 33     |          39 | As vice president , he became Jackson’s heir apparent , and with Old Hickory’s blessing , he `was_nominated_by` the Democratic Party to be the next president of the United States .                                                                                                                                              |

## Summary
