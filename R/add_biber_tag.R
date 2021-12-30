#' Re-code PoS tags, per Biber (1991)
#'
#' @name add_biber_tags
#' @param x Annotion dataframe
#' @return A data frame
#'
#' @export
#' @rdname add_biber_tags
#'
#'

add_biber_tags <- function(x){

  ## biber-features specific --
  data.table::setDT(x)
  x[, term := tolower(token)]
  x0 <- lxfeatures::biber_search_categories[x, on = c('term')]

  x0$tag[grepl("'ve$|'d$", x0$token)] <- 'HAVE'
  x0$tag[grepl("'s$", x0$token)] <- 'S'
  x0$tag[grepl("'ll$", x0$token)] <- 'MODAL'
  x0[, tag := ifelse(is.na(tag), xpos, tag)]
  x0[, term := NULL]

  return(x0)
}
