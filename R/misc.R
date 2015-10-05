#' Test if an object inherits from XML::XMLAbstractNode
#'
#' @export
#' @param x object to test
#' @param classname character, the class name to test against, by default 'XMLAbstractNode'
#' @return logical
is_xmlNode <- function(x, classname = 'XMLAbstractNode'){
   inherits(x, classname)
}

#' Convert XML::xmlNode to character
#' 
#' @export
#' @param x xmlNode
#' @return character
xmlString <- function(x){
   gsub("\n","", XML::toString.XMLNode(x))
}


#' Retrieve a catalog
#'
#' @export
#' @param uri the URI of the catalog
#' @return ThreddsNodeRefClass or sublass or NULL
get_catalog <- function(uri){
   
   x <- httr::GET(uri)
   if (httr::status_code(x) == 200){
      node <- parse_node(x)
   } else {
      node <- NULL
   }
   return(node)
}

#' Convert a node to an object inheriting from ThreddsNodeRefClass 
#'
#' @export
#' @param node XML::xmlNode or an httr::response object
#' @param url character, optional url if a catalog or direct dataset
#' @return ThreddsNodeRefClass object or subclass
parse_node <- function(node, url = NULL){

   # given an 'dataset' XML::xmlNode determine if the node is a collection or
   # direct (to data) and return the appropriate data type
   parse_dataset <- function(x){
      if ('access' %in% names(XML::xmlChildren(x))){
         r <- DatasetRefClass$new(x)
      } else {
         r <- DatasetsRefClass$new(x)
      }
      return(r)
   }
   
   if (inherits(node, 'response')){
      if (httr::status_code(node) == 200){
         if (is.null(url)) url <- node$url
         node <- XML::xmlRoot(httr::content(node))
      } else {
         cat("response status != 200\n")
         print(node)
         return(NULL)
      }
   }

   if (!is_xmlNode(node)) stop("assign_node: node must be XML::xmlNode")
   
   nm <- XML::xmlName(node)[1]
   n <- switch(nm,
       'catalog' = TopCatalogRefClass$new(node),
       'catalogRef' = CatalogRefClass$new(node),
       'service' = ServiceRefClassr$new(node),
       'dataset' = parse_dataset(node),
       ThreddsRefClass$new(node))

   if (!is.null(url)) n$url <- url

   return(n)
}


