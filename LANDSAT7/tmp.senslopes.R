#load libraries
library(raster)
library(doSMP)
w <- startWorkers(4)
     registerDoSMP(w)
#set working dir
setwd("/media/FreeAgent GoFlex Drive/adityajoshi/veg")
#create file list in dir
a<-list.files("/media/FreeAgent GoFlex Drive/adityajoshi/veg", pattern="[ST]",ignore.case = TRUE)
a

library(rgdal)
#read files

for (i in a){
		x<-raster(i)
                assign(i, x)}
imgs<-ls(,pattern="rst")
imgs
s <- stack(imgs)

plot(s)
#Extract no of cells to vector
n<-cellsFromExtent(s,extent(s))
#check single cell 100
extract(s,100)
summary(s)
#create dataframe from stack

val<-as.data.frame(extract(s,c(1:ncell(s))))
t<-as.data.frame(cbind(n,val))
head(t)
#fit trend
library(zyp)
names(t)
trend<-zyp.trend.dataframe(t,1,"yuepilon",conf.intervals=TRUE)
#write trends to raster
blank<-raster(s, layer=1)
#check the above step, see if anything is going wrong with the setValue command
slope <- setValues(blank, trend$trend)
slopet<- setValues(blank, trend$trendp)
sig<- setValues(blank, trend$sig)
tau<- setValues(blank, trend$tau)
image(slopet)
summary(trend)
hist(slope)
# write trend to hdd
if (require(rgdal)) {
       writeRaster(slope, filename="adi_veg_slope.tif", format="GTiff",NAflag=-9999,overwrite=TRUE)
     }
if (require(rgdal)) {
       writeRaster(slopet, filename="adi_veg_slopet.tif",format="GTiff",NAflag=-9999,overwrite=TRUE)
     }
if (require(rgdal)) {
       writeRaster(sig, filename="adi_veg_sig.tif",format="GTiff",NAflag=-9999,overwrite=TRUE)
     }
if (require(rgdal)) {
       writeRaster(tau, filename="adi_veg_tau.tif",format="GTiff",NAflag=-9999,overwrite=TRUE)
     }

