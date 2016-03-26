# 0-library.R

library(BGTools)
library(dplyr)
library(stringr)
library(lubridate)
library(tidyr)

patient.dir <- "patients"

gzip_files(patient.dir)
