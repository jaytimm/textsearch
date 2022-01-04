#' Add context to search results
#'
#' @name add_context
#' @param gramx output from find_gramx()
#' @param df Annotion dataframe
#' @param highlight A boolean
#' @return A data frame
#'
#' @export
#' @rdname add_context
#'

add_context <- function(gramx,
                        df,
                        form = 'token',
                        tag = 'xpos',
                        highlight = NULL) {

  data.table::setDT(df)
  y <- subset(df, doc_id %in% unique(gramx$doc_id))

  #### assume column here -- needs parameter --
  ## y[, inline := paste0(tag, '_', token, ' ')]
  y[, inline := paste0(get(tag), '~', get(form), ' ')]

  y[, end := cumsum(nchar(inline)), by = list(doc_id)]
  y[, start := c(1, end[1:(length(end)-1)] + 1),
    by = list(doc_id)]

  ## x2 <- x[y, on = c('doc_id', 'beg')]

  x1 <- y[gramx, on = c('doc_id', 'start')]

  x2 <- x1[, c('construction',
               'doc_id',
               'sentence_id',
               'start')][y, on = c('doc_id', 'sentence_id'),
                       nomatch = 0]

  x3 <- x2[, list(text = paste(token, collapse = " ")),
           by = list(doc_id, sentence_id, construction, start)]


  ### highlight piece --
  if(!is.null(highlight)) {

    if(nchar(highlight) < 3){p1 <- highlight; p2 <- highlight} else{

      p1 <- paste0('<span style="background-color:', highlight, '">')
      p2 <- '</span> '}

    x3[, pattern := trimws(gsub('[A-Z_]+~', '', construction))]
    x3[, text := gsub(pattern, paste0(p1, pattern, p2), text),
       by = list(doc_id, sentence_id, start)]
    x3[, pattern := NULL]
    }


  x3[, start := NULL]
  return(x3)
}
