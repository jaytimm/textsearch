#' Add context to search results
#'
#' @name add_context
#' @param x output from find_gramx()
#' @param annotation Annotion dataframe
#' @return A data frame
#'
#' @export
#' @rdname add_context
#'

add_context <- function(x, ## output from find_gramx()
                        annotation,
                        highlight = NULL) {

  data.table::setDT(annotation)
  y <- subset(annotation, doc_id %in% unique(x$doc_id))

  #### assume column here -- needs parameter --
  y[, inline := paste0(tag, '_', token, ' ')]

  y[, end := cumsum(nchar(inline)), by = list(doc_id)]
  y[, beg := c(1, end[1:(length(end)-1)] + 1),
    by = list(doc_id)]

  ## x2 <- x[y, on = c('doc_id', 'beg')]

  x1 <- y[x, on = c('doc_id', 'beg')]

  x2 <- x1[, c('construction',
               'doc_id',
               'sentence_id',
               'beg')][y, on = c('doc_id', 'sentence_id'),
                       nomatch = 0]

  x3 <- x2[, list(text = paste(token, collapse = " ")),
           by = list(doc_id, sentence_id, construction, beg)]


  ### highlight piece --
  if(!is.null(highlight)) {

    if(highlight == '|'){p1 <- '|'; p2 <- '|'} else{

      p1 <- paste0('<span style="background-color:', highlight, '">')
      p2 <- '</span> '}

    x3[, pattern := trimws(gsub('[A-Z]+_', '', construction))]
    x3[, text := gsub(pattern, paste0(p1, pattern, p2), text),
       by = list(doc_id, sentence_id, beg)]
    x3[, pattern := NULL]
    }


  x3[, beg := NULL]
  return(x3)
}
