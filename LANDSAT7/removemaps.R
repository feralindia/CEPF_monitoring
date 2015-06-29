## script lists files by date for deletion or modification
## here its removing all files older than specified date
library(spgrass6)

allmaps <- list.files(path="/grassdata/wghats/l7corrected/fcell", full.names=TRUE)
maps2remove <- (file.info(list.files(path="/grassdata/wghats/l7corrected/fcell", full.names=TRUE)))
maps2remove$filename <- rownames(maps2remove)
rownames(maps2remove) <- NULL
removemaps <- (subset(maps2remove, subset=mtime > "2015-01-10 00:00:00 IST", select=filename))
execGRASS("g.mapset", mapset='l7corrected')
for(i in 1:nrow(removemaps)){
    tmp <- substr(removemaps[i,], start=37, stop=100)
    execGRASS("g.remove", flags="f", type='raster', name=tmp)
}
rm(tmp)
