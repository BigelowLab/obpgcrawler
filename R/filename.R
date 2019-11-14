#' Decompose a new-convention L3 filename
#'
#' @seealso \href{https://oceancolor.gsfc.nasa.gov/docs/filenaming-convention/}{Ocean Color Filename Convention}
#' @export
#' @param x character vector of one or more filenames
#' @return a tibble of one or more rows (one row for each input filename)
#' \itemize{
#' \item{mission character }
#' \item{instrument character }
#' \item{type character possibly NA if not present in filename}
#' \item{date1 Date start date}
#' \item{date2 numeric or Date end date or NA if none}
#' \item{level character }
#' \item{period character }
#' \item{suite character }
#' \item{product character }
#' \item{res character }
#' \item{nrt character possibly NA if not present in filename}
#' \item{ext character }
#' }
decompose_L3 <- function(
  x = c("SNPP_VIIRS.20180703.L3m.DAY.OC.chlor_a.4km.nc",
        "SNPP_VIIRS.20180703.L3m.DAY.OC.chl_ocx.4km.nc") ){

  # mission_instrument_type from SNPP_VIIRS
  miss_inst_typ <- function(x) {
    ss <- strsplit(x, "_", fixed = TRUE)
    m <- sapply(ss, '[[', 1)
    i <- sapply(ss, '[[', 2)
    n <- lengths(ss)
    typ <- rep(NA_character_, length(ss))
    hastyp <- n > 2
    if (any(hastyp)) typ[hastyp] <- sapply(ss[hastyp], "[[", 2)
    dplyr::tibble(mission = m, instrument = i, type = typ)
  }
  # dates from 20180703 and or 20180703_20180706
  date1_date2 <- function(x){
    ss <- strsplit(x, "_", fixed = TRUE)
    d0 <- as.Date(sapply(ss, '[[', 1), format = '%Y%m%d')
    n <- lengths(ss)
    d1 <- rep(NA_real_, length(ss))
    hasd1 <- n > 2
    if (any(hasd1)) d1[hasd1] <- as.Date(sapply(ss[hasd1], '[[', 2), format = '%Y%m%d')
    dplyr::tibble(date1 = d0, date2 = d1)
  }
  ff <- strsplit(basename(x), ".", fixed = TRUE)
  mit <- miss_inst_typ(sapply(ff, "[[", 1))
  dates <- date1_date2(sapply(ff, "[[", 2))
  y <- dplyr::tibble(
    level = sapply(ff, "[[", 3),
    period = sapply(ff, "[[", 4),
    suite = sapply(ff, "[[", 5),
    product   = sapply(ff, "[[", 6),
    res       = sapply(ff, "[[", 7))
  r <- dplyr::bind_cols(mit, dates, y)
  n <- lengths(ff)
  ix <- n > 8
  nrt <- rep(NA_character_, length(ff))
  if (any(ix)) nrt[ix] <- sapply(ff[ix], "[[", 8)
  ext <- sapply(seq_along(n), function(i) ff[[i]][[n[i]]])
  r %>% dplyr::mutate(
    nrt = nrt,
    ext = ext)
}


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
