#' Count ~lexical features from Biber (1991)
#'
#' @name count_lexical_features
#' @param x Annotion dataframe
#' @return A data frame
#'
#' @export
#' @rdname count_lexical_features
#'
#'


## another option would be to add features to existing annotation --

count_lexical_features <- function(x){

  feats <- lxfeatures::biber_lx_features
  anno <- data.table::data.table(x)

  ## text features
  anno[, syls := sylcount::sylcount(gsub("[^[:alnum:] ]", "", token))]

  words <-  anno[, list(WordCount = .N,
                        TypeCount = length(unique(lemma)),
                        WordLength = round(mean(nchar(token),
                                                na.rm=T), 3)
  ),
  by = list(doc_id)]

  words[, TypeTokenRatio := round(TypeCount/WordCount, 3)]
  words[, TypeCount := NULL]

  ## lexemes
  lexes <- subset(feats, type == 'lemma')
  x0 <- lexes[anno, nomatch = 0, on = 'lemma']
  lexcounts <- x0[, list(feature_count = .N), by = list(doc_id, feature)]


  #### verbs
  verbs <- subset(feats, grepl('Verbs|Modals', feature) &
                    type == 'lemma_pos')
  anno_verbs <- subset(anno, penntree %in% c('V', 'M'))
  x1 <- verbs[anno_verbs, nomatch = 0, on = 'lemma']
  verbcounts <- x1[, list(feature_count = .N), by = list(doc_id, feature)]


  ### tense
  anno_ts <- subset(anno, penntree == 'V' | upos == 'ADV')
  anno_ts[, PresentTense := ifelse(grepl('Tense=Pres', feats), 1, 0)]
  anno_ts[, PastTense := ifelse(grepl('Tense=Past', feats), 1, 0)]
  anno_ts[, Infinitives := ifelse(grepl('VerbForm=Inf', feats), 1, 0)]

  anno_ts[, Adverbs := ifelse(upos == 'ADV', 1, 0)]

  tensecounts <- anno_ts[, list(PastTense = sum(PastTense),
                                PresentTense = sum(PresentTense),
                                Infinitives = sum(Infinitives),
                                Adverbs = sum(Adverbs)),
                         by = list(doc_id)]

  ## Nouns
  anno_nom <- subset(anno, penntree == 'N')
  anno_nom[, Nominalizations := ifelse(grepl('ness(es)?$|ment(s)?$|tion(s)?$|ity|ities$', token) &
                                         syls > 2 &
                                         nchar(token) > 6,
                                       1, 0)]
  anno_nom[, Gerunds := ifelse(grepl('ing$', token) &
                                 syls > 1 &
                                 !lemma %in% lexes$lemma, 1, 0)]

  nouncounts <- anno_nom[, list(Nominalizations = sum(Nominalizations),
                                Gerunds = sum(Gerunds),
                                Nouns = .N),
                         by = list(doc_id)]

  nouncounts[, Nouns := Nouns - Nominalizations - Gerunds]

  ## aggregate
  wids <- nouncounts[tensecounts,  on = 'doc_id']
  wids <- wids[words,  on = 'doc_id']
  suppressWarnings({
    wids <- data.table::melt(wids,
                             id.vars = c(1),
                             measure.vars = c(2:ncol(wids)),
                             variable.name = 'feature',
                             value.name = 'feature_count')
  })

  full <- rbind(verbcounts, lexcounts, wids)

  ## last step
  full <- words[full,  on = 'doc_id']
  full[, per1K := round(feature_count/WordCount * 1000, 3)]
  full <- subset(full, select = -c(WordCount:TypeTokenRatio))
  full[, per1K := ifelse(feature %in% colnames(words),
                       feature_count,
                       per1K)]

  return(full)
}
