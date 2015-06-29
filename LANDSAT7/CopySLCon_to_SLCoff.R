## Script to copy slc on images (mostly before 2003) to gf. images
## Basically done for NDVI calculations of pre-gf years
## Catches tiles that were missed as new images were added

execGRASS("g.mapset", mapset='ndvi')
nogf.ndvi <- execGRASS("g.list", type='raster', pattern='toar.ndvi.*', exclude='gf', mapset='ndvi', intern=T)
gf.ndvi <-  execGRASS("g.list", type='raster', pattern='gf.toar.ndvi.*', mapset='ndvi', intern=T)
gf.ndvi <-  substrRight(gf.ndvi, 31)
tmp <- nogf.ndvi[!(nogf.ndvi %in% gf.ndvi)]
tmp2002 <- subset(tmp, subset=as.numeric(substr(tmp, start=20, stop=23))<2003)
tmp2003 <- subset(tmp, subset=as.numeric(substr(tmp, start=20, stop=23))==2003)
dellist <- paste(tmp2003, "@ndvi", sep="")
 dellist <- toString(dellist)
dellist <- gsub(' ', '', dellist)
execGRASS("g.remove",  flags="f", type='raster', name=dellist)
## copy existing files to gf.toar.ndvi
tmp2002gf <- paste("gf.", tmp2002, sep="")
cpfls <- paste(tmp2002, tmp2002gf, sep=",")

cp.files <- function(x){
        execGRASS("g.copy",
                  flags="overwrite",
                  parameters=list(raster=x))
    }
lapply(cpfls, cp.files)        


dellist <- execGRASS("g.list", type='raster', pattern='*LE7143053*', mapset='ndvi', intern=T)
dellist <- toString(dellist)
dellist <- gsub(' ', '', dellist)
execGRASS("g.remove",flags="f", type='raster', name=dellist)
