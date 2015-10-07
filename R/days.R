#' Compute the first or last day of the month for a given year.  
#' Useful for retrieving monthly data stored ont the first day of each month.
#'
#' @export
#' @family DAYS
#' @param year numeric or character the year(s) to compute
#' @param form charcater, by default we return the day of the year
#' @param when character either 'first' or 'last' to indicate the first or last day of the month
#' @return a list of character vectors of the last day of the months for the years specified
#'    one list element per year
#' @seealso \url{http://oceancolor.gsfc.nasa.gov/BROWSE_HELP/L3/}
get_monthdays <- function(year, form = '%j', when = c("first", "last")[1]){
   
   # one calendar month's worth of data; this will be 28, 29, 30, or 31 days' 
   # worth of data depending on the month. 
   month_one_year <- function(year, form = '%j', when = 'last'){
      y0 <- sprintf("%0.4i-01-01", year)
      y1 <- sprintf("%0.4i-12-31", year)
      d <- seq(as.Date(y0), as.Date(y1), by = 'day')
      switch(tolower(when),
         'last' = sapply(split(d,format(d, '%m')), function(x) format(x[length(x)], form)),
         'first' = sapply(split(d,format(d, '%m')), function(x) format(x[1], form)))
   }   
   x <- lapply(as.numeric(year), month_one_year, form = form[1], when = when[1])
   names(x) <- year
   x
}


#' Compute the first or last day of 8-day intervals for a given year.  Handles
#' leap years when finding the last day of 8-day intervals.
#'
#' @export
#' @family DAYS
#' @param year numeric or character the year(s) to compute
#' @param form charcater, by default we return the day of the year in '001' form
#' @param when character either 'first' or 'last' to indicate the first or last 
#'    day of the 8-day interval
#' @return a list of character vectors of the last day of the 8-day interval for 
#'    the years specified with one list element per year.  Be advised that the first
#'    day of winter for a given year occurs in the prior year.
#' @seealso \url{http://oceancolor.gsfc.nasa.gov/BROWSE_HELP/L3/}
get_8days <- function(year, form = '%j', when = 'first'){

   # eight consecutive days' worth of data with predetermined start and stop days; 
   # the first 8-day period of each year always begins with January 1, the second 
   # with January 9, the third with January 17, etc. The final "8-day" composite of
   # each year comprises only five days in non-leap years (27 - 31 December) or six
   # days in leap years (26 - 31 December).
   
   # see http://www.r-bloggers.com/leap-years/
   # see https://cran.r-project.org/web/packages/pheno/index.html
   last_day <- function(year){
      year <- as.numeric(year)
      #http://en.wikipedia.org/wiki/Leap_year
      if (((year %% 4 == 0) & (year %% 100 != 0)) | (year %% 400 == 0)) {
         return(366)
      } else {
         return(365)
      }
   }

   eight_one_year <- function(year, form = '%j'){
      days <- switch(tolower(when[1]),
         'first' = seq(from = 1, to = 365, by = 8),
         'last' = c(seq(from = 8, to = 365, by = 8), last_day(year))) 
      format(as.Date(sprintf('%0.4i-%0.3i', year, days), format = '%Y-%j'), format = form)
   }
   x <- lapply(as.numeric(year), eight_one_year, form = form)
   names(x) <- year
   x
} 


#' Compute the first or last day of seasons for a given year.  
#' Useful for retrieving seasonal data.
#'
#' @export
#' @family DAYS
#' @param year numeric or character the year(s) to compute
#' @param form charcater, by default we return the day of the year
#' @param when character either 'first' or 'last' to indicate the first or last day of the season
#' @return a list of character vectors of the last day of the seasons for the years 
#'    specified with one list element per year
#' @seealso \url{http://oceancolor.gsfc.nasa.gov/BROWSE_HELP/L3/}
get_seasondays <- function(year, form = '%j', when = c('first', 'last')[1]){

   #  Winter 21 December through 20 March of the following year
   #  Spring 21 March through 20 June of the same year
   #  Summer 21 June through 20 September of the same year
   #  Autumn 21 September through 20 December of the same year 
   
   seasons_one_year <- function(year, form = '%j', when = 'first') {
      x <- switch(tolower(when),
         'first' = c(
            winter = as.Date(sprintf("%0.4i-12-21", as.numeric(year)-1)),
            spring = as.Date(sprintf("%0.4i-03-21", year)),
            summer = as.Date(sprintf("%0.4i-06-21", year)),
            autumn = as.Date(sprintf("%0.4i-09-21", year)) ),
         'last' = c(
            winter = as.Date(sprintf("%0.4i-03-20", year)),
            spring = as.Date(sprintf("%0.4i-06-20", year)),
            summer = as.Date(sprintf("%0.4i-09-20", year)),
            autumn = as.Date(sprintf("%0.4i-12-20", year)) ) )
      format(x, format = form)
   }
   x <- lapply(as.numeric(year), seasons_one_year, form = form, when = when)
   names(x) <- year
   x
}
