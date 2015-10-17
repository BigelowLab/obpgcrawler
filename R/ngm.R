# The Nested Grid Mode, Norman A. Phillips, April 1979
# NOAA Technical Report NWS 22

# Outer Grid A
# inner grids B and C

# GRN Greenwich meridian
# a = radius of earth
# theta = geographic lat
# lambda = geographic lon

# 1.5
# [x,y] <- 2a*(cos(theta)/(1+sin(theta))*[cos(lambda), sin(lambda)]

#' Compute the grid x,y locations from longitude and latitude
#' 
#' @param theta numeric, geographic lat
#' @param lambda numeric, geographic lon
#' @param a numeric, radius of earth
#' @return two element nmeric vector of x,y
grid_center <- function(theta = 45, lambda = 45, a = 1){
   2*a*(cos(theta)/(1+sin(theta)))* c(cos(lambda), sin(lambda))
}

# 1.6
# The outer grid, denoted by A, is a square array in which i and j each run in the x and y directions from 1 through 2•NH+6. The North Pole on this grid is located at
#   i =  j =  NH+4.

# 1.7
# integer NH determines the horizontal grid spacing delta on this grid
# deltaA = 2a/(NH + 0.5)

#' Compute the grid delta
#' 
#' @param NH integer, grid spacing
#' @param a radius of the earth
#' @return numeric
grid_delta <- function(NH = 10, a = 1){
   2*a/(NH + 0.5)
}
