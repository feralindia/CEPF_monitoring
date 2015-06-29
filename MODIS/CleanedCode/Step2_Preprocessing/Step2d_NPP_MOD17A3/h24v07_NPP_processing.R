library(raster)
library(zoo)
library(rgdal)
library(ncdf)
#### Set working directory ####
setwd("/media/MOD17_A3/h24v07/")
#### Read npp Data. List and stack all the layers ####
s1 <- list.files(pattern=".tif$")
h24v07npp<-stack(s1)

##Import WG boundary and read tile info##
tileextent<-readOGR(dsn="/media/vector/", layer="wg_modis_npp_tileExtent")
tileextent@data

#### Crop and mask files to corrsponding layer in WG tile extent####
h24v07npp<-crop(h24v07npp,(extent(as.SpatialPolygons.PolygonsList(tileextent@polygons[2]))), snap='out')

#### Create a mask for WG ####
blank<-raster(h24v07npp, layer=1)
blank<-reclassify(blank, c(-Inf,Inf,NA))
wgbound<-rasterize(as.SpatialPolygons.PolygonsList(tileextent@polygons[2]),blank,fun="first")
#plot(wgbound)
wgbound<-reclassify(wgbound, c(-Inf,Inf,1))

##Mask with WG boundary##
h24v07npp.m<-mask(h24v07npp,wgbound)

##Retain only valid data range##
h24v07npp.m[h24v07npp.m >65500]<-NA

#### Apply scale factor ####
h24v07npp.m<-h24v07npp.m*0.0001

#### Set name  ####
names(h24v07npp.m)<-(strptime(paste(substr(s1, start=2, stop=5)),
                                 format="%Y"))
h24v07npp.m<-setZ(h24v07npp.m, as.Date(strptime(paste(substr(s1, start=2, stop=5)),
                                                      format="%Y")))
#plot(h24v07npp.m)

writeRaster(h24v07npp.m,"h24v07npp_scaled.grd",overwrite=T)

#### Create Annual stack ####
yy<- function(x)as.numeric(format(x, '%Y'))
h24v07npp<-zApply(h24v07npp.m,by=yy,fun=sum,na.rm=T)
getZ(h24v07npp)
#plot(h24v07npp)

writeRaster(h24v07npp,"h24v07npp_annual.grd",overwrite=T)

#### Extract Data and save as CSV ####
nn2m <- cellsFromExtent(h24v07npp$X2000,extent(h24v07npp$X2000))
nxy<-xyFromCell(h24v07npp$X2000,nn2m)
npp.h24v07<- extract(h24v07npp,nxy, df=T)

#write.csv(npp.h24v07, "h24v07npp.annual.csv", row.names=F)

#########Extract LST for corresponding ET tile####################
lst.h24v07.a<-brick("/media/MOD11_A2/h24v07/h24v07lst_MAM_hants10.grd")
plot(lst.h24v07.a)
degC.h24v07<-extract(lst.h24v07.a, nxy, df=T)
#write.csv(degC.h24v07, "h24v07lst.annualET.csv", row.names=F)

######################Extract TRMM####################################
trmm.a<-brick("/media/trmmv73hour/trmm_annual.grd")
plot(trmm.a)
rain.h24v07<-extract(trmm.a, nxy, df=T)
#write.csv(rain.h24v07, "h24v07rain.annual.csv", row.names=F)

##Save as R objects, to be used for analysis##
save(blank,npp.h24v07,rain.h24v07,
     degC.h24v07, file="npp_h24v07.RData")
save.image("MOD17A3h24v07.RData")
rm(list=ls())
print("Finished processing tile h24v07")
#q("no")
