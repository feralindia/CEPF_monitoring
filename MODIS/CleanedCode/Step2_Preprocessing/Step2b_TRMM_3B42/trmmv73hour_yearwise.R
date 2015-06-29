library(raster)
library(zoo)
library(rgdal)
library(ncdf)
#### Set working directory ####
setwd("/media/trmmv73hour/")
#### Read TRMM Data. Create a list and stack them ####
s1 <- list.files(pattern =".nc$")
trmm.h<-stack(s1, varname="pcp",quick=T)
plot(trmm.h)

##Change projection##
utmz43<-"+proj=utm +zone=43 +datum=WGS84 +units=m +no_defs"
trmm.h<-projectRaster(trmm.h, crs=utmz43)

#### Read WG boundary##
tileextent<-readOGR(dsn="/media/vector/", layer="WGhats_bounds_utm")
plot(tileextent)

##Crop data to WG##
trmm.h<-crop(trmm.h,tileextent,snap='out')
plot(trmm.h)

##Apply scale factor. The data is mean of every 3 hrs. Multiply with 3 to get actual values##
trmm.h<-trmm.h*3

##Set names and time with dates##
names(trmm.h)<-(strptime(paste(substr(s1, start=6, stop=9), substr(s1, start=10, stop=11),
                               substr(s1, start=12, stop=13),  substr(s1, start=15, stop=16)),
                         format="%Y %m%d"))
trmm.h<-setZ(trmm.h, as.Date(strptime(paste(substr(s1, start=6, stop=9), substr(s1, start=10, stop=11),
                                            substr(s1, start=12, stop=13),  substr(s1, start=15, stop=16)),
                                      format="%Y %m%d")),"Date")

#### Generate daily totals ####
dd<- function(x)as.numeric(format(x, '%Y%m%d'))
trmm.d<-zApply(trmm.h,by=dd,fun=sum,na.rm=T)

##Set names and time with dates##
names(trmm.d)<-unique(as.Date(strptime(paste(substr(s1, start=6, stop=9), substr(s1, start=10, stop=11),
                                             substr(s1, start=12, stop=13),  substr(s1, start=15, stop=16)),
                                       format="%Y %m%d")))
trmm.d<-setZ(trmm.d,unique(as.Date(strptime(paste(substr(s1, start=6, stop=9), substr(s1, start=10, stop=11),
                                                  substr(s1, start=12, stop=13),  substr(s1, start=15, stop=16)),
                                            format="%Y %m%d"))))
plot(trmm.d)
writeRaster(trmm.d,"trmm_daily.grd",overwrite=T)

#### Generate monthly totals ####
trmm.m<-zApply(trmm.h,by=as.yearmon,fun=sum, na.rm=T)
plot(trmm.m)
writeRaster(trmm.m,"trmm_monthly.grd",overwrite=T)

#### Generate Annual totals ####
yy<- function(x)as.numeric(format(x, '%Y'))
trmm.y<-zApply(trmm.h,by=yy,fun=sum,na.rm=T)
plot(trmm.y)
writeRaster(trmm.y,"trmm_annual.grd",overwrite=T)

#### Generate Annual stack with median function ####
yy<- function(x)as.numeric(format(x, '%Y'))
trmm.median<-zApply(trmm.h,by=yy,fun=median,na.rm=T)
plot(trmm.median)
writeRaster(trmm.median,"trmmyearly_median.grd",overwrite=T)

#### Create hourly stack without Rainy months (without June,July,August and September months). Months in R start with 0 and ends at 11 ####

trmm.JFMAMOND<- dropLayer(trmm.h, c(which(as.POSIXlt(getZ(trmm.h))$mon>=5 & as.POSIXlt(getZ(trmm.h))$mon <=8)))
trmm.JFMAMOND<-setZ(trmm.JFMAMOND,as.Date(strptime(paste(substr(names(trmm.JFMAMOND),start=2, stop=12)),"%Y.%m.%d")))
writeRaster(trmm.JFMAMOND,"trmm_JFMAMOND.grd",datatype='FLT4S',overwrite=T)

#### Create monthly stack without JJAS ####
trmm.JFMAMOND.monthly<-zApply(trmm.JFMAMOND,by=as.yearmon,fun=sum)
plot(trmm.JFMAMOND.monthly)
writeRaster(trmm.JFMAMOND.monthly,"trmm_JFMAMOND_monthly.grd",datatype='FLT4S',overwrite=T)

##Save R objects##
save.image("trmm_wg.RData")
rm(list=ls())
print("Finished processing TRMM")
#q("no")