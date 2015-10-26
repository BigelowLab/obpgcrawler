#### OBPG Crawler

[Ocean Biology Processing Group](http://oceancolor.gsfc.nasa.gov/cms/homepage) provides OpeNDAP access to data.  `obpgcrawler` package provides basic THREDDS crawling facilties.  The idea is to programmatically search the OpeNDAP offerings at [OceanColor](http://oceancolor.gsfc.nasa.gov/cms/homepage).  There are many facilities for searching the website, but using the THREDDS catalogs for programmatic access seems just right.  Use cases...

+ Retrieve the most recent 8DAY 4km CHLA from MODISA (example below)
+ Retrieve MODISA Chlorophyll 8DAY 4km L3SMI's from days 1-30 in 2014 and 2015 (example below)
+ Retrieve MODISA Chlorophyll and SST monthly 4km L3SMI's 2008 and 2009

The above examples use the simple function, `obpg_query()`.  At the very end of this document is a description of detailed step-by-step process hidden in `obpg_query()`.

#### Requirements

[R >= 3.0](http://cran.r-project.org)

[threddscrawler](https://github.com/btupper/threddscrawler)

#### Installation

It is easy to install with [devtools](https://cran.r-project.org/web/packages/devtools/index.html)

```R
library(devtools)
install_github("btupper/obpgcrawler")
```

#### Classes

Most users will only use the `obpg_query()` and `get_*days()` functions, but in case you are interested here is a brief description of the various classes (all Reference Classes) used.

`TopCatalogRefClass` for catalogs that are containers of `CatalogRefClass` pointers.  This is like a listing of files and subdirectories in a directory, but here the files and subdirectories are all `CatalogRefClass` pointers. 

`CatalogRefClass` is a pointer to `TopCatalogRefClass`  
 
OBPG's `dataset` comes in two flavors: collections of datasets and direct datasets.  I split these into  `DatasetsRefClass` (collections) and `DatasetRefClass` (direct); the latter has an 'access' child node the former does not.  A collection is a listing of one or more datasets (either direct or catalogs).  A direct dataset is a pointer to an actual OpeNDAP resource (exposed as NetCDF object, the very thing we seek!)

#### Data Organization

OBPG data is organized by PLATFORM > PRODUCT > YEAR > DAY.  Data files are stored at the day level.

+ PLATFORM currently MODISA MODIST OCTS SeaWiFS or VIIRS
+ PRODUCT currently only L3SMI
+ YEAR such as 2002 2003 ... 2013 2014 2015
+ DAY such as 001 002 003 ...  360 361


#### Way good easy way examples

These two examples show how to use the `obpg_query()` function to simply collect one or more dataset descriptions.  These examples are MODISA-centric.

###### Q: What are the most recent offerings from MODISA L3SMI's of 8day 4km chla?

###### A: Go gettum with obpg_query()!  Note, the date will change if you run this.

```R
library(obpgcrawler)
query <- obpg_query(top = 'http://oceandata.sci.gsfc.nasa.gov/opendap/catalog.xml',
   platform = 'MODISA', 
   product = 'L3SMI',
   what = 'most_recent',
   greplargs = list(pattern='8D_CHL_chlor_a_4km', fixed = TRUE))
query
$A20151932015200.L3m_8D_CHL_chlor_a_4km.nc
Reference Class: "DatasetRefClass"
  url: http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/193/A20151932015200.L3m_8D_CHL_chlor_a_4km.nc
  children: dataSize date access
  dataSize:26844930
  date:2015-08-05T11:05:15
  serviceName:dap
  urlPath:/MODISA/L3SMI/2015/193/A20151932015200.L3m_8D_CHL_chlor_a_4km.nc
```

###### Q: Can I get all of the MODISA Chlorophyll 8-day L3SMI's from days 1-30 in 2014 and 2015?

###### A: Yes, with obpg_query()!  Note that each day for each year is returned.

```R
query <- obpg_query(year = c('2014', '2015'),day = 1:30,
   greplargs = list(pattern='8D_CHL_chlor_a_4km', fixed = TRUE))
query
$A20140012014008.L3m_8D_CHL_chlor_a_4km.nc
Reference Class: "DatasetRefClass"
  url: http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2014/001/A20140012014008.L3m_8D_CHL_chlor_a_4km.nc
  children: dataSize date access
  dataSize:30411689
  date:2015-06-26T02:52:51
  serviceName:dap
  urlPath:/MODISA/L3SMI/2014/001/A20140012014008.L3m_8D_CHL_chlor_a_4km.nc

    <... snip there are 8 of them ...>

$A20150252015032.L3m_8D_CHL_chlor_a_4km.nc
Reference Class: "DatasetRefClass"
  url: http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/025/A20150252015032.L3m_8D_CHL_chlor_a_4km.nc
  children: dataSize date access
  dataSize:31609299
  date:2015-06-26T02:52:55
  serviceName:dap
  urlPath:/MODISA/L3SMI/2015/025/A20150252015032.L3m_8D_CHL_chlor_a_4km.nc
```

#### Best practices for getting data

OBPG organizes data by platform/product/year/day - you can improve access times by precomputing the days to search.  In addition, you can specify more than one search pattern in one search.  For example, to get the monthly SST and CHL for 2008 and 2009 we supply two search patterns as well as explicitly provide the days to search.

```R
top = 'http://oceandata.sci.gsfc.nasa.gov/opendap/catalog.xml'
platform = 'MODISA'
product = 'L3SMI'
greplargs = list(
   chl = list(pattern='MO_CHL_chlor_a_9km', fixed = TRUE),
   sstM = list(pattern ='MO_SST_sst_9km', fixed = TRUE))

# precompute the days to search
days <- get_monthdays(c(2008, 2009))

# we get 2008 and 2009 separately since 2008 is a leap year and the months
# may have different start days that in 2009
x <- c(
    obpg_query(top = top, platform = platform, product = product,
        year = 2008, day = days[['2008']], what = 'all',
        greplargs = greplargs),
    obpg_query(top = top, platform = platform, product = product,
        year = 2009, day = days[['2009']], what = 'all',
        greplargs = greplargs) )
```

An alternative is to provide a window of dates within which to search.  This will iterate through all of the days between to the two times provided - which can be slower than the above.

```R
date_filter <- as.Date(c("2008-01-01", "2009-12-31"))
x <- obpg_query(top = top, platform = platform, product = product,
        what = 'within', date_filter = date_filter,
        greplargs = greplargs)
```
  

#### Accessing the data

A dataset can be accessed using the [ncdf4](https://cran.r-project.org/web/packages/ncdf4/index.html) or [spnc](https://github.com/btupper/spnc) packages.  Below is an example using `spnc`.

```R
library(spnc)
query <- obpg_query(year = c('2014', '2015'),day = 1:30,
+    greplargs = list(pattern='8D_CHL_chlor_a_4km', fixed = TRUE))
chl <- SPNC(query[['A20140012014008.L3m_8D_CHL_chlor_a_4km.nc']]$url)
chl
# Reference Class: "L3SMIRefClass" 
#   flavor: source=L3SMI type=raster local=FALSE 
#   state: opened 
#   bounding box: -180 180 -90 90 
#   VARS: palette chlor_a 
#   DIMS: eightbitcolor=256 lat=4320 lon=8640 rgb=3 
#   LON: [ -179.979172, 179.979172] 
#   LAT: [ 89.979164, -89.979179] 
#   TIME: [ 2014-01-01, 2014-01-01]

bb <- c(xmin = -77, xmax = -63, ymin = 35, ymax = 46)

r <- chl$get_raster(what = 'chlor_a', bb = bb)
# r
# class       : RasterStack 
# dimensions  : 264, 337, 88968, 1  (nrow, ncol, ncell, nlayers)
# resolution  : 0.04154302, 0.04150885  (x, y)
# extent      : -77.02083, -63.02083, 35.02083, 45.97917  (xmin, xmax, ymin, ymax)
# coord. ref. : +proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0 
# names       :  layer_1 
# min values  : 0.115527 
# max values  : 68.65778 

sp::spplot(log10(r))
```

#### Step by step example 

Here is a worked example showingf each step; these steps are hidden when you use `obpg_query()`.  Let's follow this line of this question "What is in the most recent offering from platform = MODISA product = L3SMI and year = 2015?"

First we get the top level catalog for the OpeNDAP offerings. 
[web](http://oceandata.sci.gsfc.nasa.gov/opendap/) 
[catalog.xml](http://oceandata.sci.gsfc.nasa.gov/opendap/hyrax/catalog.xml)

```R
uri <- oceancolor_catalog <- 'http://oceandata.sci.gsfc.nasa.gov/opendap/catalog.xml'
Top <- get_catalog(oceancolor_catalog)
Top
Reference Class: "TopCatalogRef"
  url: http://oceandata.sci.gsfc.nasa.gov/opendap/catalog.xml
  children: service dataset
  catalogs: MODISA MODIST OCTS SeaWiFS VIIRS
```

Next we select the MODISA catalog. 
[web](http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/contents.html) 
[catalog.xml](http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/catalog.xml)

```R
catalogs <- Top$get_catalogs()
MODISA <- catalogs[['MODISA']]$GET()
MODISA
Reference Class: "TopCatalogRef"
  url: http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/catalog.xml
  children: service dataset
  catalogs: L3SMI
```

Next we select the L3SMI catalog. (yes, it is the only subcatalog) 
[web](http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/contents.html) 
[catalog.xml](http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/catalog.xml)

```R
catalogs <- MODISA$get_catalogs()
L3SMI <- catalogs[['L3SMI']]$GET()
L3SMI
Reference Class: "TopCatalogRef"
  url: http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/catalog.xml
  children: service dataset
  catalogs: 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015
```

Next we select the 2015 catalog. 
[web](http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/contents.html) 
[catalog.xml](http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/catalog.xml)

```R
YEARS <- L3SMI$get_catalogs()
Y2015 <- YEARS[['2015']]$GET()
Y2015
Reference Class: "TopCatalogRef" 
  url: http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/catalog.xml
  children: service dataset
  catalogs: 001 002 003 ... 197 198 199 200 201
```  

And now we select the most recent day (let's assume that is day 201) 
[web](http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/201/contents.html) 
[catalog.xml](http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/201/catalog.xml)

```R
DAYS <- Y2015$get_catalogs()
D201 <- DAYS[['201']]$GET()
D201
Reference Class: "TopCatalogRef" 
  url: http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/201/catalog.xml
  children: service dataset
  datasets: A2015201.L3m_DAY_NSST_sst_4km.nc A2015201.L3m_DAY_NSST_sst_9km.nc A2015201.L3m_DAY_SST4_sst4_4km.nc A2015201.L3m_DAY_SST4_sst4_9km.nc
```

So that brings us to our 'deepest' penetration into the organization showing just 4 items.  We can retrieve the datasets.

```R
datasets <- D201$get_datasets()
datasets
$A2015201.L3m_DAY_NSST_sst_4km.nc
Reference Class: "DatasetRefClass"
  url: http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/201/A2015201.L3m_DAY_NSST_sst_4km.nc
  children: dataSize date access
  dataSize:47093655
  date:2015-08-05T11:28:29
  serviceName:dap
  urlPath:/MODISA/L3SMI/2015/201/A2015201.L3m_DAY_NSST_sst_4km.nc

$A2015201.L3m_DAY_NSST_sst_9km.nc
Reference Class: "DatasetRefClass"
  url: http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/201/A2015201.L3m_DAY_NSST_sst_9km.nc
  children: dataSize date access
  dataSize:12376940
  date:2015-08-05T11:28:41
  serviceName:dap
  urlPath:/MODISA/L3SMI/2015/201/A2015201.L3m_DAY_NSST_sst_9km.nc

$A2015201.L3m_DAY_SST4_sst4_4km.nc
Reference Class: "DatasetRefClass"
  url: http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/201/A2015201.L3m_DAY_SST4_sst4_4km.nc
  children: dataSize date access
  dataSize:47143175
  date:2015-08-05T11:22:01
  serviceName:dap
  urlPath:/MODISA/L3SMI/2015/201/A2015201.L3m_DAY_SST4_sst4_4km.nc

$A2015201.L3m_DAY_SST4_sst4_9km.nc
Reference Class: "DatasetRefClass"
  url: http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/201/A2015201.L3m_DAY_SST4_sst4_9km.nc
  children: dataSize date access
  dataSize:12441580
  date:2015-08-05T11:22:14
  serviceName:dap
  urlPath:/MODISA/L3SMI/2015/201/A2015201.L3m_DAY_SST4_sst4_9km.nc
```

