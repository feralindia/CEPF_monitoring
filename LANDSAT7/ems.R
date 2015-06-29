## Set mapset
execGRASS("g.mapset", mapset='pet')

## first calculate emissivity for each scene using NDVI

for(i in 1:nrow(ems.list)){
    src.ndvi <- paste("toar.ndvi.", ems.list$ID[i], "@ndvi", sep="")
    out.ems <- paste("ems.", ems.list$ID[i], "@pet", sep="")
    execGRASS("g.region", raster=src.ndvi)
    execGRASS("i.emissivity", flags=c("overwrite"),
              parameters=list(input=src.ndvi, output=out.ems))
    src.ndvi <- paste("gf.toar.ndvi.", ems.list$ID[i], sep="")
    ## get available gapfilled ndvi rasters
    pat.ndvi <- paste("gf.toar.ndvi*", format(ems.list$Date[i], "%Y"), "*", sep="")
    gf.ndvi.list <- execGRASS("g.list", parameters=list(type='raster',
                                            pattern=pat.ndvi, mapset='ndvi'), intern=TRUE)
    out.gf.ems <- paste("gf.ems.", ems.list$ID[i], sep="")
    if (src.ndvi %in% gf.ndvi.list){
        execGRASS("i.emissivity", flags=c("overwrite"),
                  parameters=list(input=src.ndvi, output=out.gf.ems))
    } else {
## create another if statement which prevents copying over existing files
        execGRASS("g.copy", flags="overwrite", raster=paste(out.ems,out.gf.ems, sep=","))
    }
    print(paste("Emissivity map:", ems.list$ID[i], "generated.", sep=" "))
}
