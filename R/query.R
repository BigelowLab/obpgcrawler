#' Convert jjj day numbers to mmdd or the reverse
#'
#' @export
#' @param x days of year (1-366), month-days (0101-1231) or dates
#' \itemize{
#' \item{day of year, generally a three-digit character, but we try to cast it
#'       if numeric are passed.  It's best to not pass numerics.}
#' \item{month-day, generally a four-digit character, but we try to cast it
#'       if numeric are passed.  It's best to not pass numerics here either.}
#' \item{Date or POSIXt, if one of these then \code{form} and \code{year} are ignored.}
#' }
#' @param year one or more years to associate with each day of year or month-day.
#'     If shorter than \code{x} then \code{year} is recycled.  Ignored if
#'     \code{x} is a date time class.
#' @param form character either 'mmdd', 'jjj'  Ignored if \code{x} is of class
#'    Date or POSIXt
#' @return tibble with these variables
#' \itemize{
#'   \item{date Date class objects}
#'   \item{year character four digit year}
#'   \item{jjj character three digit day of year}
#'   \item{mmdd character 4 digit month and day}
#' }
obpg_date <- function(x = Sys.Date()-1,
                      year = format(Sys.Date(), "%Y"),
                      form = c("mmdd", "jjj")[1]){


  if (inherits(x, 'Date') || inherits(x, 'POSIXt')){
    date <- x
    mmdd <- format(date, "%m%d")
    jjj <- format(date, "%j")
  } else {
    if (!inherits(year, 'character')) year <- sprintf("%0.4i", year)
    if (tolower(form[1]) == 'jjj'){
      if (!inherits(x, 'character')){
        jjj <- sprintf("%0.3i", x)
      } else {
        jjj <- x
      }
      date <- as.Date(paste0(year, jjj), format = "%Y%j")
      mmdd <- format(date, "%m%d")
    } else {
      if (!inherits(x, 'character')){
        mmdd <- sprintf("%0.4i", x)
      } else {
        mmdd <- x
      }
      date <- as.Date(paste0(year, mmdd), format = '%Y%m%d')
      jjj <- format(date, "%j")
    }
  }

  dplyr::tibble(
    date,
    year = format(date, '%Y'),
    jjj,
    mmdd)
}



#' A basic query function to retrieve one or more datasets
#'
#' @export
#' @param top character, uri of the top catalog
#' @param platform character, the name of the platform (MODISA, MODIST, OCTS, SeaWiFS, VIIRS, etc.)
#' @param product character, the product type (L3SMI, etc.)
#' @param year character or numeric, four digit year(s) - ignored if \code{when} is not 'all'
#' @param day character or numeric, either 'jjj' or 'mmdd' form. Ignored if \code{when} is not
#'    'all'. You can improve efficiency by preselecting days for months, days, or
#'    seasons using \code{year} and \code{day}
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
#' @param day_form character either 'jjj' or 'mmdd' indicating the day request format.
#'    This is passed to \code{\link{obpg_date}} as \code{form} as required.
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
   day = format(Sys.Date(), "%m%d"),
   when = c("all", "any", "most_recent", "within", "before", "after")[1],
   date_filter = NULL,
   greplargs = NULL,
   verbose = FALSE,
   userpassword = c(user = 'user', password = 'password'),
   day_form = c('mmdd', 'jjj')[1]) {

  # Used to scan all/any days for the listed year
  # Product CatalogRefClass
  # dates tibble as produced by obpg_date
  # greplargs list of one or more grepl args
  get_all_obpg <- function(Product,
                           dates = obpg_date(),
                           greplargs = NULL,
                           verbose = Product$verbose_mode) {
    #if (!is.character(year)) year <- sprintf("%0.4i", year)
    R <- NULL
    YY <- Product$get_catalog()$get_catalogs(dates$year)
    for (iy in seq_along(YY)){
      DD <- YY[[iy]]$get_catalog()$get_catalogs(c(dates$mmdd, dates$jjj))
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

   dates <- obpg_date(day, year = year, form = day_form[1])
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
         warning("If when is 'within', 'before' or 'after' then date_filter must be provided. Returning NULL\n")
         return(NULL)
      }
      if ((when == 'within') && (length(date_filter) < 2) ) {
         warning("If when is 'within' then date_filter have [begin,end] elements. Returning NULL\n")
         return(NULL)
      }
      if (!inherits(date_filter, "POSIXt") && !inherits(date_filter, "Date")){
         cat("If when is 'within', 'before' or 'after' then date_filter must be date/time class. Returning NULL\n")
         return(NULL)
      }

      # compute the beginning and end
      if (inherits(date_filter, 'Date')){
        now <- Sys.Date()
        then <- as.Date("1990-01-01")
      } else {
        now <- as.POSIXct(Sys.time(), tz = 'UTC')
        then <- as.POSIXct("1990-01-01 00:00:00", tz = 'UTC')
      }
     # make sure the filter is setup
      tbounds <-   switch(tolower(when),
            'within' = date_filter[1:2],
            'after' = c(date_filter[1], now), # from date to now
            'before' = c(then, date_filter[1]) ) # from 1990 to date
      # convert to daily steps
      tsteps <- seq(tbounds[1], tbounds[2], by = 'day')
      dates <- obpg_date(tsteps)
      R <- get_all_obpg(Product, dates, greplargs = greplargs)
   } else {
      R <- get_all_obpg(Product, dates, greplargs = greplargs)

   }

   # if none found then we return NULL (not an empty list)
   if (length(R) == 0) R <- NULL
   if (verbose){
      cat(sprintf("obpg_query: retrieved %i records\n", length(R)))
   }
   invisible(R)
}
