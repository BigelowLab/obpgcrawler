# Catalog.R
 
# http://www.unidata.ucar.edu/software/thredds/current/tds/catalog/InvCatalogSpec.html#catalogRef
# A catalogRef element refers to another THREDDS catalog that logically is a nested 
# dataset inside this parent catalog. This is used to separately maintain catalogs 
# and to break up large catalogs. THREDDS clients should not read the referenced 
# catalog until the user explicitly requests it, so that very large dataset collections
# can be represented with catalogRef elements without large delays in presenting 
# them to the user. The referenced catalog is not textually substituted into the 
# containing catalog, but remains a self-contained object. The referenced catalog 
# must be a valid THREDDS catalog, but it does not have to match versions with 
# the containing catalog. 

#' An catalogRef representation that subclasses from ThreddsNodeRefClass
#' 
#' @family Catalog
#' @include Thredds.R
#' @field name character
#' @field href character relative link
#' @field title character
#' @field type character
#' @field ID character
#' @export
CatalogRefClass <- setRefClass("CatalogRefClass",
   contains = 'ThreddsNodeRefClass',
   fields = list(
      name = 'character',
      href = 'character',
      title = 'character',
      type = 'character',
      ID = 'character'),
   methods = list(
      initialize = function(x, ...){
         callSuper(x, ...)
         if (is_xmlNode(x)){
            atts <- XML::xmlAttrs(.self$node)
            natts <- names(atts)
            nm <- c("name", "href", "title", "type", "ID")
            for (n in nm) {
               if (n %in% natts) .self[[n]] <- atts[[n]]
            }
         }
      },
   
   show = function(prefix = ""){
      callSuper(prefix = "")
      cat(prefix, "  name:", .self$name, "\n", sep = "")
      cat(prefix, "  href:", .self$href, "\n", sep = "")
      cat(prefix, "  title:", .self$title, "\n", sep = "")
      cat(prefix, "  type:", .self$type, "\n", sep = "")
      cat(prefix, "  ID:", .self$ID, "\n", sep = "")
      }  
   ) # methods
)



#' Retrieve the URL for a non-collection dataset
#'
#' @name DatasetRefClass_get_url
#' @return character
NULL
CatalogRefClass$methods(
   get_url = function(){
      return(sub("catalog.xml", .self$href, .self$url, fixed = TRUE))
   })
