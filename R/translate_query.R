#' Build regex query
#'
#' @name translate_query
#' @param x a string
#' @param mapping a list
#' @return A string
#'
#' @export
#' @rdname translate_query
#'
translate_query <- function(x, mapping = mapping){

  ## build mappings --
  mapdf <- stack(mapping)

  mapdf <- aggregate(mapdf$values,
                     list(map = mapdf$ind),
                     paste0,
                     collapse="|")

  colnames(mapdf)[2] <- 'tag'
  mapdf$map <- paste0('\\b', mapdf$map, '\\b')

  y <- x ## replace tags with maps --
  for (i in 1:nrow(mapdf)){
    y <- gsub(mapdf$map[i], mapdf$tag[i], y) }

  #####
  q <- unlist(strsplit(y, " "))

  ## maybe str_locate_all would be cleaner here --

  y0 <- lapply(q, function(x) { ## Add in-line tag info --

    if(grepl('\\|', x) & !grepl('^\\(', x)) {
      x <- paste0('(', x, ')')}

    if(x == toupper(x)){
      gsub('([A-Z_]+)', '\\1~\\\\S+ ', x)
    } else{

      paste0('\\S+~', x, ' ')
    } })

  paste0(y0, collapse = '')
}

