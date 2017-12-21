

source("dflow_function.R")

#--- DFLOW examples using USGS text files included w/ DFLOW 3.1 download ------------------------------------------------------

# Example 1
q.df  <- read.table(file= "C:/Program Files (x86)/DFLOW 3.1b/usgs02072000.txt", header = TRUE, sep ="\t", 
                    skip=29, stringsAsFactors=FALSE )
q <- q.df[,c(3,4)]
colnames(q) <-c("date", "flow")
q$date <- as.POSIXct(q$date, format="%m/%d/%Y")

dflow(x=q, m=7, R=10, year.start=NA, year.end=NA, wy.start="10-01", wy.end="09-30")

# Example 2
q.df  <- read.table(file= "C:/Program Files (x86)/DFLOW 3.1b/usgs02072500.txt", header = TRUE, sep ="\t", 
                    skip=29, stringsAsFactors=FALSE )
q <- q.df[,c(3,4)]
colnames(q) <-c("date", "flow")
q$date <- as.POSIXct(q$date, format="%m/%d/%Y")

dflow(x=q, m=7, R=10, year.start=NA, year.end=NA, wy.start="10-01", wy.end="09-30")

# Example 3
q.df  <- read.table(file= "C:/Program Files (x86)/DFLOW 3.1b/usgs02078000.txt", header = TRUE, sep ="\t", 
                    skip=29, stringsAsFactors=FALSE )
q <- q.df[,c(3,4)]
colnames(q) <-c("date", "flow")
q$date <- as.POSIXct(q$date, format="%m/%d/%Y")

dflow(x=q, m=7, R=10, year.start=NA, year.end=NA, wy.start="10-01", wy.end="09-30")

#--- USGS web download example ------------------------------------------------------------------------------------

require(dataRetrieval)

# download
q.df <- readNWISdv(siteNumbers = "14174000",
                   parameterCd = "00060",
                   startDate = "1970-10-01",
                   endDate = "2016-09-30",
                   statCd = "00003")

# Just get columns 3 and 4 (date and flow)
q <- q.df[,c(3,4)]
colnames(q) <-c("date", "flow")

q$date <- as.POSIXct(q$date, format="%Y-%m-%d")

dflow(x=q, m=7, R=10, year.start=NA, year.end=NA, wy.start="10-01", wy.end="09-30")

#--- OWRD web download example ------------------------------------------------------------------------------------

require(RCurl)

stationID <- "14120000"
start.date <- "10/1/1897"
end.date <- "9/30/2016"
data.type <- "MDF" # Mean Daily Flow

# create download url
d.url <- paste0("http://apps.wrd.state.or.us/apps/sw/hydro_near_real_time/hydro_download.aspx?",
                "station_nbr=",stationID,
                "&start_date=",start.date,"%2012:00:00%20AM",
                "&end_date=",end.date,"%2012:00:00%20AM",
                "&dataset=",data.type,
                "&format=tab")


url.content <- getURL(d.url)

q.df <- read.table(file=textConnection(url.content), header = TRUE, sep ="\t", 
                   skip=0, stringsAsFactors=FALSE )

# get columns 2 and 3 (date and flow)
q <- q.df[,c(2,3)]

colnames(q) <-c("date", "flow")
q$date <- as.POSIXct(q$date, format="%m-%d-%Y")

dflow(x=q, m=7, R=10, year.start=NA, year.end=NA, wy.start="10-01", wy.end="09-30")
