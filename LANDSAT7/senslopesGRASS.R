
## Pull in the ndvi files in the relevant GRASS mapset into a stack and brick
## ndvi.list <- execGRASS("g.mlist",
##                      flags=c("m","r", "quiet"),
##                      parameters=list(type='rast', mapset='ndvi', exclude='toar'), intern=TRUE)
## ndvi.names <- execGRASS("g.mlist",
##                      flags=c("r", "quiet"),
##                      parameters=list(type='rast', mapset='ndvi', exclude='toar'), intern=TRUE)
toar.ndvi.list <- execGRASS("g.mlist",
                     flags=c("m","r", "quiet"),
                     parameters=list(type='rast', mapset='ndvi', pattern='max.toar'), intern=TRUE)
toar.ndvi.names <- execGRASS("g.mlist",
                     flags=c("r", "quiet"),
                     parameters=list(type='rast', mapset='ndvi', pattern='max.toar'), intern=TRUE)

## this is temporary - to test

execGRASS("g.region",
              flags="p",
              parameters=list(res='1000'))
s <- stack(readRAST6(ndvi.names))
b <- brick(readRAST6(ndvi.names))
names(b)
## Get slope - from raster manual using lm - taking inordinate amounts of time
## time <- 1:nlayers(s)
## fun <- function(x) { lm(x ~ time)$coefficients[2] }
##---- need to push this to the lscorr script-------
## x2 <- calc(s, fun)
## get image dates
## img.dts <- data.frame(img=character(0), dt=numeric(0))
## for (i in 1: length(ndvi.list)){
## dt <- execGRASS("i.landsat.toar",
##               flags="p",
##               parameters=list(input_prefix='B', output_prefix='toar.B', metfile=metfl, lsatmet='date'), intern=TRUE)
## img <- substrRight(ndvi.names[i], 21)
## dts <- substrRight(dt, 10)
## img.dt <- c(img, dts)
## img.dts <- rbind(img.dts, img.dt)
## }
## names(img.dts) <- c("scene", "date")

## get the sen-slopes
names(b)<-paste("Y", {1:10}, sep="")# these are dummy years, we need to have a ts, if years are missing it is fine,
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
trend <- zyp.trend.dataframe(t,1,"zhang",conf.intervals=TRUE)
##changed prewhitening to zhang. it does not affect sen slope. the error appears to due to package kendal, we will have to confirm.
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


## To do
## Get new script for slopes from Srini
## Get multithreading working
