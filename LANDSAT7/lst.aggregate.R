## Group by year for aggregations
lst.list$Year <- format(avg.list$Date, "%Y")
grp <- subset(lst.list, select=c(Path, Row, Year)) ## select relevant columns trim date to year
grp <- unique(grp)
for (i in 1: nrow(grp)){
    sb.grp <- subset(avg.list, subset=(Path==grp$Path[i] & Row==grp$Row[i] & Year==grp$Year[i]), select=ID)
    sb.grp.id <- unique(sb.grp)
    sb.grp <- paste("toar.ndvi.", sb.grp$ID, sep="")
    avg.ndvi <-  paste("avg.toar.ndvi", sb.grp.id, sep="")
    regmap <- execGRASS("g.list", flags = "e", parameters = list(type='raster', pattern=sb.grp.id$ID, exclude='(gf|avg)', mapset='ndvi'), intern=TRUE)
    
    execGRASS("g.region",
              flags="p",
              parameters=list(raster=regmap[1]))
    if(length(sb.grp)>1) {
        tmp.input <- str_c(regmap,collapse=",")
        execGRASS("r.series",
                  flags=c("z", "overwrite"),
                  parameters=list(input=tmp.input, output=avg.ndvi, method='average'))
    } else {
        cpcmd <- paste(regmap, avg.ndvi, sep=",")
        execGRASS("g.copy",
                    flags="overwrite",
                    parameters=list(raster=cpcmd))
    }

    gf.sb.grp <- paste("gf.", sb.grp, sep="")
    gf.avg.ndvi <-  paste("avg.gf.toar.ndvi.",sb.grp.id, sep="")
    gf.regmap <- execGRASS("g.list", flags = "e", parameters = list(type='raster', pattern=gf.sb.grp[1], exclude='avg', mapset='ndvi'), intern=TRUE)
    if(length(gf.regmap)>0){
        
        execGRASS("g.region", flags="p", parameters=list(raster=gf.regmap[1]))
        if(length(gf.regmap>1)){
            gf.tmp.input <- str_c(gf.regmap,collapse=",")
            execGRASS("r.series",
                      flags=c("z", "overwrite"),
                      parameters=list(input=gf.tmp.input, output=gf.avg.ndvi, method='average'))
            
        } else {
            cpcmd <- paste(gf.regmap, gf.avg.ndvi, sep=",")
            execGRASS("g.copy",
                      flags="overwrite",
                      parameters=list(raster=cpcmd))
        }
    }
}
