#' Recode gramx in df
#'
#' @name recode_gramx
#' @param df An annotated corpus df
#' @param col A string
#' @param new_cat A string
#' @param renumber A boolean
#' @return A data frame
#'
#' @export
#' @rdname recode_gramx
#'

recode_gramx <- function(df, 
                         gramx,
                         # search, ## will need to add translator in below code -- 
                         # mapping,
                         col = 'xpos', 
                         new_cat = 'jrb', 
                         renumber = T){
  
  ### a found object and DF -- as parameters -- 
  
  ### modify search output -- 
  f0 <- data.table::rbindlist(gramx, idcol='doc_id', use.names = F)
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
  
  ## LASTLY -- need to re-assign token and lemma columns to construction --
  f100[, (col) := ifelse(!is.na(construction), new_cat, get(col))]
  
  ## IF re-number
  f100[, term_id := seq_len(.N), by = doc_id]
  f100[, token_id := seq_len(.N), by = list(doc_id, sentence_id)]
  
  ## Assign value -- 
  f100[, token := ifelse(!is.na(construction), construction, token)]
  f100[, lemma := ifelse(!is.na(construction), construction, lemma)]
  
  ## return -- what -- ??
  return(f100)
}