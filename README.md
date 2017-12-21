# DFLOW_R

R function to find the design flow, such as the 7Q10, based on methodology used 
in EPA's DFLOW with a modification to account for missing flow data or days with zero flow. 
If there is missing flow data in any particular water year, all data from that water 
year is not. This approach is recommended by [EPA][1] (although not implemented in DFLOW 3.1) 
and applied in USGS's [SWSTAT][2] program.

I have double-checked that this function produces values consistent 
with DFLOW 3.1 (in cases without missing data), but there still may be areas 
of the code that need improvement. Use at your own risk.

[1]: https://www.epa.gov/waterdata/technical-support-dflow#xqy
[2]: https://water.usgs.gov/software/SWSTAT/

References:
+ https://www.epa.gov/waterdata/dflow
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

`year.start` = Optional. The year defining the start of the calculation period. 
				Should be in integer format yyyy. If not specified the 
				default will be the minimum date in x.

`year.end` = 	Optional. The year defining the end of the calculation period. 
				Should be in integer format yyyy. If not specified the 
				default will be the maximum date in x.

`wy.start` = Optional. The water year beginning date (excluding year). The date 
			 should be in character format "mm-dd". If not specified the default is "10-01".

`wy.end` = Optional. The water year ending date (excluding year). The date should be in 
		   character format "mm-dd". If not specified the default is "09-30".

If a particular season is desired, set wy.start and wy.end arguments to correspond to the beginning and ending dates of the season. The season does not have to span an entire year. Only flow records that fall within the season will be used in the calculations.

### Example

```R
require(dataRetrieval)

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