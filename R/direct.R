#' Download a direct data access file using \code{\link{download.file}}
#'
#' @param filename the name of the file to download - required as 'A2016186.L3m_DAY_CHL_chlor_a_4km.nc'
#' @param output_filename character the name of the output file, the default is the same as \code{filename}
#' @param output_path the file path to save to, the default is to save to the current path "."
#' @param base_uri character Oceandata's base uri (default 'http://oceandata.sci.gsfc.nasa.gov/cgi/getfile')
#' @param mode character - see \code{\link{download.file}}
#' @param ... other argments for \code{\link{download.file}}
#' @return 0 for success and non-zero otherwise - see \code{\link{download.file}}
download_direct <- function(filename, output_filename,
    output_path = ".", base_uri = 'http://oceandata.sci.gsfc.nasa.gov/cgi/getfile',
    mode = 'wb', ...){
    
    if (missing(filename)) stop("filename is required")
    if (missing(output_filename)) output_filename = filename[1]
    uri <- file.path(base_uri, filename[1])
    orig_dir <- setwd(output_path[1])
    r <- download.file(uri, basename(output_filename[1]), mode = 'wb', ...)
    setwd(orig_dir)
    
    return(r)
}


#' Query a direct data download webpage such as 
#' \url{http://oceandata.sci.gsfc.nasa.gov/MODIS-Aqua/Mapped/Daily/4km/chlor_a/2016}
#' 
#' This is fairly centric to 'Mapped' level data but some flexibility is provided to 
#' access other levels of data.
#' 
#' @export
#' @param base_uri character Oceandata's base uri (default 'http://oceandata.sci.gsfc.nasa.gov')
#' @param mission character one mission listed at base_uri (default 'MODIS-Aqua') 
#' @param level character level of processing is mission dependent.  See 
#'   \url{http://oceandata.sci.gsfc.nasa.gov/MODIS-Aqua} for an example. (default 'Mapped')
#' @param freq character (or NULL, "" or NA)  Some mission levels are processed at various
#'   freqencies.  See \url{http://oceandata.sci.gsfc.nasa.gov/MODIS-Aqua/Mapped}.  The default ('Daily')
#'   assumes there is a choice, but skip this by setting to \code{freq} to \code{NULL}, 
#'   \code{NA} or \code{""}.
#' @param res character (or NULL, "" or NA) resolution.  Defaults to '4km' but you can skip this 
#'   by setting to \code{freq} to \code{NULL}, \code{NA} or \code{""}.
#' @param param character the name of the parameter
#' @param year numeric (or character) year (2016 default)
#' @param alt_uri character or NULL.  Use this to specify your own full uri which ignores
#'  other parameters.
#' @return data.frame or NULL
query_direct <- function(base_uri = 'http://oceandata.sci.gsfc.nasa.gov', 
    mission = 'MODIS-Aqua',
    level = 'Mapped',
    freq = 'Daily',
    res = '4km',
    param = 'chlor_a',
    year = 2016,
    alt_uri = NULL){

    # test if x is NA, NULL or ""
    not_missing <- function(x) {
        if (is.character(x)) {
            r <- nchar(x) > 0
        } else {
           r <- !is.null(x)
           if (r) r <- !is.na(x)
        }
        r
    }
    
    
    if (!is.null(alt_uri)) {
        uri <- alt_uri[1]
    } else {
        #list_uri <- file.path(base_uri, mission,level,freq,res,param,year)
        uri <- c(base_uri[1], mission[1], level[1])
        if (not_missing(freq[1])) uri <- c(uri, freq[1])
        if (not_missing(res[1])) uri <- c(uri, res[1])
        uri <- c(uri, param[1], as.character(year[1]))
        uri <- paste(uri, collapse = "/")
    } 

    r <- httr::GET(uri)
    if (httr::status_code(r) == 200){
        x <- list_uri %>%
            xml2::read_html(httr::content(r, type = 'text/html', as = 'text', encoding = 'UTF-8')) %>%
            rvest::html_nodes(xpath='//*[@id="content"]/table') %>%
            rvest::html_table()
    } else {
        # hmmmm - what's up?
        print(r)
        x <- NULL
    }

    return(x[[1]])
}