### This section calls scripts to analyse each tile ###
### Depending on the computer capability decide how many tile will be processed ###
### The analysis can be time consuming and will require a minimum of 24 gb RAM ###
### You can distribute the computing by copying the data and relevent script and run them individually on different computers ###
### You can also run multiple instances of R to process individual tiles if you have a high end desktop, ###
### to do so uncomment the last line in each of the source files ###
source("/media/MOD16_A2/h24v06/h24v06_BW_analysis.R")
source("/media/MOD16_A2/h24v07/h24v07_BW_analysis.R")
source("/media/MOD16_A2/h25v07/h25v07_BW_analysis.R")
source("/media/MOD16_A2/h25v08/h25v08_BW_analysis.R")

### This section compiles all results  ###
### This analysis can be be performed on desktop or laptops with 8gb RAM ###
library(raster)
library(rgdal)
setwd("/media/MOD16_A2/results")

##Read and mosaic trendpDLM files across all tiles##
s1 <- list.files(pattern="grd$",)
for (i in s1){
  assign(paste(i), raster(i))}

### Before mosaicing the tiles check resolution ###
### MOD16A2 has a spatial resolution of 1000m ###
res(h24v06_bw_yearlytrendpDLM.grd)
### Check all tiles ###
### If resolution has changed due to reprojection ###
### set it to 1000m, you cannot mosaic tiles of different resolution ###
h24v06_bw_yearlytrendpDLM.grd<- projectRaster(h24v06_bw_yearlytrendpDLM.grd, 
                                                crs="+proj=utm +no_defs +zone=43 +a=6378137 +rf=298.257223563 +towgs84=0.000,0.000,0.000 +to_meter=1",res=1000)

## Mosaic DLM Trends ##
wg.et.trends<-mosaic(h24v06_bw_yearlytrendpDLM.grd,h24v07_bw_yearlytrendpDLM.grd,
                     h25v07_bw_yearlytrendpDLM.grd,h25v08_bw_yearlytrendpDLM.grd,
                     fun=max,tolerance=1)
##Assign NA for the values -Inf##
wg.et.trends[wg.et.trends==-Inf]<-NA
plot(wg.et.trends)

## Mosaic significant DLM Trends ##

wg.et.trends.sig<-mosaic(h24v06_bw_yearlytrendpDLM_sig.grd,h24v07_bw_yearlytrendpDLM_sig.grd,
                     h25v07_bw_yearlytrendpDLM_sig.grd,h25v08_bw_yearlytrendpDLM_sig.grd,
                     fun=max,tolerance=1)

##Assign NA for the values -Inf##
wg.et.trends.sig[wg.et.trends.sig==-Inf]<-NA
plot(wg.et.trends.sig)

##mosaic raw trends ##
wg.et.raw.trends<-mosaic(h24v06_bw_yearlytrendp.grd,h24v07_bw_yearlytrendp.grd,
                         h25v07_bw_yearlytrendp.grd,h25v08_bw_yearlytrendp.grd,
                         fun=max,tolerance=1)

##Assign NA for the values -Inf##
wg.et.raw.trends[wg.et.raw.trends==-Inf]<-NA
plot(wg.et.raw.trends)

##mosaic significant raw trends ##
wg.et.raw.trends.sig<-mosaic(h24v06_bw_yearlytrendp_sig.grd,h24v07_bw_yearlytrendp_sig.grd,
                         h25v07_bw_yearlytrendp_sig.grd,h25v08_bw_yearlytrendp_sig.grd,
                         fun=max,tolerance=1)

##Assign NA for the values -Inf##
wg.et.raw.trends.sig[wg.et.raw.trends.sig==-Inf]<-NA
plot(wg.et.raw.trends.sig)

### Write raster for making maps in QGIS ###
setwd("/media/CEPF_MONITORING/results")

writeRaster(wg.et.trends, "wg_blue_trends.tif", format="GTiff", datatype='FLT4S',overwrite=T)
writeRaster(wg.et.raw.trends, "wg_blue_raw_trends.tif", format="GTiff", datatype='FLT4S',overwrite=T)
writeRaster(wg.et.trends.sig, "wg_blue_trends_sig.tif", format="GTiff", datatype='FLT4S',overwrite=T)
writeRaster(wg.et.raw.trends.sig, "wg_blue_raw_trends_sig.tif", format="GTiff", datatype='FLT4S',overwrite=T)

###Statistics for reporting ####
freq(wg.et.raw.trends>0)
freq(wg.et.raw.trends.sig>0)
freq(wg.et.trends>0)
freq(wg.et.trends.sig>0)

###Check how many pixels in WG###
tileextent<-readOGR(dsn="/media/vector/", layer="WGhats_bounds_utm")

##Set blank##
blank<-raster(wg.et.raw.trends)
blank<-reclassify(blank, c(-Inf,Inf,NA))
wgbound<-rasterize(tileextent,blank,fun="first")
plot(wgbound)
wgbound<-reclassify(wgbound, c(-Inf,Inf,1))
freq(wgbound)
