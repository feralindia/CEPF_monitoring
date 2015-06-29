## fix mapset

execGRASS("g.mapset", mapset='ndvi')

max.list$Year <- format(max.list$Date, "%Y")
grp <- subset(max.list, select=c(Path, Row, Year)) ## select relevant columns trim date to year
grp <- unique(grp)


## execGRASS("r.mask",
##           flags="overwrite",
##           parameters=list(vector='wg_extent@PERMANENT')
##           ) #add mask to stick to limits of WG
## execGRASS("r.mask",flags="r") #remove mask for this operation seems to be causing problems

## need to tweak the script so that it handles one region at a time while using the foreach packages- else GRASS will choke
##foreach(i=1:nrow(grp), .packages='spgrass6') %dopar% { 
for (i in 1: nrow(grp)){ # create loop to extract maximum NDVI
    ## without gap fill
    sb.grp <- subset(max.list, subset=(Path==grp$Path[i] & Row==grp$Row[i] & Year==grp$Year[i]), select=ID)
    sb.grp.id <- unique(sb.grp)
    sb.grp <- paste("toar.ndvi.", sb.grp$ID, sep="")
    max.ndvi <-  paste("max.toar.ndvi.", sb.grp.id, sep="")
    regmap <- execGRASS("g.list", flags = "e", parameters = list(type='raster', pattern=sb.grp.id$ID, exclude='(gf|max)', mapset='ndvi'), intern=TRUE)
    
    execGRASS("g.region",
              flags="p",
              parameters=list(raster=regmap[1]))
    if(length(sb.grp)>1) {
        tmp.input <- str_c(regmap,collapse=",")
        execGRASS("r.series",
                  flags=c("z", "overwrite"),
                  parameters=list(input=tmp.input, output=max.ndvi, method='maximum'))
    } else {
        cpcmd <- paste(regmap, max.ndvi, sep=",")
        execGRASS("g.copy",
                    flags="overwrite",
                    parameters=list(raster=cpcmd))
    }

    ## repeat above with gap fill FROM HERE RUN ON MAPS YR>2003
    
    ## with gap fill
    ##    sb.grp <- subset(img.list, subset=(Path==grp$Path[i] & Row==grp$Row[i] & Year==grp$Year[i]), select=ID)
    gf.sb.grp <- paste("gf.", sb.grp, sep="")
    ##gf.sb.grp <- subset(max.list, subset=(Path==grp$Path[i] & Row==grp$Row[i] & Year==grp$Year[i]), select=ID)
    
    gf.max.ndvi <-  paste("max.gf.toar.ndvi.",sb.grp.id, sep="")
    gf.regmap <- execGRASS("g.list", flags = "e", parameters = list(type='raster', pattern=gf.sb.grp[1], exclude='max', mapset='ndvi'), intern=TRUE)
    if(length(gf.regmap)>0){
        
        execGRASS("g.region", flags="p", parameters=list(raster=gf.regmap[1]))
        if(length(gf.regmap>1)){
            gf.tmp.input <- str_c(gf.regmap,collapse=",")
            execGRASS("r.series",
                      flags=c("z", "overwrite"),
                      parameters=list(input=gf.tmp.input, output=gf.max.ndvi, method='maximum'))
            
        } else {
            cpcmd <- paste(gf.regmap, gf.max.ndvi, sep=",")
            execGRASS("g.copy",
                      flags="overwrite",
                      parameters=list(raster=cpcmd))
        }
    }
}
    
##     ## from here
##     if(length(gf.sb.grp)>1) {
##         execGRASS("r.series",
##                   flags=c("z", "overwrite"),
##                   parameters=list(input=gf.tmp.input, output=gf.max.ndvi, method='maximum'))
##     } else {
##         cpcmd <- paste(gf.sb.grp, gf.max.ndvi, sep=",")
##         execGRASS("g.copy",
##                   flags="overwrite",
##                   parameters=list(raster=cpcmd[1]))
##     }
## } else {
##     cpcmd <- paste(sb.grp, gf.max.ndvi, sep=",")
##     execGRASS("g.copy",
##               flags="overwrite",
##               parameters=list(raster=cpcmd[1]))
## }
## }
        
    
