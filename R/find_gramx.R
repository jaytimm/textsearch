#' Extract gramx from tif
#'
#' @name find_gramx
#' @param tif a tif
#' @param search char string
#' @param mapping A list
#' @return A data frame
#'
#' @export
#' @rdname find_gramx
#'
find_gramx <- function(search,
                       mapping = textsearch::mapping_generic,
                       tif) {

  query <- translate_query(x = search, mapping = mapping)

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




####
translate_query <- function(x,
                            mapping){

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
      gsub('([A-Z_]+)', '\\\\S+/\\1 ', x)
    } else{

      paste0(x, '/\\S+ ')
    } })

  paste0(y0, collapse = '')
}
