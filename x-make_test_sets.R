
library(dplyr)
library(stringr)
library(lubridate)
library(readr)
library(edwr)

rnum <- sample.int(100000, 1)
rdays <- sample.int(15, 1)

labs <- read_data("data", "labs_coag", "skip")

test.censor <- labs %>%
    filter(str_detect(`Clinical Event Result`, ">|<")) %>%
    sample_n(5)

test <- labs %>%
    sample_n(10)

pts.sample <- bind_rows(test, test.censor) %>%
    distinct(`PowerInsight Encounter Id`)

test <- read_data("data", "demographics", "skip") %>%
    filter(`PowerInsight Encounter Id` %in% pts.sample$`PowerInsight Encounter Id`) %>%
    mutate(
        `PowerInsight Encounter Id` = as.character(
            as.numeric(`PowerInsight Encounter Id`) + rnum),
        `Person ID` = as.character(as.numeric(`Person ID`) + rnum),
        `Person Location- Facility (Curr)` = "Hospital"
    )


test <- labs %>%
    filter(`PowerInsight Encounter Id` %in% pts.sample$`PowerInsight Encounter Id`) %>%
    mutate(
        `PowerInsight Encounter Id` = as.character(
            as.numeric(`PowerInsight Encounter Id`) + rnum),
        `Clinical Event End Date/Time` = format(
            ymd_hms(`Clinical Event End Date/Time`) + days(rdays),
            format = "%Y/%m/%d %H:%M:%S")
    )

dir <- "../edwr/data-raw/"
write_csv(test, "../edwr/inst/extdata/test_demographics.csv")
write_csv(test, paste0(dir, "test_labs.csv"))
