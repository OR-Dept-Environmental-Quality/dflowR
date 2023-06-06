#' Design Flow Calculation
#'
#' Function to find the design flow based on methodology used in U.S. EPA's [DFLOW program](https://www.epa.gov/ceam/dflow)
#' with a modification to account for missing flow data or days with zero flow.
#' If there are missing flow data in any particular water year, all data from that water year is not used.
#' This approach is [recommended by EPA](https://www.epa.gov/ceam/technical-support-dflow#xqy) (although not implemented in DFLOW 3.1)
#' and applied in USGS's [SWSTAT](https://water.usgs.gov/software/SWSTAT/) program.
#'
#' The methodology for this function is based on the equations contained in DFLOW user manual
#' as presented by Rossman (1999). Design flow is computed from the sample of lowest m-day
#' average flow for each defined year, where "m" is the user supplied flow averaging period.
#' The arithmetic averaging is used to calculate the m-day average flows. A log Pearson Type III
#' probability distribution is fitted to the annual minimum m-day flows. The design
#' flow is the value from the distribution whose probability of not being exceeded is 1/r where r
#' is the user-supplied return period.
#'
#' If a particular season is desired, set wystart and wyend arguments to correspond to the beginning
#' and ending dates of the season. The season does not have to span an entire year. Only flow records
#' that fall within the season will be used in the calculations.
#'
#' References:
#'
#' Rossman, L A. 1990. DFLOW USER'S MANUAL. U.S. Environmental Protection Agency,
#' Washington, DC, EPA/600/8-90/051 (NTIS 90-225616). https://nepis.epa.gov/Exe/ZyPDF.cgi/30001JEH.PDF?Dockey=30001JEH.PDF
#'
#' DFLOW: https://www.epa.gov/ceam/dflow
#'
#' @param x Data frame where col 1 = POSIXct date and col 2 = numeric daily mean flow rate
#' @param m Flow averaging period in days
#' @param r Return period in years
#' @param yearstart Optional. The starting year of the calculation period.
#' Should be in integer format as yyyy. If not specified the
#' default will be the year of the minimum date in x.
#' @param yearend Optional. The ending year of the calculation period.
#' Should be in integer format as yyyy. If not specified the
#' default will be the year of the maximum date in x.
#' @param wystart Optional. Character date (excluding year) that begins the water year in format "mm-dd".
#' Default is "10-01"
#' @param wyend Optional. Character date (excluding year) that ends the water year in format "mm-dd".
#' Default is "09-30".
#' @export
#' @return numeric design flow.


