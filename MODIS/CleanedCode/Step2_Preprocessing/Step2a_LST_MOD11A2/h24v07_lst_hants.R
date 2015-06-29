library(raster)
library(zoo)
library(rgdal)
library(ncdf)
library(spacetime)

#### Set working directory ####
setwd("/media/MOD11_A2/h24v07/")

#### Read LST Data ####
#### Create a list of layers and brick them ####
s1 <- list.files(pattern="LST_Day_1km")
h24v07daylst<-stack(s1)

##Import WG boundary
tileextent<-readOGR(dsn="/media/vector/", layer="wg_modis_LST_tileExtent")
## Check polygon corresponding to tile ##
tileextent@data

#### Crop files to WG ####
h24v07daylst<-crop(h24v07daylst,(extent(as.SpatialPolygons.PolygonsList(tileextent@polygons[2]))),snap='out')

#### Create a mask for WG ####
blank<-raster(h24v07daylst, layer=1)
blank<-reclassify(blank, c(-Inf,Inf,NA))
wgbound<-rasterize(as.SpatialPolygons.PolygonsList(tileextent@polygons[2]),blank,fun="first")
#plot(wgbound)
wgbound<-reclassify(wgbound, c(-Inf,Inf,1))

##Mask with WG boundary##
h24v07daylst.m<-mask(h24v07daylst,wgbound)

##Apply rescale and covert units from Kelvin to Celsius##
h24v07daylst.m<-h24v07daylst.m*0.02-273.15

##Set names with dates##
names(h24v07daylst.m)<-(strptime(paste(substr(s1, start=2, stop=5), substr(s1, start=6, stop=8)),
                                 format="%Y %j"))
h24v07daylst.m<-setZ(h24v07daylst.m, as.Date(strptime(paste(substr(s1, start=2, stop=5), substr(s1, start=6, stop=8)),
                                                      format="%Y %j")))

#### Export rescaled tiles as timeseries .gz for analysis in GRASS ####
write.tgrass(h24v07daylst.m,"h24v07lst_scale2.tar.gz",localName = F, isGeoTiff = T,overwrite=T)

####next analysis will be carried out in GRASS, using 'r.hants' command, with frequency 10########## 

#### Read hants appied data as Time Series oject ####

h24v07daylst.m<-read.tgrass("/media/MOD11_A2/hants/h24v07/lst_hants_10_300",
                       localName = F, isGeoTiff = T)
##Set names##
names(h24v07daylst.m)<-(strptime(paste(substr(s1, start=2, stop=5), substr(s1, start=6, stop=8)),
                                 format="%Y %j"))
h24v07lst.m<-setZ(h24v07daylst.m, as.Date(strptime(paste(substr(s1, start=2, stop=5), substr(s1, start=6, stop=8)),
                                                      format="%Y %j")))
#plot(h24v07lst.m)
##Save as raster for reference##
writeRaster(h24v07lst.m,"h24v07lst_hants28.grd",datatype='FLT4S',overwrite=T)

#### Create monthly stack with appropriate function ####
h24v07lst.monthly<-zApply(h24v07lst.m,by=as.yearmon,fun=mean, na.rm=T)
#plot(h24v07lst.monthly)
writeRaster(h24v07lst.monthly,"h24v07lst_hants10_monthly.grd",overwrite=T)

#### Create Annual stack with median function. Months in R start with 0 and ends at 11 ####
yy<- function(x)as.numeric(format(x, '%Y'))
h24v07lst.median<-zApply(h24v07lst.m,by=yy,fun=median,na.rm=T)
#getZ(h24v07lst.median)
#plot(h24v07lst.median)
writeRaster(h24v07lst.median,"LST_24v07_median.grd",overwrite=T)

#### Create Annual stack, average of March-May (Summer). Months in R start with 0 and ends at 11 ####
t2<-subset(h24v07lst.m, which(as.POSIXlt(getZ(h24v07lst.m))$mon>=2 & as.POSIXlt(getZ(h24v07lst.m))$mon <=4))
t2<-setZ(t2,as.Date(getZ(t2)))
h24v07lst.a<-zApply(t2,by=yy,fun=mean,na.rm=T)# Average for MAM
#getZ(h24v07lst.a)
#plot(h24v07lst.a)
writeRaster(h24v07lst.a,"h24v07lst_MAM_hants10.grd",overwrite=T)

#### Create monthly stack without JJAS (cloudy months- June,July,Augut,September). Months in R start with 0 and ends at 11 ####
h24v07LST.JFMAMOND<- dropLayer(h24v07lst.m, c(which(as.POSIXlt(getZ(h24v07lst.m))$mon>=5 & as.POSIXlt(getZ(h24v07lst.m))$mon <=8)))
h24v07LST.JFMAMOND<-setZ(h24v07LST.JFMAMOND,as.Date(strptime(paste(substr(names(h24v07LST.JFMAMOND),start=2, stop=12)),"%Y.%m.%d")))
writeRaster(h24v07LST.JFMAMOND,"h24v07LST_JFMAMOND_hants10.grd",datatype='FLT4S',overwrite=T)

#### Create stack of annual mean for non-rainy months####
h24v07LST.JFMAMOND.monthly<-zApply(h24v07LST.JFMAMOND,by=as.yearmon,fun=mean,na.rm=T)
#plot(h24v07LST.JFMAMOND.monthly)
writeRaster(h24v07LST.JFMAMOND.monthly,"h24v07LST_JFMAMOND_monthly_hants10.grd",datatype='FLT4S',overwrite=T)

##Save R objects##
save.image("lst24v07.RData")
rm(list=ls())
print("Finished processing tile h24v07")
#q("no")