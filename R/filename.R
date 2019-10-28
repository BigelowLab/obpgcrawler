#' Construct an new-convention L3 filename from consituent segments
#'
#' @seealso \href{https://oceancolor.gsfc.nasa.gov/docs/filenaming-convention/}{Ocean Color Filename Convention}
#' @export
#' @param mission character such as 'MODIS'
#' @param instrument character such as 'AQUA'
#' @param type character such as 'GAC' or NA to skip
#' @param date Date one or two elements depending upon the \code{period}
#' @param level character such as 'L3m'
#' @param period character such as 'DAY'
#' @param suite character such as 'CHL' or NA to skip
#' @param product character such as 'chlor_a' or NA to skip
#' @param nrt character, 'NRT' (near real time) or NA to skip
#' @param res character such as '4km' or NA to skip
#' @param ext character such as 'nc' or NA to skip
#' @return a character L3 filename
#' @examples
#' \dontrun{
#' compose_L3(mission = 'MODIS', date = as.Date("2001-01-01"))
#' # [1] "MODIS_AQUA.2001001.L3m.DAY.CHL.chlor_a.4km.nc"
#' }
compose_L3 <- function(
  mission = c("MODIS",  "S3A", "SNPP", "ADEOS", "SEASTAR")[1],
  instrument = c("AQUA", "TERRA", "OLCI", "SEAWIFS", "VIIRS", "OCTS")[1],
  type = c(NA, "ERR", "GAC", "EFR"),
  date = Sys.Date(),
  level = "L3m",
  period = "DAY",
  suite = 'CHL',
  product = "chlor_a",
  nrt = NA,
  res = "4km",
  ext = "nc"
  ){

  src <- sprintf("%s_%s", toupper(mission[1]), toupper(instrument[1]))
  if (!is.na(type[1])) src <- sprintf("%s_%s", src, toupper(type))

  period <- toupper(period[1])
  if (!inherits(date, 'Date')) date <- as.Date(date)
  date <- format(date, "%Y%j")
  if (period != "DAY"){
    if (length(date) < 2) stop("date must have 2 elements is period greater than DAY")
    date <- sprintf("%s_%s", date[1], date[2])
  }

  name <- sprintf("%s.%s.%s.%s.%s", src, date, level[1], period, toupper(suite[1]))

  if (!is.na(product[1])) name <- sprintf("%s.%s", name, product[1])
  if (!is.na(res[1])) name <- sprintf("%s.%s", name, res[1])
  if (!is.na(nrt[1])) name <- sprintf("%s.%s", name, nrt[1])
  if (!is.na(ext[1])) name <- sprintf("%s.%s", name, ext[1])

  name

}
