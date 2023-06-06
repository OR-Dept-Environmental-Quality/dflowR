# dflowR

A R package to find the design flow based on methodology used in U.S. EPA's [DFLOW program][1]
with a modification to account for missing flow data or days with zero flow. 
If there are missing flow data in any particular water year, all data from that water year is not used. 
This approach is [recommended by EPA][2] (although not implemented in DFLOW 3.1) 
and applied in USGS's [SWSTAT][3] program. 

The methodology is based on the equations contained in the DFLOW user manual 
as presented by Rossman (1999). Design flow is computed from the sample of lowest m-day
average flow for each defined year, where "m" is the user supplied flow averaging period.
The arithmetic averaging is used to calculate the m-day average flows. A log Pearson Type III
probability distribution is fitted to the annual minimum m-day flows. The design
flow is the value from the distribution whose probability of not being exceeded is 1/r where r
is the user-supplied return period.

This function produces values consistent  with DFLOW 3.1 (in cases without missing data), 
but there still may be areas  of the code that need improvement. Use at your own risk.

References:

Rossman, L A. 1990. DFLOW USER'S MANUAL. U.S. Environmental Protection Agency, 
Washington, DC, EPA/600/8-90/051 (NTIS 90-225616) https://nepis.epa.gov/Exe/ZyPDF.cgi/30001JEH.PDF?Dockey=30001JEH.PDF

[1]: https://www.epa.gov/ceam/dflow
[2]: https://www.epa.gov/ceam/technical-support-dflow#xqy
[3]: https://water.usgs.gov/software/SWSTAT/

## Install

```R
devtools::install_github("OR-Dept-Environmental-Quality/dflowR"", 
                         host = "https://api.github.com", 
                         dependencies = TRUE, force = TRUE, upgrade = "never")
```

## Usage

```R
dflow(x, m, r, yearstart, yearend, wystart, wyend)
```

`x` = A data frame object where,
	col 1 = POSIXct date,
	col 2 = daily mean flow (numeric format)

`m` = Flow averaging period in days

`r` = Return period in years

`yearstart` = Optional. The starting year of the calculation period. 
				Should be in integer format as yyyy. If not specified the 
				default will be the year of the minimum date in x.

`yearend` = 	Optional. The ending year of the calculation period. 
				Should be in integer format as yyyy. If not specified the 
				default will be the year of the maximum date in x.

`wystart` = Optional. The water year beginning date (excluding year). The date 
			 should be in character format "mm-dd". If not specified the default is "10-01".

`wyend` = Optional. The water year ending date (excluding year). The date should be in 
		   character format "mm-dd". If not specified the default is "09-30".

If a particular season is desired, set `wystart` and `wyend` arguments to correspond to the beginning and ending dates of the season. The season does not have to span an entire year. Only flow records that fall within the season will be used in the calculations.

## Example

See `dflow_example.R` for more examples.

```R

library(dataRetrieval)
library(dflowr)

# -- Example using USGS text files included w/ DFLOW 3.1 download ----

q.df  <- read.table(file= "C:/Program Files (x86)/DFLOW 3.1b/usgs02072000.txt",
                    header = TRUE, sep = "\t", skip = 29, 
                    stringsAsFactors = FALSE )
q <- q.df[, c(3,4)]
colnames(q) <- c("date", "flow")
q$date <- as.POSIXct(q$date, format = "%m/%d/%Y")

dflow(x=q, m=7, r=10, yearstart=NA, yearend=NA, wystart="10-01", wyend="09-30")

# -- USGS web download example ----

# download flow data
q.df <- readNWISdv(siteNumbers = "14174000",
                   parameterCd = "00060",
                   startDate = "1970-10-01",
                   endDate = "2016-09-30",
                   statCd = "00003")

# Just get columns 3 and 4 (date and flow)
q <- q.df[, c(3,4)]
colnames(q) <- c("date", "flow")
q$date <- as.POSIXct(q$date, format = "%Y-%m-%d", tz = "UTC")

dflow(x = q, m = 7, r = 10, yearstart = NA, yearend = NA, 
wystart = "10-01", wyend = "09-30")
```