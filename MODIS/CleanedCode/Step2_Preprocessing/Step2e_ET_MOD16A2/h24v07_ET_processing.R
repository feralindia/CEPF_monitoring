library(raster)
library(zoo)
library(rgdal)
library(ncdf)
#### Set working directory ####
setwd("/media/MOD16_A2/h24v07/")
#### Read ET Data. List and stack all the layers ####
s1 <- list.files(pattern=".tif$")
h24v07ET<-stack(s1)

##Import WG boundary and read tile info##
tileextent<-readOGR(dsn="/media/vector/", layer="wg_modis_ET_tileExtent")
tileextent@data

#### Crop and mask files to corrsponding layer in WG tile extent####
h24v07ET<-crop(h24v07ET,(extent(as.SpatialPolygons.PolygonsList(tileextent@polygons[2]))), snap='out')

#### Create a mask for WG ####
blank<-raster(h24v07ET, layer=1)
blank<-reclassify(blank, c(-Inf,Inf,NA))
wgbound<-rasterize(as.SpatialPolygons.PolygonsList(tileextent@polygons[2]),blank,fun="first")

wgbound<-reclassify(wgbound, c(-Inf,Inf,1))

##Mask with WG boundary##
h24v07ET.m<-mask(h24v07ET,wgbound)

#### Apply scale factor ####
h24v07ET.m<-h24v07ET.m*0.1

#### Set names with dates ####
names(h24v07ET.m)<-(strptime(paste(substr(s1, start=2, stop=5), substr(s1, start=7, stop=8),05),
                                 format="%Y %m %d"))
h24v07ET.m<-setZ(h24v07ET.m, as.Date(strptime(paste(substr(s1, start=2, stop=5), substr(s1, start=7, stop=8),05),
                                                      format="%Y %m %d")))
writeRaster(h24v07ET.m,"h24v07ET_scaled.grd",overwrite=T)

#### Create monthly stack ####
h24v07ET.monthly<-zApply(h24v07ET.m,by=as.yearmon,fun=mean,na.rm=T)

writeRaster(h24v07ET.monthly,"h24v07ET_monthly.grd",overwrite=T)

#### Create Annual stack ####
yy<- function(x)as.numeric(format(x, '%Y'))
h24v07ET.a<-zApply(h24v07ET.m,by=yy,fun=sum,na.rm=T)
getZ(h24v07ET.a)


writeRaster(h24v07ET.a,"h24v07ET_annual_sum.grd",overwrite=T)

#### Extract Data and save as CSV ####
nn2m <- cellsFromExtent(h24v07ET.a$X2000,extent(h24v07ET.a$X2000))
nxy<-xyFromCell(h24v07ET.a$X2000,nn2m)
ET.h24v07<- extract(h24v07ET.a,nxy, df=T)

#write.csv(ET.h24v07, "h24v07ET.annual.csv", row.names=F)

#########Extract LST for corresponding ET tile####################
lst.h24v07.a<-brick("/media/MOD11_A2/h24v07/h24v07lst_MAM_hants10.grd")

degC.h24v07<-extract(lst.h24v07.a, nxy, df=T)
#write.csv(degC.h24v07, "h24v07lst.annualET.csv", row.names=F)

### Extract TRMM ###
trmm.a<-brick("/media/trmmv73hour/trmm_annual.grd")

rain.h24v07<-extract(trmm.a, nxy, df=T)
#write.csv(rain.h24v07, "h24v07rain.annual.csv", row.names=F)

### Calaculate bluewater ###

rain.h24v07<-crop(trmm.a,extent(h24v07ET.a), snap='out' )
rain.h24v07<-resample(rain.h24v07,h24v07ET.a)
blueWater.h24v07<-(rain.h24v07 - h24v07ET.a)
#plot(blueWater.h24v07)

##Save as R objects, to be used for analysis##
###Save R objects to be used in the analysis###
save(blueWater.h24v07,rain.h24v07,degC.h24v07,ET.h24v07,
     blank, file="ET_rain_BW_h24v07.RData")
save.image("MOD16A2h24v07.RData")
rm(list=ls())
print("Finished processing tile h24v07")
#q("no")
