#' Compute the grid x,y locations from longitude and latitude
#'
#' From The Nested Grid Mode, Norman A. Phillips, April 1979, NOAA Technical Report NWS 22
#'
#' @param theta numeric, geographic lat
#' @param lambda numeric, geographic lon
#' @param a numeric, radius of earth
#' @return two element nmeric vector of x,y
grid_center <- function(theta = 45, lambda = 45, a = 1){
   2*a*(cos(theta)/(1+sin(theta)))* c(cos(lambda), sin(lambda))
}

#' Compute the grid delta
#'
#' From The Nested Grid Mode, Norman A. Phillips, April 1979, NOAA Technical Report NWS 22
#'
#' @param NH integer, grid spacing
#' @param a radius of the earth
#' @return numeric
grid_delta <- function(NH = 10, a = 1){
   2*a/(NH + 0.5)
}
