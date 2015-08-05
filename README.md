#### OBPG Crawler

[Ocean Biologiy Procesing Group](http://oceancolor.gsfc.nasa.gov/cms/homepage) provides OpeNDAP access to data.  `obpg` package provides basic THREDDS crawling facilties.  The idea is to programmatically search the OpeNDAP offerings at [OceanColor](http://oceancolor.gsfc.nasa.gov/cms/homepage).  There are many facilities for searching the website, but using the THREDDS catalogs for programmatic access seems just right.  Use cases...

+ Retrieve the most recent 8DAY 4km CHLA from MODISA (example below)
+ Retrieve MODISA Chlorophyll 8DAY 4km L3SMI's from days 1-30 in 2014 and 2015 (example below)

#### Requirements

    [R >= 3.0](http://cran.r-project.org)
    [httr](http://cran.r-project.org/web/packages/httr/index.html)
    [XML](http://cran.r-project.org/web/packages/XML/index.html)

#### Installation

It is easiest to install with devtools

```R
library(devtools)
install_github("btupper/obpgcrawler")
```

#### Classes

`TopCatalogRefClass` for catalogs that are containers of `CatalogRefClass` pointers.  This is like a listing of files and subdirectories in a directory, but here the files and subdirectories are all `CatalogRefClass` pointers. 

`CatalogRefClass` is a pointer to `TopCatalogRefClass`  
 
BPG's `dataset` unfortunately comes in two flavors: collections of datasets and direct datasets.  I split these into  `DatasetsRefClass` (collections) and `DatasetRefClass` (direct); the latter has an 'access' child node the former does not.  A collection is a listing of one or more datasets (either direct or catalogs).  A direct dataset is a pointer to an actual OpeNDAP resource (like a NetCDF file, the very thing we seek!)

#### Data Organization

OBPG data is organized by PLATFORM, PRODUCT, YEAR, DAY.  Data files are stored at the day level.

+ PLATFORM such as MODISA MODIST OCTS SeaWiFS VIIRS
+ PRODUCT such as L3SMI by I suppose other products such as L2 etc might come along
+ YEAR such as 2002 2003 2004 ... 2011 2012 2013 2014 2015
+ DAY such as 001 002 003 ...  360 361


#### The way good easy way example

Q: What is in the most recent offering from platform = MODISA product = L3SMI of 8day 4km chla?

A: Yes, with obpg_query()!

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

Q: Can I get all of the MODISA Chlorophyll 8-day L3SMI's from days 1-30 in 2014 and 2015?

A: Yes, with obpg_query()!

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


Woooohooo!



#### Step by step example 

Q:  What is in the most recent offering from platform = MODISA product = L3SMI and year = 2015?

A: First we get the top level catalog for the OpeNDAP offerings.
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
Reference Class: "TopCatalogRef" (from the global environment)
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
Reference Class: "TopCatalogRef" (from the global environment)
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
  datasets: NA
  dataSize:47093655
  date:NA
  serviceName:dap
  urlPath:/MODISA/L3SMI/2015/201/A2015201.L3m_DAY_NSST_sst_4km.nc

$A2015201.L3m_DAY_NSST_sst_9km.nc
Reference Class: "DatasetRefClass" 
  url: http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/201/A2015201.L3m_DAY_NSST_sst_9km.nc
  children: dataSize date access
  datasets: NA
  dataSize:12376940
  date:NA
  serviceName:dap
  urlPath:/MODISA/L3SMI/2015/201/A2015201.L3m_DAY_NSST_sst_9km.nc

$A2015201.L3m_DAY_SST4_sst4_4km.nc
Reference Class: "DatasetRefClass" 
  url: http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/201/A2015201.L3m_DAY_SST4_sst4_4km.nc
  children: dataSize date access
  datasets: NA
  dataSize:47143175
  date:NA
  serviceName:dap
  urlPath:/MODISA/L3SMI/2015/201/A2015201.L3m_DAY_SST4_sst4_4km.nc

$A2015201.L3m_DAY_SST4_sst4_9km.nc
Reference Class: "DatasetRefClass"
  url: http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/201/A2015201.L3m_DAY_SST4_sst4_9km.nc
  children: dataSize date access
  datasets: NA
  dataSize:12441580
  date:NA
  serviceName:dap
  urlPath:/MODISA/L3SMI/2015/201/A2015201.L3m_DAY_SST4_sst4_9km.nc
```

#### Accessing the data

If you want to access a dataset you can use the [ncdf4](http://cran.r-project.org/web/packages/ncdf4/index.html) package to access.

```R
library(ncdf4)
nc <- ncdf4::nc_open(dataset[['A2015201.L3m_DAY_SST4_sst4_9km.nc']]$url)
nc
> nc
File http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/201/A2015201.L3m_DAY_SST4_sst4_9km.nc (NC_FORMAT_CLASSIC):

     3 variables (excluding dimension variables):
        byte palette[eightbitcolor,rgb]   
        short sst4[lon,lat]   
            long_name: 4um Sea Surface Temperature
            units: degree_C
            standard_name: sea_surface_temperature
            display_scale: linear
            display_min: -2
            display_max: 45
            scale_factor: 0.000717184972018003
            add_offset: -2
        short qual_sst4[lon,lat]   

     4 dimensions:
        eightbitcolor  Size:256
        lat  Size:2160
            long_name: Latitude
            units: degree_north
            _FillValue: -32767
            valid_min: -90
            valid_max: 90
        lon  Size:4320
            long_name: Longitude
            units: degree_east
            _FillValue: -32767
            valid_min: -180
            valid_max: 180
        rgb  Size:3

    65 global attributes:
        product_name: A2015201.L3m_DAY_SST4_sst4_9km.nc
        instrument: MODIS
        title: MODIS Level-3 Standard Mapped Image
        project: Ocean Biology Processing Group (NASA/GSFC/OBPG)
        platform: Aqua
        temporal_range: day
            .
            .
            .
        cdm_data_type: grid
        identifier_product_doi_authority: http://dx.doi.org
        identifier_product_doi: 10.5067/AQUA/MODIS_OC.2014.0
        keywords: Oceans > Ocean Temperature > Sea Surface Temperature
        keywords_vocabulary: NASA Global Change Master Directory (GCMD) Science Keywords
```
