
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
#' @param ... further arguments for parse_node
#' @return ThreddsNodeRefClass or subclass or NULL
get_catalog <- function(uri, ...){
   
   x <- httr::GET(uri)
   if (httr::status_code(x) == 200){
      node <- parse_node(x, ...)
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
#' @param verbose logical, by default FALSE
#' @return ThreddsNodeRefClass object or subclass
parse_node <- function(node, url = NULL, verbose = FALSE){

   # given an 'dataset' XML::xmlNode determine if the node is a collection or
   # direct (to data) and return the appropriate data type
   parse_dataset <- function(x, verbose = FALSE){
      if ('access' %in% names(XML::xmlChildren(x))){
         r <- DatasetRefClass$new(x, verbose = verbose)
      } else {
         r <- DatasetsRefClass$new(x, verbose = verbose)
      }
      return(r)
   }
   
   if (inherits(node, 'response')){
      if (httr::status_code(node) == 200){
         if (is.null(url)) url <- node$url
         node <- XML::xmlRoot(httr::content(node))
      } else {
         cat("response status ==",httr::status_code(node), "\n")
         cat("response url = ", node$url, "\n")
         print(httr::content(node))
         return(NULL)
      }
   }

   if (!is_xmlNode(node)) stop("assign_node: node must be XML::xmlNode")
   
   nm <- XML::xmlName(node)[1]
   n <- switch(nm,
       'catalog' = TopCatalogRefClass$new(node, verbose = verbose),
       'catalogRef' = CatalogRefClass$new(node, verbose = verbose),
       'service' = ServiceRefClassr$new(node, verbose = verbose),
       'dataset' = parse_dataset(node, verbose = verbose),
       ThreddsRefClass$new(node, verbose = verbose))

   if (!is.null(url)) n$url <- url

   return(n)
}

