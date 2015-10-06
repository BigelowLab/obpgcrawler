# http://www.unidata.ucar.edu/software/thredds/current/tds/catalog/InvCatalogSpec.html#service
# A service element represents a data access service and allows basic data 
# access information to be factored out of dataset and access elements.


#' An Service representation that subclasses from ThreddsNodeRefClass
#' 
#' @family Thredds
#' @include Thredds.R
#' @field name character
#' @field serviceType character
#' @field base character base url
#' @export
ServiceRefClass <- setRefClass("ServiceRefClass",
   contains = 'ThreddsNodeRefClass',
   fields = list(
      name = 'character',
      serviceType = 'character',
      base = 'character'),
   methods = list(
      initialize = function(x, ...){
         callSuper(x, ...)
         if (is_xmlNode(.self$node)){
            atts <- XML::xmlAttrs(x)
            natts <- names(atts)
            if ("name" %in% natts) .self$name <- atts[['name']]
            if ('serviceType' %in% natts) .self$serviceType <- atts[['serviceType']]
            if ('base' %in% natts) .self$base <- atts[['base']]
         }
      },
      show = function(prefix = ""){
         callSuper(prefix = "")
         cat(prefix, "  name: ", .self$name, "\n", sep = "")
         cat(prefix, "  serviceType: ", .self$serviceType, "\n")
         cat(prefix, "  base: ", .self$base, "\n", sep = "")
      })
   )
