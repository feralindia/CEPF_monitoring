#This script returns the intercept and slope of a DLM single covariate.
dlmonecovar<- function(data,xdata){
  dataout<-matrix(-999,nrow(data), (ncol(data)-1)*2)
  for (j in 1:nrow(data)){
    ydata<-t(data[j, 2:ncol(data)])
    if (all(is.na(ydata))) {dataout[j,]<-NA
    } 
    else {  
      xdata1<-t(xdata[j, 2:ncol(xdata)])
      if (all(is.na(xdata1))) {dataout[j,]<-NA
      }
      else{
        xdata1<-t(xdata[j, 2:ncol(xdata)])   
        mod1<-lm(ydata~xdata1)
        test<-summary(mod1)$coefficients
        dV=var(mod1$resid)
        dW=c(dV/10,dV/10)
        m0<-c(test[1,1],test[2,1])
        C0<-c(test[1,2]^2,test[2,2]^2)
        mod1<-dlmModReg(xdata1,dV=dV,dW=dW,m0=m0,C0=matrix(C0,2,2,byrow=T))
        modtimeseries<-matrix(0,ncol(data)-1, 2)
        smoothmod<-dlmSmooth(ydata,mod1)
        smoothvar<-dlmSvd2var(smoothmod$U.S,smoothmod$D.S)
        len<-length(smoothmod$s[,1])
        dataout[j,1:(ncol(data)-1)]<- t(smoothmod$s[2:len,1])
        dataout[j,(ncol(data)):(2*((ncol(data)-1)))]<- t(smoothmod$s[2:len,2])
      }
    }
 print(j) }
  return(as.data.frame(dataout))
}
