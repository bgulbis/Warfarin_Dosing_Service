# 0-library.R

library(BGTools)
library(dplyr)
library(stringr)
library(lubridate)
library(tidyr)
library(tibble)
library(purrr)

source("0-dirs.R")

gzip_files(dir.patients)
# gzip_files(dir.exclude)
gzip_files(dir.data)


#' Determine if patient is new to warfarin therapy
#'
#' @param therapy Character vector indicating new / previous therapy from
#'   anticoagulation goals in EMR
#' @param med Character vector indicating use of either warfarin or DOACs at
#'   home
#' @param inr Numeric vector indicating first INR value during hospitalization
#'
#' @return Character vector
#' @export
check_new <- function(therapy, med, inr) {
    map_chr(seq_along(therapy), function(i) {
        x <- therapy[[i]]
        x[med[[i]] == "warfarin" | (inr[[i]] >= 1.7 & is.na(med[[i]]))] <- "Previous"
        x[is.na(x) & inr[[i]] < 1.7] <- "New"
        x
    }
    )
}

