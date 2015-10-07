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
      node = "ANY",
      handle = "ANY",
      verbose_mode = "logical",
      tries = 'numeric'),
   methods = list(
      
      initialize = function(x, verbose = FALSE, n_tries = 3){
         "x may be url or XML::xmlNode"
         if (!missing(x)){
            if (is_xmlNode(x)) {
               .self$node <- x
               .self$url <- 'none'
               .self$verbose_mode <- verbose
               .self$tries <- n_tries
            } else if (is.character(x)) {
               .self$handle <- httr::handle(x)
               r <- httr::GET(x)
               if (reponse(r) == 200){
                  .self$node <- XML::xmlRoot(content(x))
                  .self$url <- x
                  .self$verbose_mode <- verbose
                  .self$tries <- n_tries
               }
               
            }
         }
      },
      
      show = function(prefix = ""){
         "show the content of the class"
         cat(prefix, "Reference Class: ", methods::classLabel(class(.self)), "\n", sep = "")
         cat(prefix, "  verbose_mode: ", .self$verbose_mode, "\n", sep = "")
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
      if (.self$verbose_mode) cat("GET", .self$url, "\n")
      i <- 1
      r <- NULL
      while(i <= .self$tries){
         #r <- try(httr::GET(.self$url, handle = httr::handle(.self$url)))
         r <- try(httr::GET(.self$url))
         if (inherits(r, "try-error")){
            if (.self$verbose_mode) {
               cat(sprintf("*** GET failed after attempt %i\n", i))   
               if (i < .self$tries) {
                  cat("  will try again\n")
               } else { 
                  cat("  exhausted permitted tries, returning NULL\n")
               }
            } 
            r <- NULL
            i <- i + 1
         } else {
            if (i > 1) cat(sprintf("  whew!  attempt %i successful\n", i))
            r <- parse_node(r, verbose = .self$verbose_mode)
            break
         }
      }
      return(r)
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