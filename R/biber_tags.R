#' Re-code PoS tags, per Biber (1991)
#'
#' @name biber_tags
#' @param x Annotion dataframe
#' @return A data frame
#'
#' @export
#' @rdname biber_tags
#'
#'

biber_tags <- function(token, tag){ ## x = token column

  ## biber-features specific --
  x <- data.table::data.table(token = token, tag2 = tag)
  x[, term := tolower(token)]
  x0 <- lxfeatures::biber_search_categories[x, on = c('term')]

  x0$tag[grepl("'ve$|'d$", x0$token)] <- 'HAVE'
  x0$tag[grepl("'s$", x0$token)] <- 'S'
  x0$tag[grepl("'ll$", x0$token)] <- 'MODAL'

  ## breaks here -- no access to xpos here --
  x0[, tag := ifelse(is.na(tag), tag2, tag)]
  # x0[, term := NULL]

  x0[, 1]
}
