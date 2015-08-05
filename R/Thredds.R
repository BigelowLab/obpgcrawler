# thredds

#' An base representation that  other nodes subclass from
#' 
#' @family Thredds
#' @field url character - possibly wrong but usually right!
#' @field node XML::xmlNode
#' @export
ThreddsNodeRefClass <- setRefClass("ThreddsNodeRefClass",
   fields = list(
      url = 'character',
      node = "ANY"),
   methods = list(
      
      initialize = function(x){
         "x may be url or XML::xmlNode"
         if (!missing(x)){
            if (is_xmlNode(x)) {
               .self$node <- x
               .self$url <- 'none'
            } else if (is.character(x)) {
               r <- httr::GET(x)
               if (reponse(r) == 200){
                  .self$node <- xmlRoot(content(x))
                  .self$url <- x
               }
               
            }
         }
      },
      
      show = function(prefix = ""){
         "show the content of the class"
         cat(prefix, "Reference Class: ", methods::classLabel(class(.self)), "\n", sep = "")
         cat(prefix, "  url: ", .self$url, "\n", sep = "")
         if (is_xmlNode(.self$node)) {
            cat(prefix, "  children: ", paste(.self$unames(), collapse = " "), "\n", sep = "")
         }
      })
      
   ) 

#' Retrieve the url of this node (mostly gets an override by subclasses?)
#'
#' @family Thredds
#' @name ThreddsNodeRefClass_get_url
#' @return character url (possibly invalid)
NULL
ThreddsNodeRefClass$methods( 
   get_url = function(){
      .self$url
   })
   
   
#' Retrieve a node of the contents at this nodes URL
#'
#' @family Thredds
#' @name ThreddsNodeRefClass_GET
#' @return ThreddsNodeRefClass or subclass or NULL
NULL
ThreddsNodeRefClass$methods( 
   GET = function(){
      r <- try(httr::GET(.self$url))
      if (inherits(r, "try-error")){
         return(NULL)
      } else {
         return(parse_node(r))
      }
   })
   
#' Retrieve a vector of unique child names
#'
#' @family Thredds
#' @name ThreddsNodeRefClass_unames
#' @return a vector of unique children names
NULL
ThreddsNodeRefClass$methods( 
   unames = function(){ 
      x <- if (is_xmlNode(.self$node)) unique(names(.self$node)) else ""
      return(x)
   })