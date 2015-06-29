## ----- identify folders with missing images and data
mapdir <- "/maps2/western_ghats/"
dir.name <- list.dirs("/maps2/western_ghats", recursive=FALSE)
for (i in 1:length(dir.name)){
    subdir.name <- paste(dir.name[i], sep="")
    subsubdir.name <- list.dirs(subdir.name, full.names=FALSE,recursive=FALSE)
    subsubdir.full.name <- list.dirs(subdir.name, full.names=TRUE, recursive=FALSE)
    error.file <- paste(wd, "folderlist/errors.csv", sep="") # removed missing files/folders
    for (j in 1:length(subsubdir.name)){
        file.numbers <- length(list.files(subsubdir.full.name[j]))
        to.paste <- paste(subsubdir.full.name[j], file.numbers, sep=", ")
        if (file.numbers<12){write.table(to.paste, file=error.file, row.names=FALSE, col.names=FALSE, append=TRUE)}
    }
}
