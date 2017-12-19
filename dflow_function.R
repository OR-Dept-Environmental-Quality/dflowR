
dflow <- function(x, m, R, period.start=NA, period.end=NA, wy.start="10-01", wy.end="09-30") {
  
  # Function to find the design flow based on methodology used in EPA's DFLOW with a modificaton to account for missing flow data or days with zero flow.
  # If there is missing flow data in any particular water year, all data from that water year is not used.
  # DFLOW 3.1 uses the USGS A193 implementation, which may be obtained as source code from http://water.usgs.gov/software/swstat.html
  # 
  # References
  # https://www.epa.gov/waterdata/dflow
  # https://nepis.epa.gov/Exe/ZyPDF.cgi/30001JEH.PDF?Dockey=30001JEH.PDF
  #
  # x = Data frame where, 
  #       col 1 = POSIXct date
  #       col 2 = numeric daily mean flow
  # m = Flow averaging period in days
  # R = Return period in years
  # period.start = Optional. Character date defining the start of the calculation period in format "yyyy-mm-dd". Default is the minimum date in x.
  # period.end = Optional. Character date defining the end of the calculation period in format "yyyy-mm-dd". Default is the maximum date in x.
  # wy.start = Optional. Character date (excluding year) that begins the water year in format "mm-dd" Default is "10-01"
  # wy.end = Optional. Character date (excluding year) that ends the water year in format "mm-dd". Default is "09-30".
  # 
  # Ryan Michie
  # Oregon Department of Environmental Quality
  
  require(lubridate)
  require(zoo)
  require(dplyr)
  
  X <- x
  
  # Error checking
  if (!is.data.frame(X)) {
    stop("x must be a data frame.", call. = TRUE)
  }
  
  if (!any(is.POSIXct(X[,1]),is.numeric(X[,2]))) {
    stop("Data types are not correct. x[,1] must be POSIXct and x[,2] must be numeric.", call. = TRUE)
  }
  
  colnames(X) <-c("date", "flow")
  
  if (is.na(period.start)) {
    period.start <- min(X$date)
  } else {
    period.start <- as.POSIXct(period.start, format="%Y-%m-%d")
  }
  
  if (is.na(period.end)) {
    period.end <- max(X$date)
  } else {
    period.end <- as.POSIXct(period.end, format="%Y-%m-%d")
  }
  
  # Add and missing days
  date99 <- data.frame(date=as.POSIXct(format(seq(from=min(X$date),
                       to=max(X$date)+86400,by="day"), "%m/%d/%Y"),format="%m/%d/%Y"))
  
  X <- merge(date99, X, by="date")
  
  # Add year
  X$year <- year(X$date)
  
  # Add ordinal day assuming non leap year,
  X$jday <- yday(as.POSIXct(paste0("1900-",month(X$date),"-",day(X$date)), format="%Y-%m-%d"))
  
  # define water year
  X$water.year <- ifelse(X$jday >= yday(as.POSIXct(paste0(X$year,"-",wy.start, format="%Y-%m-%d"))), 
                         X$year + 1, X$year)
  
  X <- X[with(X, order(date)), ]
  
  # Calculate the m-days rolling average
  X$m.avg <- ave(X$flow, X$water.year, FUN = 
                   function(x) rollapply(zoo(x), m, mean, fill = NA, align = "left"))
  
  # filter to days only within the water year
  # start and end water year in ordinal days not accounting for leap years
  wy.start <- yday(as.POSIXct(paste0("1900","-",wy.start, format="%Y-%m-%d")))
  wy.end <- yday(as.POSIXct(paste0("1900","-",wy.end, format="%Y-%m-%d")))
  
  if (wy.start < wy.end) { 
    season <- c(wy.start:wy.end)
  } else {
      season <- c(wy.start:365, 1:wy.end)
  }
  
  # limit to dates to the period and only those in the water year
  X <- X[(X$date >= period.start & X$date <= period.end), ]
  X <- X[X$jday %in% season,]
  

  # summary of water years with missing flow data
  qc.NA <- X %>%
    group_by(water.year) %>%
    summarise(na.count = sum(is.na(flow)))
  
  # the water years to keep
  keep.wy <- unique(qc.NA[qc.NA$na.count == 0,]$water.year)
  
  # remove NAs and water years with missing flow data
  X <-X[!is.na(X$m.avg),]
  X <-X[X$water.year %in% keep.wy,]
  
  # vector of the lowest m-day rolling average flow in each water year
  Y <- X %>% select(water.year, m.avg) %>%
    group_by(water.year) %>%
    summarise(m.avg = min(m.avg, na.rm=TRUE))
  
  Y <- Y[with(Y, order(m.avg)), ]
  
  NY <- length(Y$m.avg)
  
  Y$log.m.avg <- log(Y$m.avg)
  
  # remove -Inf and NaN
  y <- Y[!(is.infinite(Y$log.m.avg) | is.na(Y$log.m.avg)),]$log.m.avg
  
  N <- length(y)
  
  U <- mean(y, na.rm=TRUE)
  S <- sd(y, na.rm=TRUE)
  G <- (N*sum((y-U)^3))/((N-1)*(N-2)*S^3)
  
  F0 <- (NY - N)/NY
  
  p <- (1/R - F0)/(1-F0)
  
  Z = 4.91 * ((p^0.14) - ((1-p)^0.14))
  
  K <- (2/G)*( (1+ (G*Z)/6- (G^2/36) )^3 - 1)
  
  d.flow <- exp(U + (K*S))
  
  return(d.flow)
  
}