#' A basic query function to retrieve one or more datasets
#'
#' @export
#' @param top character, uri of the top catalog
#' @param platform character, the name of the platform (MODISA, MODIST, OCTS, SeaWiFS, VIIRS, etc.)
#' @param product character, the product type (L3SMI, etc.)
#' @param year character or numeric, four digit year(s) - ignored if what is not 'all'
#' @param day character or numeric, three digit year of day(s) - ignored if what is not 'all'
#' @param what character, optional filters
#'   \itemize{
#'       \item{all - return all occurences, the default, used with year and day, date_filter = NULL}
#'       \item{most_recent - return only the most recent, date_filter = NULL}
#'       \item{within - return the occurrences bounded by date_filter first and secomd elements}
#'       \item{before - return the occurences prior to the first date_filter element}
#'       \item{after - return the occurrences after the first date_filter element}
#'    }
#' @param date_filter POSIXct one or two element vector populated according to
#'    the \code{what} parameter.  By default NULL.  It is an error to not match 
#'    the value of date_filter  
#' @param greplargs list or NULL, if a list the provide two elements,
#'    pattern=character and fixed=logical, which are arguments for \code{grepl} If fixed is FALSE
#'    then be sure to provide a regex for the pattern value.
#' @param verbose logical, for debugging
#' @return list of DatasetRefClass or NULL
#' @examples
#'    \dontrun{
#'       query <- obpg_query(
#'          top = 'http://oceandata.sci.gsfc.nasa.gov/opendap/catalog.xml',
#'          platform = 'MODISA', 
#'          product = 'L3SMI',
#'          what = 'most_recent',
#'          greplargs = list(pattern='8D_CHL_chlor_a_4km', fixed = TRUE))
#'       query <- obpg_query( 
#'          top = 'http://oceandata.sci.gsfc.nasa.gov/opendap/catalog.xml',
#'          platform = 'MODISA', 
#'          product = 'L3SMI',
#'          what = 'within',
#'          date_filter = as.POSIXct(c("2008-01-01", "2008-06-01"), format = "%Y-%m-%d"),
#'          greplargs = list(pattern='8D_CHL_chlor_a_4km', fixed = TRUE))
#'    }
obpg_query <- function(
   top = 'http://oceandata.sci.gsfc.nasa.gov/opendap/catalog.xml',
   platform = 'MODISA', 
   product = 'L3SMI',
   year = format(as.POSIXct(Sys.Date()), "%Y"),
   day = format(as.POSIXct(Sys.Date()), "%j"),
   what = c("all", "most_recent", "within", "before", "after")[1],
   date_filter = NULL,
   greplargs = NULL, 
   verbose = FALSE) {
   
   Top <- get_catalog(top[1])
   if (is.null(Top)) {
      cat("error getting catalog for", top[1], "\n")
      return(NULL)
   }
   
   Platform <- Top$get_catalogs()[[platform[1]]]$GET()
   if (is.null(Platform)) {
      cat("error getting catalog for", platform[1], "\n")
      return(NULL)
   }
   
   Product <- Platform$get_catalogs()[[product[1]]]$GET()
   if (is.null(Product)) {
      cat("error getting catalog for", platform[1], "\n")
      return(NULL)
   }
   
   if (is.numeric(year)) year <- sprintf("%0.4i",year)
   if (is.numeric(day)) day <- sprintf("%0.3i", day)
   
   what <- tolower(what[1])
   R <- list()
   if (what == "most_recent"){
      while(length(R) == 0){
         Years <- Product$get_catalogs()
         for (y in rev(names(Years))){
            Y <- Years[[y]]$GET()
            Days <- Y$get_catalogs()
            for (d in rev(names(Days))){
               D <- Days[[d]]$GET()
               datasets <- D$get_datasets()
               if (is.null(greplargs)){
                  R <- datasets
                  break
               } else {
                  ix <- grepl(greplargs[['pattern']], names(datasets), fixed = greplargs[['fixed']])
                  if (any(ix)){
                     R <- datasets[ix]
                     break
                  }
               }  # greplargs?
               if (length(R) != 0){ break }
            } #days 
            if (length(R) != 0){ break }
         } #years
      }
   
   } else if (what %in% c('within', "before", "after")){
   
      if (is.null(date_filter)){
         cat("if what is 'within', 'before' or 'after' then date_filter must be provided\n")
         return(NULL)
      }
      if ((what == 'within') && (length(date_filter) < 2) ) {
         cat("if what is 'within' then date_filter have [begin,end] elements\n")
         return(NULL)
      }   
      if (!inherits(date_filter, "POSIXct")){
         cat("if what is 'within', 'before' or 'after' then date_filter must be POSIXct class\n")
         return(NULL)
      }          
      
      # compute the beginning and end
      tbounds <-   switch(tolower(what),
            'within' = date_filter[1:2],
            'after' = c(date_filter[1], as.POSIXct(Sys.time())), # from then to present
            'before' = c( as.POSIXct("1990-01-01 00:00:00"), date_filter[1]) ) # from 1990 to then
      # convert to daily steps
      tsteps <- seq(tbounds[1], tbounds[2], by = 'day')
      year <- format(tsteps, "%Y")
      day <- format(tsteps,"%j")
      
      yd <- split(day, year)
      
      for (i in seq_along(yd)){
         y = names(yd)[i]
         R[[y]] <- obpg_query(top = top, platform = platform, product = product,
            year = y, day = yd[[y]], 
            what = 'all', greplargs = greplargs)
      }

      R <- unlist(R)
   
   } else {
      #all for a given YEAR/DAY
      Years <- Product$get_catalogs()
      Y <- Years[year]
      if (!is.null(Y)){
         for (y in Y){
            Days <- y$GET()$get_catalogs()
            D <- Days[day]
            if (!is.null(D)){
               for (d in D){
                  d <- d$GET()
                  if (!is.null(d)){
                     datasets <- d$get_datasets()
                     if (!is.null(greplargs)){
                        ix <- grepl(greplargs[['pattern']], names(datasets), fixed = greplargs[['fixed']])
                        if (any(ix)) R[names(datasets[ix])] <- datasets[ix]
                     } else {
                        R[names(datasets)] <- datasets
                     }  # greplargs?
                  } # d is !null
               } # day loop
            } # day is found
        } # year loop 
      } #year is found
   }
   
   # if none found then we return NULL (not an empty list)
   if (length(R) == 0) R <- NULL
   invisible(R)   
}


