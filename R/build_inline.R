#' Build inline tif for search gramx
#'
#' @name build_inline
#' @param doc_id vector
#' @param form vector
#' @param pos vector
#' @return A data frame
#'
#' @export
#' @rdname build_inline
#'
#'

build_inline <- function(doc_id, form, pos){

  x <- data.table::data.table(doc_id, form, pos)
  x[, inline := paste0(pos, '_', form, ' ')] #### ---
  x[, list(text = paste0(inline, collapse = "")),
    by = list(doc_id)]
}
