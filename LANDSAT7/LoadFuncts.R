##-----------Functions to be used-----------------##
   
registerDoParallel(cores=6)
## modified from <http://stackoverflow.com/a/7963963/2548841>
substrLeft <- function(x, n){
    substr(x, 0, nchar(x)-n)}
substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))}
## function to convert intern values to a dataframe
fun.int2df <- function(x){
  x1 <- t(as.data.frame(strsplit(x, ",")))
  row.names (x1) <- NULL
  colnames (x1) <- x1[1,]
  x1 <- x1[-1,]
  return(as.data.frame(x1))
}

## improved list of objects http://stackoverflow.com/questions/1358003/tricks-to-manage-the-available-memory-in-an-r-session
.ls.objects <- function (pos = 1, pattern, order.by,
                        decreasing=FALSE, head=FALSE, n=5) {
    napply <- function(names, fn) sapply(names, function(x)
                                         fn(get(x, pos = pos)))
    names <- ls(pos = pos, pattern = pattern)
    obj.class <- napply(names, function(x) as.character(class(x))[1])
    obj.mode <- napply(names, mode)
    obj.type <- ifelse(is.na(obj.class), obj.mode, obj.class)
    obj.size <- napply(names, object.size)
    obj.dim <- t(napply(names, function(x)
                        as.numeric(dim(x))[1:2]))
    vec <- is.na(obj.dim)[, 1] & (obj.type != "function")
    obj.dim[vec, 1] <- napply(names, length)[vec]
    out <- data.frame(obj.type, obj.size, obj.dim)
    names(out) <- c("Type", "Size", "Rows", "Columns")
    if (!missing(order.by))
        out <- out[order(out[[order.by]], decreasing=decreasing), ]
    if (head)
        out <- head(out, n)
    out
}
# shorthand
lsos <- function(..., n=20) {
    .ls.objects(..., order.by="Size", decreasing=TRUE, head=TRUE, n=n)
}
## function below modified from:
## http://www.r-bloggers.com/identifying-records-in-data-frame-a-that-are-not-contained-in-data-frame-b-%E2%80%93-a-comparison/
missing.imgs <- function(x.1,x.2,...){
    x.1p <- do.call("paste", as.data.frame(x.1$ID))
    x.2p <- do.call("paste", x.2)
    x.1[! x.1p %in% x.2p, ]   
}

pausenow <- function(x)
    {
            p1 <- proc.time()
                Sys.sleep(x)
                proc.time() - p1 # The cpu usage should be negligible
        }


## function to list rasters from given mapset and prefix
ndvi.exists <- function(prefix, mapset){
    x <- execGRASS("g.list",
                   parameters=list(type='raster', pattern=prefix, mapset=mapset),
                   intern=TRUE)
    if(length(x>0)){
        x <- fun.int2df(x)
        x <- as.character(x$x1)
        x <- substrRight(x, 13)
        x <- as.data.frame(x)
    } else {
        x <- NULL
    }
    x <- unique(x)
}

pet.exists <- function(prefix, mapset, stno, endno){
    x <- execGRASS("g.list",
                   parameters=list(type='raster', pattern=prefix, exclude="*cel*", mapset=mapset),
                   intern=TRUE)
    if(length(x>0)){
        x <- fun.int2df(x)
        x <- as.character(x$x1)
        x <- substring(x, stno, endno)
        x <- as.data.frame(x)
    } else {
        x <- NULL
    }
    x <- unique(x)
}
