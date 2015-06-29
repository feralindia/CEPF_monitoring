## routine to call gdal_fillnodata.py on targeted folders.
## Use after toar has been done using GRASS
## Pixel width is set to 9 - see the cmd statement.

### see if this function can be made to work. Will probably speed up the gap fill
## fun.gapfill <- function(w,x,y,z,gf){
##     gunzip(z, destname=x, skip=TRUE, remove=FALSE)
##     execGRASS("r.out.gdal",
##               flags="overwrite",
##               parameters=list(input=y, output=w, format='GTiff'))

##     cmd <- paste("gdal_fillnodata.py -md 2 -mask ", x, " -of GTiff ", w, sep="") 
##     system(cmd)

##     execGRASS("r.in.gdal",
##               flags=c("o", "overwrite"),
##               parameters=list(input=w, output=gf)
##               )
## }


## Ensure mapset is PERMANENT
execGRASS("g.mapset",
          flags="c",
          parameters=list(mapset='PERMANENT'))

gapmasks.gz <- list.files(gapmaskdir, full.names=TRUE, include.dirs=FALSE, pattern="tif.gz", ignore.case=TRUE) ## z
gapmask.fn <- substrLeft(list.files(gapmaskdir, full.names=FALSE, include.dirs=FALSE, pattern="tif.gz", ignore.case=TRUE)[1],13)
pat <-"toar.dos4.B"
gapmasks <- substrLeft(gapmasks.gz, 3) ## x
gaprasts <- execGRASS("g.list", flags=c("r","m"),
                      parameters=list(type='rast', pattern=pat, exclude='gf', mapset='PERMANENT'), intern=TRUE) ## y
gaptif <- execGRASS("g.list", flags=c("r"),
                    parameters=list(type='rast', pattern=pat, exclude='gf', mapset='PERMANENT'), intern=TRUE) ## w
gapfill <- paste("gf.", gaptif, sep="") ##gf
execGRASS("g.region",
          flags=c("a"),
          parameters=list(raster=gaprasts[1])) 

foreach(p=1:length(gapfill)) %dopar% {
    gunzip(gapmasks.gz[p], destname=gapmasks[p], skip=TRUE, remove=FALSE)
    execGRASS("r.out.gdal",
              flags="overwrite",
              parameters=list(input=gaprasts[p], output=gaptif[p], format='GTiff'))
    
    cmd <- paste("gdal_fillnodata.py -md 9 -mask ", gapmasks[p], " -of GTiff ", gaptif[p], sep="") 
    system(cmd)
    
    execGRASS("r.in.gdal",
              flags=c("o", "overwrite"),
              parameters=list(input=gaptif[p], output=gapfill[p]))
}

## CREATE A TOAR.REF  FOR CLOUD ASSESSMENT
## RUN IT AGAIN ON TOAR.REF

gapmasks.gz <- list.files(gapmaskdir, full.names=TRUE, include.dirs=FALSE, pattern="tif.gz", ignore.case=TRUE) ## z
gapmask.fn <- substrLeft(list.files(gapmaskdir, full.names=FALSE, include.dirs=FALSE, pattern="tif.gz", ignore.case=TRUE)[1],13)
pat <-"toar.ref.B"
gapmasks <- substrLeft(gapmasks.gz, 3) ## x
gaprasts <- execGRASS("g.list",
                      flags=c("r","m"),
                      parameters=list(type='rast', pattern=pat, exclude='gf', mapset='PERMANENT'), intern=TRUE)
gaptif <- execGRASS("g.list", flags=c("r"),
                    parameters=list(type='rast', pattern=pat, exclude='gf', mapset='PERMANENT'), intern=TRUE)
gapfill <- paste("gf.", gaptif, sep="") ##gf

execGRASS("g.region",
          flags=c("a"),
          parameters=list(raster=gaprasts[1]))

foreach(p=1:length(gapfill)) %dopar% {
    gunzip(gapmasks.gz[p], destname=gapmasks[p], skip=TRUE, remove=FALSE)
    execGRASS("r.out.gdal",
              flags="overwrite",
              parameters=list(input=gaprasts[p], output=gaptif[p], format='GTiff'))
    
    cmd <- paste("gdal_fillnodata.py -md 9 -mask ", gapmasks[p], " -of GTiff ", gaptif[p], sep="") 
    system(cmd)
    
    execGRASS("r.in.gdal",
              flags=c("o", "overwrite"),
              parameters=list(input=gaptif[p], output=gapfill[p]))
}
