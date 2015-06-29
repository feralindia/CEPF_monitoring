### This section calls scripts to analyse each tile ###
### Depending on the computer capability decide how many tile will be processed ###
### The analysis can be time consuming and will require a minimum of 24 gb RAM ###
### You can distribute the computing by copying the data and relevent script and run them individually on different computers ###

### h25v07 was a large tile and needed a high end desktop to process the entire tile ###
### to make processing faster and easier we preprocessed and analysed the tile in 4 chunks ###
### this allowed us to run the analysis on regular desktops and we could run the analysis parallely on 2 or more desktops ###

source("/media/MOD16_ET/h24v06/h24v06_veg_analysis.R")
source("/media/MOD16_ET/h24v07/h24v07_veg_analysis.R")
source("/media/MOD16_ET/h25v07/h25v07_veg_analysis_1.R")
source("/media/MOD16_ET/h25v07/h25v07_veg_analysis_2.R")
source("/media/MOD16_ET/h25v07/h25v07_veg_analysis_3.R")
source("/media/MOD16_ET/h25v07/h25v07_veg_analysis_4.R")
source("/media/MOD16_ET/h25v08/h25v08_veg_analysis.R")

### This section compiles all results  ###
### This analysis can be be performed on desktop or laptops with 8gb RAM ###
library(raster)
library(rgdal)
setwd("/media/MOD13_Q1/results")

#### Read Outputs ####
s1 <- list.files(pattern="grd$",)
for (i in s1){
  assign(paste(i), raster(i))}

##Mosaic tiles##
##Set resolution and projection of tiles if they are different##
h25v08_annual_ndvi_trendsig.grd<- projectRaster(h25v08_annual_ndvi_trendsig.grd, 
crs="+proj=utm +no_defs +zone=43 +a=6378137 +rf=298.257223563 +towgs84=0.000,0.000,0.000 +to_meter=1",res=250)
h25v08_annual_ndvi_trend.grd<- projectRaster(h25v08_annual_ndvi_trend.grd, 
crs="+proj=utm +no_defs +zone=43 +a=6378137 +rf=298.257223563 +towgs84=0.000,0.000,0.000 +to_meter=1",res=250)
h25v08_annualraw_ndvi_trend.grd<- projectRaster(h25v08_annualraw_ndvi_trend.grd, 
crs="+proj=utm +no_defs +zone=43 +a=6378137 +rf=298.257223563 +towgs84=0.000,0.000,0.000 +to_meter=1",res=250)
h25v08_annualraw_ndvi_trendsig.grd<- projectRaster(h25v08_annualraw_ndvi_trendsig.grd, 
crs="+proj=utm +no_defs +zone=43 +a=6378137 +rf=298.257223563 +towgs84=0.000,0.000,0.000 +to_meter=1",res=250)

### Mosaic trendsig files ###

ndvi_trend_sig<-mosaic(h24v06_annual_ndvi_trendsig.grd,h24v07_annual_ndvi_trendsig.grd,
                       h25v07_1_annual_ndvi_trendsig.grd,h25v07_2_annual_ndvi_trendsig.grd,
                       h25v07_3_annual_ndvi_trendsig.grd,h25v07_4_annual_ndvi_trendsig.grd,
                       h25v08_annual_ndvi_trendsig.grd,
                       fun=max,tolerance=1)

summary(ndvi_trend_sig)
plot(ndvi_trend_sig)

##Mosaic trend files##
ndvi_trend<-mosaic(h24v06_annual_ndvi_trend.grd,h24v07_annual_ndvi_trend.grd,
                       h25v07_1_annual_ndvi_trend.grd,h25v07_2_annual_ndvi_trend.grd,
                       h25v07_3_annual_ndvi_trend.grd,h25v07_4_annual_ndvi_trend.grd,
                       h25v08_annual_ndvi_trend.grd,
                       fun=max,tolerance=1)

plot(ndvi_trend)

##Mosaic raw_trend sig files##
ndviraw_trend_sig<-mosaic(h24v06_annualraw_ndvi_trendsig.grd,h24v07_annualraw_ndvi_trendsig.grd,h25v07_1_annualraw_ndvi_trendsig.grd,
                          h25v07_2_annualraw_ndvi_trendsig.grd,h25v07_3_annualraw_ndvi_trendsig.grd,h25v07_4_annualraw_ndvi_trendsig.grd,
                          h25v08_annualraw_ndvi_trendsig.grd,fun=max,tolerance=1)

##Mosaic raw_trend files##
ndviraw_trend<-mosaic(h24v06_annualraw_ndvi_trend.grd,h24v07_annualraw_ndvi_trend.grd,h25v07_1_annualraw_ndvi_trend.grd,
                      h25v07_2_annualraw_ndvi_trend.grd,h25v07_3_annualraw_ndvi_trend.grd,h25v07_4_annualraw_ndvi_trend.grd,
                      h25v08_annualraw_ndvi_trend.grd,fun=max,tolerance=1)

##Reclassify the values ##
ndviraw_trend_sig<-reclassify(ndviraw_trend_sig, c(-2,-1,1,1,2,1))
ndviraw_trend<-reclassify(ndviraw_trend, c(-2,-1,1,1,2,1))
plot(ndviraw_trend)
plot(ndviraw_trend_sig)

### reapplying mask ###
ndviraw_trend<-mask(ndviraw_trend,wgbound)
ndviraw_trend_sig<-mask(ndviraw_trend_sig,wgbound)
ndvi_trend<-mask(ndvi_trend,wgbound)
ndvi_trend_sig<-mask(ndvi_trend_sig,wgbound)

### Write raster for making maps in QGIS ###
setwd("/media/CEPF_MONITORING/results")

writeRaster(ndviraw_trend, "ndviraw_trend.tif", format="GTiff",datatype='FLT4S', overwrite=TRUE)
writeRaster(ndviraw_trend_sig, "ndviraw_trend_sig.tif", format="GTiff",datatype='FLT4S', overwrite=TRUE)
writeRaster(ndvi_trend, "ndvi_trend.tif", format="GTiff",datatype='FLT4S', overwrite=TRUE)
writeRaster(ndvi_trend_sig, "ndvi_trend_sig.tif", format="GTiff",datatype='FLT4S', overwrite=TRUE)

### Tabular outputs ###
freq(ndviraw_trend>0)
freq(ndviraw_trend_sig>0)
freq(ndvi_trend>0)
freq(ndvi_trend_sig>0)

### Number of Pixel analysed ###
wg<-readOGR(dsn="/media/vector/", layer="WGhats_bounds_utm")

blank<-raster(ndviraw_trend)
blank<-reclassify(blank, c(-Inf,Inf,NA))
wgbound<-rasterize(wg,blank,fun="first")
plot(wgbound)
wgbound<-reclassify(wgbound, c(-Inf,Inf,1))
freq(wgbound)
