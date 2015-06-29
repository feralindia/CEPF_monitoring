library(raster) # raster operations
library(spatial.tools)
library(zyp)

## Pull in the ndvi files in the relevant GRASS mapset into a stack and brick
ndvilst <- execGRASS("g.mlist",
                     flags=c("m", "quiet"),
                     parameters=list(type='rast', mapset='ndvi'), intern=TRUE)
ndv <- readRAST6(ndvilst)
b <- ndv
s <- stack(ndv)

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
