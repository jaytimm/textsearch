#' Identify lexical patterns in text.
#'
#' @name find_lex
#' @param text a character vector
#' @param doc_id a character vector
#' @param query a character vector
#' @param window An integer
#' @param highlight a character vector
#' @return A data frame
#'
#' @export
#' @rdname find_lex
#'
find_lex <- function(query,
                     text,
                     doc_id,
                     window = 20L,
                     highlight = c('<', '>')) {

  term1 <- paste0('(?i)', query)
  term2 <- paste0(term1, collapse = '|')
  og <- data.table::data.table(doc_id = as.character(doc_id), t1 = text)

  found <- stringi::stri_locate_all(text, regex = term2)

  names(found) <- doc_id
  found1 <- lapply(found, data.frame)
  df <- data.table::rbindlist(found1, idcol='doc_id', use.names = F)
  df[, doc_id := as.character(doc_id)]
  df <- subset(df, !is.na(start))
  df <- og[df, on = 'doc_id']

  df[, start_w := start - (window*10)]
  df[, end_w := end + (window*10)]

  df[, lhs := stringi::stri_sub(t1, start_w, start-1L)]
  df[, rhs := stringi::stri_sub(t1, end+1L, end_w)]
  df[, pattern := stringi::stri_sub(t1, start, end)]
  #
  wd <- sprintf("^\\S+( \\S+){0,%d}", window)
  df[, rhs := stringi::stri_extract(trimws(rhs),
                                    regex = wd)]

  df[, lhs := stringi::stri_extract(stringi::stri_reverse(trimws(lhs)),
                                    regex = wd)]
  df[, lhs := stringi::stri_reverse(lhs)]
  df[is.na(df)] <- ''

  ## by group --
  df[, id := .I]

  # highlight procedure
  if(!is.null(highlight)) {

    if(length(highlight) == 2){
      p1 <- paste0(' ', highlight[1])
      p2 <- paste0(highlight[2], ' ')} else{
        p1 <- paste0(' <span style="background-color:', highlight, '">')
        p2 <- '</span> '
      }

    df[, context := trimws(paste0(lhs, p1, pattern, p2, rhs))]} else{

      df[, context := trimws(paste(lhs, pattern, rhs, sep = ' '))] }

  # # sentence_id
  # if(grepl('\\.', df$doc_id[1])) {
  #   df[, sentence_id := gsub('^.*\\.', '', doc_id)]
  #   df[, doc_id := gsub('\\..*$', '', doc_id)]
  #   df[, c('doc_id',
  #          'sentence_id',
  #          'pattern',
  #          'context')]
  # } else{
    df[, c('doc_id', 'id', 'pattern', 'context')]
    #}

}



# ps <- 'part[a-z]*\\b'
# mus <- 'political \\w+'
# term <- c('populism', 'political ideology', 'Many real-world')
#
# jj <- find_lex(query = mus,
#                text = corpus$text,
#                doc_id = corpus$doc_id,
#                window = 99)


