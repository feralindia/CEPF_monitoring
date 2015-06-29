datadir <- "/home/udumbu/rsb/OngoingProjects/CEPF_monitoring/rdata/data2"
library(raster) # raster operations
library(sp) # vector operations
library(rgdal) # import and export formats
#library(doSMP) # no longer available
library(spatial.tools)
library(zyp)
rednir <- list.files(datadir, pattern="B3.tif$|B4.tif$", full.names=TRUE)
## clip to smallest region to ensure
## all files cover same extent to be fixed

## for (i in length(rednir)){
##      x <- raster(rednir[i])
##      assign(rednir[i], x)
##      extx <- names(x)
##      assign(extx, extent(x))
##  }


## function taken from spatial.tools
## manual, modified to specify the
## number of layers based on brick
rednirstk <- stack(rednir)
rednirbrk <- brick(rednirstk) # bricks work faster than stacks

### code below needs fixing, 
## nlyr <- nlayers(rednirbrk)/2
## ndvi_function <- function(x,...)
## {
##   # Note that x is received by the function as a 3-d array:
##   red_band <- x[,,1]
##   nir_band <- x[,,2]
##   ndvi <- (nir_band - red_band)/(nir_band + red_band)
##   # The output of the function should also be a 3-d array,
##   # even if it is a single band:
##   ndvi <- array(ndvi,dim=c(dim(x)[1],dim(x)[2],4))
##   return(ndvi)
## }

## sfQuickInit(cpus=4)
## lsat_ndvi <-
##     focal_hpc(x=rednirbrk,fun=ndvi_function) #focal_hpc multithreads the command
## sfQuickStop()
## ## summarise the output
## summary(lsat_ndvi)
## spplot(lsat_ndvi)



redbnds <- names(rednirbrk)[c(1,3,5,7)]
nirbnds <- names(rednirbrk)[c(2,4,6,8)]
redbnds <- subset(rednirbrk, redbnds)
nirbnds <- subset(rednirbrk, nirbnds)
ndvi <-  (nirbnds-redbnds)/(nirbnds+redbnds)
summary(ndvi)

b <- ndvi
s <- stack(ndvi)

## Get slope - from raster manual using lm - taking inordinate amounts of time
## time <- 1:nlayers(s)
## fun <- function(x) { lm(x ~ time)$coefficients[2] }
## x2 <- calc(s, fun)


## get the sen-slopes
names(b)<-c("Y1999","Y2004", "Y2009","Y2014")# these are dummy years, we need to have a ts, if years are missing it is fine,
#but it time interval has to be equal
names(b)
## get the sen-slopes
## Srini to help from here

n <- cellsFromExtent(b,extent(b))
val <- as.data.frame(extract(b,c(1:ncell(b))))
t <- as.data.frame(cbind(n,val))
head(t)
#fit trend
names(t)
trend <- zyp.trend.dataframe(t,1,"zhang",conf.intervals=TRUE)#changed prewhitening to zhang. it does not affect sen slope. the error appears to due to package kendal, we will have to confirm.
#write trends to raster
blank<-raster(b, layer=1)
#check the above step, see if anything is going wrong with the setValue command
slope <- setValues(blank, trend$trend)
slopet<- setValues(blank, trend$trendp)
sig<- setValues(blank, trend$sig)
tau<- setValues(blank, trend$tau)
image(slopet)
summary(trend)
hist(slope)
