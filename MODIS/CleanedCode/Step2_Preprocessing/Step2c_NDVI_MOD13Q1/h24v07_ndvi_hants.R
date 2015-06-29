library(raster)
library(rgdal)
library(spacetime)
library(zoo)
#### Set working directory ####
setwd("/media/MOD13_Q1/h24v07/")
#### Read NDVI Data ####
#### Create a list of layers and brick them ####

s1 <- list.files(pattern="NDVI.tif")
h24v07ndvi<-stack(s1)

#### Read WG boundary and tile info ####
### This has to be manually created for each tile, and smaller polygons can be used to process larger tiles ###

tileextent<-readOGR(dsn="/media/vector/", layer="wg_modis_tile_extent_NDVI")
## Check polygon corresponding to tile ##
tileextent@data

#### Crop and mask files to WG ####
h24v07ndvi<-crop(h24v07ndvi,(extent(as.SpatialPolygons.PolygonsList(tileextent@polygons[2]))), snap='out')
#### Create a mask for WG ####
blank<-raster(h24v07ndvi, layer=1)
blank<-reclassify(blank, c(-Inf,Inf,NA))
wgbound<-rasterize(as.SpatialPolygons.PolygonsList(tileextent@polygons[2]),blank,fun="first")

wgbound<-reclassify(wgbound, c(-Inf,Inf,1))

##Mask NDVI with WG boundary##
h24v07ndvi.m<-mask(h24v07ndvi,wgbound)

#####rescale ndvi with scale factor###
h24v07ndvi.m<-h24v07ndvi.m*0.0001

##Set name with dates##
names(h24v07ndvi.m)<-(strptime(paste(substr(s1, start=2, stop=5), substr(s1, start=6, stop=8)),
                                 format="%Y %j"))
h24v07ndvi.m<-setZ(h24v07ndvi.m, as.Date(strptime(paste(substr(s1, start=2, stop=5), substr(s1, start=6, stop=8)),
                                                      format="%Y %j")))

#### Export rescaled tiles as timeseries .gz for analysis in GRASS ####
write.tgrass(h24v07ndvi.m,"h24v07ndvi_scale.tar.gz",localName = F, isGeoTiff = T,overwrite=T)

####next analysis will be carried out in GRASS, using 'r.hants' command, with frequency 10########## 

### Import hants applied ndvi files#########
h24v07ndvi.hants<-read.tgrass("/media/MOD13_Q1/hants/h24v07/h24v07_hants10",
                       localName = F, isGeoTiff = T)
summary(h24v07ndvi.hants)

##if any value is greater than 1, rescale it to 1##
h24v07ndvi.hants[h24v07ndvi.hants>1]<-1

##Set names with dates##
names(h24v07ndvi.hants)<-(strptime(paste(substr(s1, start=2, stop=5), substr(s1, start=6, stop=8)),
                               format="%Y %j"))
h24v07ndvi.hants<-setZ(h24v07ndvi.hants, as.Date(strptime(paste(substr(s1, start=2, stop=5), substr(s1, start=6, stop=8)),
                                                  format="%Y %j")))

##Save raster##
writeRaster(h24v07ndvi.hants,"h24v07ndvi_hants10.grd",datatype='FLT4S',overwrite=T)

#### Create stack without months where data is unreliable due to cloud (June,July,August,September). Months in R start with 0 and ends at 11 ####

h24v07ndvi.JFMAMOND<- dropLayer(h24v07ndvi.hants, c(which(as.POSIXlt(getZ(h24v07ndvi.hants))$mon>=5 & as.POSIXlt(getZ(h24v07ndvi.hants))$mon <=8)))
h24v07ndvi.JFMAMOND<-setZ(h24v07ndvi.JFMAMOND,as.Date(strptime(paste(substr(names(h24v07ndvi.JFMAMOND),start=2, stop=12)),"%Y.%m.%d")))


writeRaster(h24v07ndvi.JFMAMOND,"h24v07ndvi_JFMAMOND.grd",datatype='FLT4S',overwrite=T)

#### Create annual stack with median function for non-rainy months####
yy<- function(x)as.numeric(format(x, '%Y'))
h24v07ndvi.JFMAMOND.median<-zApply(h24v07ndvi.JFMAMOND, by=yy, fun=median, na.rm=T)

writeRaster(h24v07ndvi.JFMAMOND.median,"ndvi_h24v07_median.grd",datatype='FLT4S',overwrite=T)

#### Extract NDVI to dataframe ####
nn2m <- cellsFromExtent(h24v07ndvi.JFMAMOND.median$X2000,extent(h24v07ndvi.JFMAMOND.median$X2000))
nxy<-xyFromCell(h24v07ndvi.JFMAMOND.median$X2000,nn2m)
ndvi.h24v07.JFMAMOND.median<- extract(h24v07ndvi.JFMAMOND.median,nxy, df=T)

#write.csv(ndvi.h24v07.JFMAMOND.median, "h24v07ndvi_JFMAMOND_median.csv", row.names=F)

#########Extract Median LST for corresponding NDVI tile####################

lst.h24v07.JFMAMOND<-brick("/media/MOD11_A2/h24v07/LST_h24v07_median.grd")

degC.h24v07.JFMAMOND<-extract(lst.h24v07.JFMAMOND, nxy, df=T)
#write.csv(degC.h24v07.JFMAMOND, "h24v07lst.JFMAMOND.csv", row.names=F)

###################### Extract TRMM ####################################
trmm.median<-brick("/media/trmm/trmmyearly_median.grd")

rain.h24v07.JFMAMOND<-extract(trmm.JFMAMOND, nxy, df=T)
#write.csv(rain.h24v07.JFMAMOND, "h24v07rain.JFMAMOND.csv", row.names=F)

##Save as R objects, to be used in analysis##
save(blank,rain.h24v07.JFMAMOND,h24v07ndvi.JFMAMOND.median,degC.h24v07.JFMAMOND, file="ndvi_h24v07.RData")
save.image("MOD13Q1h24v07.RData")
rm(list=ls())
print("Finished processing tile h24v07")
#q("no")