dflow <-
  function(x,
           m,
           r,
           yearstart = NA,
           yearend = NA,
           wystart = "10-01",
           wyend = "09-30") {
    # This is to use the same notation as Rossman 1990
    X <- x
    R <- r
    
    # Error checking
    if (!is.data.frame(X)) {
      stop("x must be a data frame.", call. = TRUE)
    }
    
    if (!any(lubridate::is.POSIXct(X[, 1]), is.numeric(X[, 2]))) {
      stop("Data types are not correct. x[,1] must be POSIXct and x[,2] must be numeric.",
           call. = TRUE)
    }
    
    colnames(X) <- c("date", "flow")
    
    if (is.na(yearstart)) {
      yearstart <- lubridate::year(min(X$date))
    } else {
      yearstart <- as.integer(yearstart)
    }
    
    if (is.na(yearend)) {
      yearend <- lubridate::year(max(X$date))
    } else {
      yearend <- as.integer(yearend)
    }
    
    # make a character vector of all days starting on date wystart in the year of period.start and
    # ending on date wyend + m-1 days in the year of period.end.
    # This is to identify missing days and limit data to the period.
    date99 <-
      data.frame(date2 = format(
        seq(
          from = as.POSIXct(paste0(yearstart, "-", wystart), format = "%Y-%m-%d"),
          to = as.POSIXct(paste0(yearend, "-", wyend), format =
                            "%Y-%m-%d") + (86400 * (m - 1)),
          by = "day"
        ),
        "%m/%d/%Y"
      ),
      stringsAsFactors = FALSE)
    
    X <- X[with(X, order(date)),]
    
    # character date for merging
    X$date2 <- format(X$date, "%m/%d/%Y")
    
    X <- dplyr::left_join(x = date99, y = X, by = "date2")
    
    #X <- merge(x=date99, y=X, by="date2", all.x=TRUE)
    
    # back to POSIXct
    X$date <- as.POSIXct(X$date2, format = "%m/%d/%Y")
    X$date2 <- NULL
    
    # Add year
    X$year <- lubridate::year(X$date)
    
    # Add ordinal day assuming non leap year,
    X$jday <- lubridate::yday(as.POSIXct(
      paste0(
        "1900-",
        lubridate::month(X$date),
        "-",
        lubridate::day(X$date)
      ),
      format = "%Y-%m-%d"
    ))
    
    # define water year
    X$water.year <-
      ifelse(X$jday >= lubridate::yday(as.POSIXct(
        paste0(X$year, "-", wystart, format = "%Y-%m-%d")
      )),
      X$year + 1, X$year)
    
    X <- X[with(X, order(date)),]
    
    # Calculate the m-days rolling average
    X$m.avg <-
      zoo::rollapply(zoo::zoo(X$flow), m, mean, fill = NA, align = "left")
    
    # filter to days only within the water year
    # start and end water year in ordinal days not accounting for leap years
    wystart <-
      lubridate::yday(as.POSIXct(paste0("1900", "-", wystart, format = "%Y-%m-%d")))
    wyend <-
      lubridate::yday(as.POSIXct(paste0("1900", "-", wyend, format = "%Y-%m-%d")))
    
    if (wystart < wyend) {
      season <- c(wystart:wyend)
    } else {
      season <- c(wystart:365, 1:wyend)
    }
    
    # limit to dates in the water year season
    X <- X[X$jday %in% season, ]
    
    # summary of water years with missing flow data
    qc.NA <- X %>%
      dplyr::select(water.year, m.avg) %>%
      dplyr::group_by(water.year) %>%
      dplyr::summarise(na.count = sum(is.na(m.avg)))
    
    # the water years to keep
    keep.wy <- unique(qc.NA[qc.NA$na.count == 0, ]$water.year)
    
    # remove NAs and water years with missing flow data
    X <- X[!is.na(X$m.avg), ]
    X <- X[X$water.year %in% keep.wy, ]
    
    # vector of the lowest m-day rolling average flow in each water year
    Y <- X %>%
      dplyr::select(water.year, m.avg) %>%
      dplyr::group_by(water.year) %>%
      dplyr::summarise(m.avg = min(m.avg, na.rm = TRUE))
    
    Y <- Y[with(Y, order(m.avg)),]
    
    NY <- length(Y$m.avg)
    
    Y$log.m.avg <- log(Y$m.avg)
    
    # remove zero or negative flows (-Inf and NaN)
    y <-
      Y[!(is.infinite(Y$log.m.avg) | is.na(Y$log.m.avg)), ]$log.m.avg
    
    N <- length(y)
    
    U <- mean(y, na.rm = TRUE)
    S <- stats::sd(y, na.rm = TRUE)
    G <- (N * sum((y - U) ^ 3)) / ((N - 1) * (N - 2) * S ^ 3)
    
    F0 <- (NY - N) / NY
    
    p <- (1 / R - F0) / (1 - F0)
    
    Z = 4.91 * ((p ^ 0.14) - ((1 - p) ^ 0.14))
    
    K <- (2 / G) * ((1 + (G * Z) / 6 - (G ^ 2 / 36)) ^ 3 - 1)
    
    d.flow <- exp(U + (K * S))
    
    return(d.flow)
    
  }
