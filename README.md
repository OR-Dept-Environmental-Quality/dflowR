# DFLOW_R

R function to find the design flow, such as the 7Q10, based on methodology used 
in EPA's DFLOW with a modification to account for missing flow data or days with zero flow. 
If there are missing flow data in any particular water year, all data from that water 
year is not used. This approach is [recommended by EPA][1] (although not implemented in DFLOW 3.1) 
and applied in USGS's [SWSTAT][2] program.

I have double-checked that this function produces values consistent 
with DFLOW 3.1 (in cases without missing data), but there still may be areas 
of the code that need improvement. Use at your own risk.

[1]: https://www.epa.gov/ceam/technical-support-dflow#xqy
[2]: https://water.usgs.gov/software/SWSTAT/

References:
+ https://www.epa.gov/ceam/dflow
+ https://nepis.epa.gov/Exe/ZyPDF.cgi/30001JEH.PDF?Dockey=30001JEH.PDF

## Usage

```R
dflow(x, m, r, year.start, year.end, wy.start, wy.end)
```

`x` = A data frame object where,
	col 1 = POSIXct date,
	col 2 = daily mean flow (numeric format)

`m` = Flow averaging period in days

`R` = Return period in years

`year.start` = Optional. The starting year of the calculation period. 
				Should be in integer format as yyyy. If not specified the 
				default will be the year of the minimum date in x.

`year.end` = 	Optional. The ending year of the calculation period. 
				Should be in integer format as yyyy. If not specified the 
				default will be the year of the maximum date in x.

`wy.start` = Optional. The water year beginning date (excluding year). The date 
			 should be in character format "mm-dd". If not specified the default is "10-01".

`wy.end` = Optional. The water year ending date (excluding year). The date should be in 
		   character format "mm-dd". If not specified the default is "09-30".

If a particular season is desired, set wy.start and wy.end arguments to correspond to the beginning and ending dates of the season. The season does not have to span an entire year. Only flow records that fall within the season will be used in the calculations.

### Example

```R

library(dataRetrieval)
source("dflow_function.R")

# -- Example using USGS text files included w/ DFLOW 3.1 download ----

q.df  <- read.table(file= "C:/Program Files (x86)/DFLOW 3.1b/usgs02072000.txt", header = TRUE, sep ="\t", 
                    skip=29, stringsAsFactors=FALSE )
q <- q.df[,c(3,4)]
colnames(q) <-c("date", "flow")
q$date <- as.POSIXct(q$date, format="%m/%d/%Y")

dflow(x=q, m=7, R=10, year.start=NA, year.end=NA, wy.start="10-01", wy.end="09-30")

# -- USGS web download example ----

# download flow data
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
```