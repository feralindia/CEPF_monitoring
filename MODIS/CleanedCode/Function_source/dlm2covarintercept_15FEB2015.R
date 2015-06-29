#This script returns the intercept and slope of a DLM with two covariates.
#The first set of columns store the intercepts, number of columns depends on the length (or timeperiod) of the
#dataset. The next set of columns stores the slopes of the first covariate and so on..
##Example of using the function: In this example Y is vegetation response for period 2002-2013.
##Columns represent months and each rows represent a pixel
##Explantory variables used are rainfall and temperature
##library(dlm)
##ndvi<-read.csv("~/ydata.csv", sep="\t")
##rain<-read.csv("~/xdata.csv", sep="\t")
##degC<-read.csv("~/xdata1.csv", sep=",")
##
##test<-dlmtwocovar(ndvi,rain,degC)
##
##ndvi.int<-test[,1:(length(test)/3)]
##rain.slp<-test[,((length(test)/3)+1):((length(test)/3)*2)]
##temp.slp<-test[,(((length(test)/3)*2)+1):(length(test))]


dlmtwocovar<- function(data,x1data,x2data){
  dataout<-matrix(-999,nrow(data), (ncol(data)-1)*3)
    s1<-(ncol(data)-1)*1
    s2<-(ncol(data)-1)*2
    s3<-(ncol(data)-1)*3

  #   samplemedian <- function(x, d) {
  #     return(median(x[d]))}#for mean replace median with mean
  for (j in 1:nrow(data)){
    ydata<-t(data[j, 2:ncol(data)])
    if (anyNA(ydata)) {dataout[j,]<-NA
    } 
    else {  
      xdata1<-t(x1data[j, 2:ncol(x1data)])
      if (anyNA(xdata1)) {dataout[j,]<-NA
      }
      else{
        xdata2<-t(x2data[j, 2:ncol(x2data)])
        if (anyNA(xdata2)) {dataout[j,]<-NA
        }
        else{
          xdata1<-t(x1data[j, 2:ncol(x1data)])
          xdata2<-t(x2data[j, 2:ncol(x2data)])
          xd1d2<-cbind(xdata1,xdata2)

          mod1<-lm(ydata~xdata1+xdata2)
          test<-summary(mod1)$coefficients
          dV=var(mod1$resid)
          dW=c(dV/10,dV/10,dV/10)
          m0<-c(test[1,1],test[2,1],test[3,1])
          C0<-c(test[1,2]^2,test[2,2]^2,test[3,2]^2)
          mod1<-dlmModReg(xd1d2,dV=dV,dW=dW,m0=m0,C0=matrix(C0,3,3,byrow=T))
          #modtimeseries<-matrix(0,(ncol(data)-1), 3)
          smoothmod<-dlmSmooth(ydata,mod1,debug=FALSE)
          smoothvar<-dlmSvd2var(smoothmod$U.S,smoothmod$D.S)
          len<-length(smoothmod$s[,1])
          dataout[j,1:s1]<- t(smoothmod$s[2:len,1])
          dataout[j,(s1+1):s2]<-t(smoothmod$s[2:len,2])
          dataout[j,(s2+1):s3]<-t(smoothmod$s[2:len,3])          
        }
      }
    }
 print(j) }
  return(as.data.frame(dataout))
}

