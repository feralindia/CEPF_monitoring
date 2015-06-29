library(zoo)
library(raster)
library(zyp)

##-- modified to use gap filled images
setwd("/home/rsb/Documents/RScripts/")

source("ControlScript.R", echo=TRUE) 

execGRASS("g.mapset", mapset='ndvi')
in.list.mpset <- execGRASS("g.list",
                           flags=c("m","r", "quiet"),
                           parameters=list(type='raster', mapset='ndvi', pattern='max'), intern=TRUE)
## Pattern should allow both gf and non gf images

in.list <- execGRASS("g.list",
                     flags=c("r", "quiet"),
                     parameters=list(type='raster', mapset='ndvi', pattern='max'), intern=TRUE)
in.pathrow <- substrRight(in.list, 10)
in.pathrow <- substrLeft(in.pathrow, 4)
unique.pathrow <- in.pathrow[!duplicated(in.pathrow)]
in.path <- substrLeft(unique.pathrow, 3) ## modified for gf from start=18, stop=20
unique.path <- in.path[!duplicated(in.path)]
in.row <- substrRight(unique.pathrow, 3) ## modified for gf from start=21, stop=23
unique.row <- in.row[!duplicated(in.row)]

## AVOID USING A LOOP - THE MACHINE RUNS OUT OF MEMORY.
## NEED TO FLUSH THE MEMORY BEFORE EACH RUN
## for (i in 2:length(unique.pathrow)){ ## note that first raster is p143r53 in utm44
i <- 19
sel.pr <- unique.pathrow[i] ## changed from in.pathrow
im.list <- subset(in.list, subset=(in.pathrow==sel.pr))## modified for gf from start=18, stop=23
im.list <- im.list[order(substrRight(im.list, 4))] ## order years in sequence
## Only select gap filled data
im.list <- im.list[grep(pattern="max.gf", x=im.list)]
im.years <- substrRight(im.list, 4) ## modified for gf from start= 24, stop=27
execGRASS("g.region",
          flags=c("p"),
          parameters=list(raster=im.list[1], res='30')## FIX RESOLUTION
          ) ## set region to first image in stack. Reset resolution to desired level if required.
for(j in 1:length(im.list)){
    ## for(j in 1:4){
    rst <- paste("rst",j, sep="")
    assign(rst, raster(readRAST6(im.list[j])))
}

lyrs <- paste("rst",1:j, sep="")
brk <- brick(lapply(lyrs, get))

####---- from Srini's code

#creating a blank raster using one of the bricks, to avoid any errors while setting values#
## not required
## blank<-brick(nrows=nrow(r1), ncols=ncol(r1), xmn=xmin(r1), xmx=xmax(r1), 
##             ymn=ymin(r1), ymx=ymax(r1), nl=nlayers(r1), crs=crs(r1))
# A wrapper function to derive sen's slope (layer 1) and significant values (layer 2)

r.sen=function(x) {if (all(is.na(x))){ NA } else{
    fit<-zyp.trend.vector(x, method="yuepilon",conf.intervals=T)
    return(cbind(fit[3], fit[6]))
    }}
# Deriving a brick with the slopes and sig #
r3<-calc(brk, fun=function(x){
  res<-t(apply(x,1,r.sen))
  return(res)}
)
plot(r3)
sig<-(r3$layer.1*(r3$layer.2<0.1))
plot(sig)

