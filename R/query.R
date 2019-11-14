


#' A basic query function to retrieve one or more datasets
#'
#' @export
#' @param top character, uri of the top catalog
#' @param platform character, the name of the platform (MODISA, MODIST, OCTS, SeaWiFS, VIIRS, etc.)
#' @param product character, the product type (L3SMI, etc.)
#' @param year character or numeric, four digit year(s) - ignored if \code{when} is not 'all'
#' @param mmdd character or numeric, 4 digit month-day - ignored if \code{when} is not 'all'.
#'    You can improve efficiency by preselecting days for months, days, or
#'    seasons using \code{year} and \code{mmdd}
#' @param when character, optional filters
#'   \itemize{
#'       \item{all - return all occurences, the default, used with year and day, date_filter = NULL}
#'       \item{any - same as all}
#'       \item{most_recent - return only the most recent, date_filter = NULL}
#'       \item{within - return the occurrences bounded by date_filter first and secomd elements}
#'       \item{before - return the occurences prior to the first date_filter element}
#'       \item{after - return the occurrences after the first date_filter element}
#'    }
#' @param date_filter POSIXct or Date, one or two element vector populated according to
#'    the \code{when} parameter.  By default NULL.  It is an error to not match
#'    the value of date_filter
#' @param greplargs list or NULL, if a list the provide two elements,
#'    pattern=character and fixed=logical, which are arguments for \code{grepl}.
#'    If \code{fixed} is FALSE then be sure to provide a regex for the pattern value.
#' @param verbose logical, by default FALSE
#' @param userpassword character, a two element named vector with elements "user"
#'        and "password"
#' @return list of DatasetRefClass or NULL
#' @examples
#'    \dontrun{
#'       query <- obpg_query(
#'          top = 'http://oceandata.sci.gsfc.nasa.gov/opendap/catalog.xml',
#'          platform = 'MODISA',
#'          product = 'L3SMI',
#'          when = 'most_recent',
#'          greplargs = list(pattern='8D_CHL_chlor_a_4km', fixed = TRUE))
#'       query <- obpg_query(
#'          top = 'http://oceandata.sci.gsfc.nasa.gov/opendap/catalog.xml',
#'          platform = 'MODISA',
#'          product = 'L3SMI',
#'          when = 'within',
#'          date_filter = as.Date(c("2008-01-01", "2008-06-01"), format = "%Y-%m-%d"),
#'          greplargs = list(
#'             chl = list(pattern='8D_CHL_chlor_a_4km', fixed = TRUE),
#'             sst = list(pattern='8D_SST_sst_4km', fixed = TRUE)) )
#'    }
#' @seealso \code{\link{get_monthdays}}, \code{\link{get_8days}} and \code{\link{get_seasondays}}
obpg_query <- function(
   top = 'https://oceandata.sci.gsfc.nasa.gov/opendap/catalog.xml',
   platform = 'MODISA',
   product = 'L3SMI',
   year = format(Sys.Date(), "%Y"),
   mmdd = format(Sys.Date(), "%m%d"),
   when = c("all", "any", "most_recent", "within", "before", "after")[1],
   date_filter = NULL,
   greplargs = NULL,
   verbose = FALSE,
   userpassword = c(user = 'user', password = 'password')) {

  # Used to scan all/any days for the listed year
  # Product CatalogRefClass
  # year one or more character in YYYY format
  # mmdd one or more charcater in format mmdd
  # greplargs list of one or more grepl args
  get_all_obpg <- function(Product, year, mmdd, greplargs = NULL, verbose = FALSE) {
    if (!is.character(year)) year <- sprintf("%0.4i", year)
    R <- NULL
    YY <- Product$get_catalog()$get_catalogs(year)
    for (iy in seq_along(YY)){
      DD <- YY[[iy]]$get_catalog()$get_catalogs(mmdd)
      for (D in DD){
        dd <- D$get_catalog()$get_datasets()
        if (!is.null(greplargs)){
            ix <- thredds::grepl_it(names(dd), greplargs)
            dd <- dd[ix]
        }
        R[names(dd)] <- dd
      } #DD loop
    } # YY loop
    return(R)
  }


   Top <- thredds::get_catalog(top[1], verbose = verbose, ns = "thredds")
   if (is.null(Top)) {
      cat("error getting catalog for", top[1], "\n")
      return(NULL)
   }

   Platform <- Top$get_catalogs()[[platform[1]]]$get_catalog()
   if (is.null(Platform)) {
      cat("error getting catalog for", platform[1], "\n")
      return(NULL)
   }

   Product <- Platform$get_catalogs(product[1])[[1]]
   if (is.null(Product)) {
      cat("error getting catalog for", product[1], "\n")
      return(NULL)
   }

   if (is.numeric(year)) year <- sprintf("%0.4i",year)
   if (is.numeric(mmdd)) mmdd <- sprintf("%0.4i", mmdd)
   if (inherits(mmdd, 'Date') || inherits(mmdd, 'POSIXct')) mmdd <- format(mmdd, '%m%d')

   when <- tolower(when[1])
   R <- list()

   if (when == "most_recent"){
      while(length(R) == 0){
         YY <- Product$get_catalog()$get_catalogs()
         YY <- YY[sort(names(YY), decreasing = TRUE)]
         for (Y in YY){
            Year <- Y$GET()
            MMDD <- Year$get_catalogs()
            MMDD <- MMDD[sort(names(MMDD), decreasing = TRUE)]
            for (md in MMDD){
               D <- md$GET()
               datasets <- D$get_datasets()
               ix <- thredds::grepl_it(names(datasets), greplargs)
               if (any(ix)){
                  R <- datasets[ix]
                  break
               }
               if (length(R) != 0){ break }
            } #days
            if (length(R) != 0){ break }
         } #years
      }

   } else if (when %in% c('within', "before", "after")){

      if (is.null(date_filter)){
         cat("if when is 'within', 'before' or 'after' then date_filter must be provided\n")
         return(NULL)
      }
      if ((when == 'within') && (length(date_filter) < 2) ) {
         cat("if when is 'within' then date_filter have [begin,end] elements\n")
         return(NULL)
      }
      if (!inherits(date_filter, "POSIXt") && !inherits(date_filter, "Date")){
         cat("if when is 'within', 'before' or 'after' then date_filter must be POSIXt or Date class\n")
         return(NULL)
      }

      # compute the beginning and end
      tbounds <-   switch(tolower(when),
            'within' = date_filter[1:2],
            'after' = c(date_filter[1], as.POSIXct(Sys.time())), # from then to present
            'before' = c( as.POSIXct("1990-01-01 00:00:00"), date_filter[1]) ) # from 1990 to then
      # convert to daily steps
      tsteps <- seq(tbounds[1], tbounds[2], by = 'day')
      year <- format(tsteps, "%Y")
      mmdd <- format(tsteps,"%m%d")

      yd <- split(mmdd, year)
      # note how this differs from when = 'all', here we explicitly iterate through
      # the years (days may be different for each year
      for (i in seq_along(yd)){
         y <- names(yd)[i]
         R[[y]] <- get_all_obpg(Product, y, yd[[i]], greplargs = greplargs, verbose = verbose)
      }

      if (length(R) > 0){
          R <- unlist(R, use.names = FALSE)
          names(R) <- sapply(R, function(x) x$name)
      }
   } else {
      # any or all
      # retrieve the days from the years specified
      R <- get_all_obpg(Product, year, mmdd, greplargs = greplargs)

   }

   # if none found then we return NULL (not an empty list)
   if (length(R) == 0) R <- NULL
   if (verbose){
      cat(sprintf("obpg_query: retrieved %i records\n", length(R)))
   }
   invisible(R)
}
