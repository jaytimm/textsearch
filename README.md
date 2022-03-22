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

| doc_id |  id | pattern | context                                                                                                                                                                                                                                                 |
|:-------|----:|:--------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 54     | 289 | Party   | In 1935, the Agrarian Party, now the Centre Party, chose to ally itself with the Labour `Party` . “This political agreement was crucial to preventing anyone from harbouring authoritarian ambitions here.” Wolff also                                  |
| 60     | 300 | parties | `parties` , Prime Minister Narendra Modi on Saturday said that “blind opposition, continuous opposition, acute frustration and                                                                                                                          |
| 5      |  22 | part    | Zionism as “fundamentally different from those projects of European settler-colonialism” such as Algeria. His opportunism is `part` of a long tradition of high-profile British social democrats policing the boundaries of acceptable public discourse |

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
| 7      | was/VBD hailed/VBN by/IN                   |  3940 |  3964 |
| 7      | was/VBD hailed/VBN by/IN                   |  7523 |  7547 |
| 7      | was/VBD marked/VBN by/IN                   | 22375 | 22399 |

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

| doc_id | sentence_id | construction                    | text                                                                                                                                                                                                                   |
|:-------|------------:|:--------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 79     |           1 | is/VBZ backed/VBN by/IN         | Legislation deemed partisan will now only be debated on the USGT floor if it `is backed by` a two-thirds majority vote .                                                                                               |
| 50     |          27 | is/VBZ modeled/VBN by/IN        | “ In general , the public seems more willing to adhere to guidelines put forth by state leaders if the underlying rationale is clearly communicated and `is modeled by` leaders , ” Benjamin-Neelon wrote .            |
| 71     |          16 | was/VBD characterized/VBN by/IN | The researchers developed a measure of anti-establishment orientation that `was characterized by` conspiratorial , populist , and Manichean worldviews .                                                               |
| 28     |          74 | was/VBD conducted/VBN by/IN     | At the University of Wisconsin-Milwaukee , a study `was conducted by` doctoral student Amir Forati and master’s student Rachel Hansen on the geographical impact of social media in regards to the COVID-19 pandemic . |
| 53     |          23 | is/VBZ thought/VBN by/IN        | Speaking in tongues `is thought by` charismatic or Pentecostal evangelicals to be the ability to speak in different or angelic languages to transmit a message from the divine .                                       |

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

| doc_id | sentence_id | example                                                                                                                                                                                                                                                                                                                      |
|:-------|------------:|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 70     |          18 | System justification `is_characterized_by` defending and justifying the societal status quo .                                                                                                                                                                                                                                |
| 66     |          17 | The teacher `is_paid_by` the union and the district is reimbursed for any administrative costs the employee accrues .                                                                                                                                                                                                        |
| 7      |          27 | It is fair to wonder , as some commentators have , what the Macron of 2021 — a tough-talking defender of the nation who leans right and flouts neoliberal economic wisdom — has in common with the Macron of 2017 , who `was_hailed_by` the anglophone press as liberalism’s savior in the face of Western populist surges . |
| 66     |           6 | While a similar bill `was_advanced_by` the Senate last year before stalling in the House , this year’s bill did not receive a committee hearing .                                                                                                                                                                            |
| 30     |          39 | Throughout the last two decades , the increase in social support allocations `was_followed_by` an increase in social demands and more pressure on successive governments to address the issue of social justice .                                                                                                            |

## Summary
