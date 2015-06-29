## Set mapset
execGRASS("g.mapset", mapset='pet')

avg.lst.list$Year <- format(avg.lst.list$Date, "%Y")
grp <- subset(avg.lst.list, select=c(Path, Row, Year)) ## select relevant columns trim date to year
grp <- unique(grp)

for (i in 1: nrow(grp)){ # create loop to extract average LST
    ## without gap fill
    sb.grp <- subset(avg.lst.list, subset=(Path==grp$Path[i] & Row==grp$Row[i] & Year==grp$Year[i]), select=ID)
    sb.grp.id <- unique(sb.grp)
    sb.grp <- paste("lst.", sb.grp$ID, sep="")
    avg.lst <-  paste("avg.lst", sb.grp.id, sep="")
    regmap <- execGRASS("g.list", flags = "e", parameters = list(type='raster', pattern=sb.grp.id$ID, exclude='(gf|avg|cel|ems)', mapset='pet'), intern=TRUE)
    
    execGRASS("g.region", raster=regmap[1])
    if(length(sb.grp)>1) {
        tmp.input <- str_c(regmap,collapse=",")
        execGRASS("r.series",
                  flags=c("z", "overwrite"),
                  parameters=list(input=tmp.input, output=avg.lst, method='median')) ## changed to median to avoid outliers
    } else {
        cpcmd <- paste(regmap, avg.lst, sep=",")
        execGRASS("g.copy",
                    flags="overwrite",
                    parameters=list(raster=cpcmd))
    }

    ## repeat above with gap fill
    gf.sb.grp <- paste("gf.", sb.grp, sep="")
    gf.avg.lst <-  paste("avg.gf.lst.",sb.grp.id, sep="")
    gf.regmap <- execGRASS("g.list", flags = "e", parameters = list(type='raster', pattern=gf.sb.grp[1], exclude='(avg|cel|ems)', mapset='pet'), intern=TRUE)

    if(length(gf.regmap)>0){
        
        execGRASS("g.region", raster=gf.regmap[1])
        if(length(gf.regmap>1)){
            gf.tmp.input <- str_c(gf.regmap,collapse=",")
            execGRASS("r.series",
                      flags=c("z", "overwrite"),
                      parameters=list(input=gf.tmp.input, output=gf.avg.lst, method='median'))
            
        } else {
            cpcmd <- paste(gf.regmap, gf.avg.lst, sep=",")
            execGRASS("g.copy",
                      flags="overwrite",
                      parameters=list(raster=cpcmd))
        }
    }
}
