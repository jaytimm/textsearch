#' Extract gramx from tif
#'
#' @name find_gramx
#' @param x a tif
#' @param search char string
#' @param mapping a list
#' @return A data frame
#'
###
build_search <- function(x, mapping = mapping){

  ## build mappings --
  mapdf <- stack(mapping)
  mapdf <- aggregate(mapdf$values, list(map = mapdf$ind), paste0, collapse="|")
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
      gsub('([A-Z]+)', '\\1_\\\\S+ ', x)
    } else{

      paste0('\\S+_', x, ' ')
    } })

  paste0(y0, collapse = '')
}



#' @export
#' @rdname find_gramx
#'
find_gramx <- function(x, ## a tif with inline tags --
                       search,
                       mapping = mapping) {

  q1 <- build_search(search, mapping = mapping)

  found <- lapply(1:nrow(x), function(z) {

    txt <- x$text[z]
    locations <- gregexpr(pattern = q1,
                          text = txt, #,
                          ignore.case = TRUE)

    beg <- unlist(as.vector(locations[[1]]))
    end <- beg + attr(locations[[1]], "match.length") - 1

    if (-1 %in% locations){} else {
      data.frame(construction = unlist(regmatches(txt, locations)),
                 beg = beg,
                 end = end) }
  })

  names(found) <- x$doc_id
  found <- Filter(length, found)
  data.table::rbindlist(found, idcol='doc_id', use.names = F)
}
