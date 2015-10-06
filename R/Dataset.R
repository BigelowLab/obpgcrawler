
# A dataset element represents a named, logical set of data at a level of
# granularity appropriate for presentation to a user. A dataset is direct if it
# contains at least one dataset access method, otherwise it is just a container
# for nested datasets, called a collection dataset. The name of the dataset
# element should be a human readable name that will be displayed to users.
# Multiple access methods specify different services for accessing the same
# dataset.

       

#' A direct Dataset representation that subclasses from ThreddsNodeRefClass
#' 
#' @family Thredds
#' @include Datasets.R Thredds.R
#' @field dataSize numeric size in bytes
#' @field date character
#' @field urlPath character relative URL, use url or get_url() instead
#' @export
DatasetRefClass <- setRefClass("DatasetRefClass",
   contains = 'DatasetsRefClass',
   
   fields = list(
      dataSize = 'numeric',
      date = 'character',
      serviceName = 'character',
      urlPath = 'character'
      ),
      
   methods = list(
      initialize = function(x, ...){
         callSuper(x, ...)
         if (!is_xmlNode(.self$node)){
            .self$dataSize <- as.numeric(NA)
            .self$date <- as.character(NA)
            .self$serviceName <- as.character(NA)
            .self$urlPath <- as.character(NA)
         } else {
            nm <- names(XML::xmlChildren(.self$node))
            if ('dataSize' %in% nm)
               .self$dataSize <- as.numeric(XML::xmlValue(.self$node[['dataSize']]))
            
            if ('date' %in% nm) 
               .self$date <- XML::xmlValue(.self$node[['date']])
                  
            if ('access' %in% nm){
               atts <- XML::xmlAttrs(.self$node[['access']])
               natts <- names(atts)
               nm <- c("serviceName", "urlPath")
               for (n in nm) {
                  if (n %in% natts) .self[[n]] <- atts[[n]]
               }
            } # access?
         } # is_xmlNode?
      },
      
      show = function(prefix = ""){
         "show the contents"
         callSuper(prefix = prefix)
         if (is_xmlNode(.self$node)){ 
            cat(prefix, "  dataSize:", .self$dataSize, "\n", sep = "")
            cat(prefix, "  date:", .self$date, "\n", sep = "")
            cat(prefix, "  serviceName:", .self$serviceName, "\n", sep = "")
            cat(prefix, "  urlPath:", .self$urlPath, "\n", sep = "")
         }
      }
   )
)

       
#' Overrides the GET method of the superclass.  GET is not permitted
#'
#' @name DatasetRefClass_GET
#' @return NULL
NULL
DatasetRefClass$methods(
   GET = function(){
      cat("DatasetRefClass$GET is not permitted. Try ncdf4::nc_open(ref$url)\n")
   })