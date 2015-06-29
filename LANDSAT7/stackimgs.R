##---create image stacks based on row-path for further analysis
##-- prequel to generating the sen-slopes
execGRASS("g.mapset",
          parameters=list(mapset='ndvi'))
in.list.mpset <- execGRASS("g.mlist",
                           flags=c("m","r", "quiet"),
                           parameters=list(type='rast', mapset='ndvi', pattern='max.toar'), intern=TRUE)

in.list <- execGRASS("g.mlist",
                     flags=c("r", "quiet"),
                     parameters=list(type='rast', mapset='ndvi', pattern='max.toar'), intern=TRUE)
in.path <- substr(in.list, start=18, stop=20)
in.row <- substr(in.list, start=21, stop=23)
in.pathrow <- as.data.frame(substr(in.list, start=18, stop=23))
in.pathrow <- in.pathrow[!duplicated(in.pathrow), ]
for (i in 1:length(in.pathrow)){
    im.list <- subset(in.list, subset=(substr(in.list, start=18, stop=23)==in.pathrow[i]))
    im.onelist <- str_c(im.list,collapse=",")
    im.years <- substr(im.list, start=24, stop=27)
    execGRASS("g.region",
              flags=c("p","a"),
              parameters=list(rast=im.onelist, res='30')
              ) # set region to first image in stack. Reset resolution to desired level if required.
    for(j in 1:length(im.list)){
        rst <- paste("rst",j, sep="")
        assign(rst, raster(readRAST6(im.list[j])))
    }

    rsts <- paste("rst", 1:length(im.list), sep="")
    
    ## Start the clock!
    ptm <- proc.time()
    b <- brick(lapply(rsts, get))
    ## b <- brick(mclapply(rsts, get, mc.cores=6))
    ## Stop the clock
    proc.time() - ptm
    
    names(b) <- im.years
    sellayers <- names(b)[!is.nan(cellStats(b, mean))] # Identify layers with data
    b <- subset(b, subset=sellayers, drop=TRUE) # remove layers with NaN
    ## above would be faster if raster is dropped on formation
    ## rather than re-creating a brick.

    
## create dataframe to store the results for each ploygon
    res<-data.frame(matrix(ncol = 11, nrow = ncell(n1)))
    names(res) <- c("lbound","trend", "trendp","ubound","tau","sig","nruns","autocor","valid_frac","linear","intercept")
    ## n <- cellsFromExtent(b,extent(b))
    for (k in length(b)){
        
    

    ## the subsequent step needs to be broken into smaller chunks
    ## and then rbind used to glue them together
    ## ptm <- proc.time()
    ## val <- as.data.frame(extract(b,c(1:ncell(b))))
    ## proc.time() - ptm
    
    ## parallisation of this makes it run faster
    getval <- function(x){
        val <- as.data.frame(extract(x,c(1:ncell(x))))
        return(val)
    }
    ptm <- proc.time()
    val <- mclapply(b, getval, mc.cores = 6)
    proc.time() - ptm
## Check to see if this can be put in a mclapply loop
    
## names(res) <- c("lbound","trend", "trendp","ubound","tau","sig","nruns","autocor","valid_frac","linear","intercept")
## ## loop over polygons
## for (i in 1:length(b)) {
  
##   ext <- as.data.frame(extract(n1,extent(i),cellnumbers=TRUE))
##   #uncomment to use the polygon itself and the multicore option
##   #ext<-as.data.frame(extract(n1,b@polygons[i],cellnumbers=T))
  
##   trend <- zyp.trend.dataframe(ext,1,"zhang",conf.intervals=TRUE)
##   res<-rbind(res,trend)
##   return(res)
## }


    ##val2 <- getValuesBlock_enhanced(b, r1 = 1, r2 = nrow(b), c1 = 1, c2 = ncol(b))
     t <- as.data.frame(cbind(n,val))
    ## t1 <- as.data.frame(cbind(n,val1))
    ## t2 <- as.data.frame(cbind(n,val2))
names(t)
    ptm <- proc.time()
    trend <- zyp.trend.dataframe(t,1,"zhang",conf.intervals=TRUE)
    proc.time() - ptm

blank<-raster(b, layer=1)
#check the above step, see if anything is going wrong with the setValue command
slope <- setValues(blank, trend$trend)
slopet<- setValues(blank, trend$trendp)
sig<- setValues(blank, trend$sig)
tau<- setValues(blank, trend$tau)
image(slopet)
summary(trend)
hist(slope)
head(b)  
}
