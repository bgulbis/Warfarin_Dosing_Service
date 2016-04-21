# tidy.R

source("0-library.R")

tmp <- get_rds(dir.tidy)

# data from exclude dir: warfarin goals, LFTs

raw.demographics <- read_edw_data(dir.data, "demographics")
