#' Recode gramx in df
#'
#' @name recode_gramx
#' @param df An annotated corpus df
#' @param gramx A DF
#' @param recode_col A string
#' @param recode_cat A string
#' @return A data frame
#'
#' @export
#' @rdname recode_gramx
#'

recode_gramx <- function(gramx,
                         df,
                         form = 'token',
                         tag = 'xpos',
                         recode_col = 'xpos',
                         recode_cat = 'cx1'){

  ## build new char onset/offset per inline --
  ## in order to align with gramx onset/offests --
  data.table::setDT(df)
  df[, inline := paste0(get(tag), '~', get(form), ' ')]
  df[, end := cumsum(nchar(inline)), by = list(doc_id)]
  df[, start := c(1, end[1:(length(end)-1)] + 1),
    by = list(doc_id)]

  ### modify gramx object -- ready for join to full df --
  f0 <- gramx
  f0[, id := seq_len(.N), by = doc_id]
  f0 <- df[, c('doc_id', 'start', 'term_id')][f0, on = c('doc_id', 'start')]
  f1 <- f0[, .(token = unlist(data.table::tstrsplit(construction, " "))),
           by = list(doc_id, term_id, id, construction)]
  f1[, term_id2 := term_id]
  f1[, term_id := term_id + seq_len(.N) - 1, by = list(doc_id, term_id)]
  f1[, c('token', 'id') := NULL]

  ### add df --
  f10 <- f1[df, on = c('doc_id', 'term_id')]
  f10[, term_id2 := ifelse(is.na(term_id2), term_id, term_id2)]
  f100 <- f10[f10[, .I[1], list (doc_id, term_id2)]$V1]

  ## Re-assign token and lemma columns -
  f100[, (recode_col) := ifelse(!is.na(construction), recode_cat, get(recode_col))]

  ## Re-number
  f100[, term_id := seq_len(.N), by = doc_id]
  f100[, token_id := seq_len(.N), by = list(doc_id, sentence_id)]


  ## Assign value --
  # x3[, pattern := trimws(gsub('[A-Z]+_', '', construction))]
  f100[, token := ifelse(!is.na(construction),
                         gsub(' ', '_',
                              trimws(gsub('/[A-Z_]+', '', construction))
                              ),
                         token)]
  f100[, lemma := ifelse(!is.na(construction), token, lemma)]
  f100[, feats := ifelse(!is.na(construction), NA, feats)]


  ## Re-do start/stop based on new concatenated forms --
  f100[, end := cumsum(nchar(inline)), by = list(doc_id)]
  f100[, start := c(1, end[1:(length(end)-1)] + 1),
       by = list(doc_id)]

  ## Remove derived columns --
  f100[, c("doc_id",
           "sentence_id",
           "start",
           "end",
           "term_id",
           "token_id",
           "token",
           "lemma",
           "upos",
           "xpos",
           "feats")]
}
