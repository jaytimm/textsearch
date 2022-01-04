#' Build inline tif for search gramx
#'
#' @name build_inline
#' @param df A data frame
#' @param form vector
#' @param tag vector
#' @return A data frame
#'
#' @export
#' @rdname build_inline
#'
#'

build_inline <- function(df, form, tag){

  x <- data.table::data.table(df)
  x[, inline := paste0(get(tag), '~', get(form), ' ')] #### ---
  x[, list(text = paste0(inline, collapse = "")),
    by = list(doc_id)]
}
