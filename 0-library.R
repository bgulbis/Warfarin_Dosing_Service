# 0-library.R

library(BGTools)
library(dplyr)
library(stringr)
library(lubridate)
library(tidyr)

source("0-dirs.R")

gzip_files(dir.patients)
# gzip_files(dir.exclude)
gzip_files(dir.data)
