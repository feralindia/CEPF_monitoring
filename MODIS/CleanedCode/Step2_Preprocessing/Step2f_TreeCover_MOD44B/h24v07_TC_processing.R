library(raster)
library(rgdal)
library(zoo)
#### Set working directory ####
setwd("/media/MOD44_B/h24v07/")
#### Read trcov Data ####
s1 <- list.files(pattern="Percent")
s2 <- list.files(pattern="Quality")
#### Read WG boundary and tile info ####
tileextent<-readOGR(dsn="/media/vector/", layer="wg_tile_extent_TC")
## Check polygon corresponding to tile ##
tileextent@data
#### Create a list of layers and brick them ####
h24v07trcov<-stack(s1)
h24v07pr<-stack(s2)
#### Crop and mask files to WG ####
h24v07trcov<-crop(h24v07trcov,(extent(as.SpatialPolygons.PolygonsList(tileextent@polygons[2]))))
h24v07pr<-crop(h24v07pr,(extent(as.SpatialPolygons.PolygonsList(tileextent@polygons[2]))))
#### Create a mask for WG ####
blank<-raster(h24v07trcov, layer=1)
wgbound<-rasterize(as.SpatialPolygons.PolygonsList(tileextent@polygons[2]),blank,fun="first")
#plot(wgbound)
wgbound<-reclassify(wgbound, c(-Inf,Inf,1))
# utmz43<-"+proj=utm +zone=43 +datum=WGS84 +units=m +no_defs"
# # latlong<-"+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
# # 
# wgbound<- projectRaster(blank, crs=utmz43)

h24v07trcov.m<-mask(h24v07trcov,wgbound)
h24v07pr.m<-mask(h24v07pr,wgbound)

h24v07trcov.m[h24v07trcov.m>=200]<-NA
#### Read QC data and check for bad pixels ####
beginCluster()
m<- c(28,32,NA,60,64,NA,92,96,NA,124,128,NA,156,160,NA,188,192,NA,220,224,NA,252,256,NA)
m <- matrix(m, ncol=3, byrow=TRUE)
## clusterR(h24v07pr.m, reclassify, args=list(rcl=m),filename="h24v07pr_m.grd",datatype='FLT4S',overwrite=T) use this if you want to save the layer
m<-clusterR(h24v07pr.m, reclassify, args=list(rcl=m))
m[m>=0]<-1
endCluster()
#### Remove bad pixels ####
h24v07trcov.m<- mask(h24v07trcov.m, m)
#h24v07trcov.m<-h24v07trcov.m*m

#### Set names and setZ ####
names(h24v07trcov.m)<-(strptime(paste(substr(s1, start=2, stop=5), substr(s1, start=6, stop=8)),
                                format="%Y %j"))
h24v07trcov.m<-setZ(h24v07trcov.m, as.Date(strptime(paste(substr(s1, start=2, stop=5), substr(s1, start=6, stop=8)),
                                                    format="%Y %j")))
writeRaster(h24v07trcov.m,"h24v07trcov_masked.grd",datatype='FLT4S',overwrite=T)

#### Extract trcov to dataframe ####
nn2m <- cellsFromExtent(h24v07trcov.m,extent(h24v07trcov.m))
system.time(h24v07trcov.m.df<-as.data.frame(h24v07trcov.m))
h24v07trcov.m.df<- as.data.frame(cbind(nn2m,h24v07trcov.m.df))
#write.csv(h24v07trcov.m.df, "h24v07trcov.csv", row.names=F)

##Save as R objects, to be used for analysis##
save(h24v07trcov.m.df,
     blank, file="TC_h24v07.RData")
save.image("MOD44Bh24v07.RData")
rm(list=ls())
print("Finished processing tile h24v07")
#q("no")

