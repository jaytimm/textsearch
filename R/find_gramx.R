#' Extract gramx from tif
#'
#' @name find_gramx
#' @param tif a tif
#' @param search char string
#' @return A data frame
#'
#' @export
#' @rdname find_gramx
#'
find_gramx <- function(tif,
                       query) {

  # q1 <- build_search(search, mapping = mapping)

  # data.table::setDT(df)
  # inline <- df[, list(text = paste0(token, collapse = " ")),
  #              by = list(doc_id)]

  found <- lapply(1:nrow(tif), function(z) {

    txt <- tif$text[z]
    locations <- gregexpr(pattern = query,
                          text = txt, #,
                          ignore.case = TRUE)

    start <- unlist(as.vector(locations[[1]]))
    end <- start + attr(locations[[1]], "match.length") - 1

    if (-1 %in% locations){} else {
      data.frame(construction = unlist(regmatches(txt, locations)),
                 start = start,
                 end = end) }
  })

  names(found) <- tif$doc_id
  found <- Filter(length, found)
  data.table::rbindlist(found, idcol='doc_id', use.names = F)
}
