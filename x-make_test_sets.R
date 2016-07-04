
library(dplyr)
library(stringr)
library(lubridate)
library(readr)
library(edwr)

dir.sample <- "sample"
rnum <- sample.int(100000, 1)
rdays <- sample.int(15, 1)

# labs <- read_data("data", "labs_coag", "skip")
#
# test.censor <- labs %>%
#     filter(str_detect(`Clinical Event Result`, ">|<")) %>%
#     sample_n(5)
#
# test <- labs %>%
#     sample_n(10)
#
# if(!file.exists("sample/patients.Rds")) {
#     pts.sample <- bind_rows(test, test.censor) %>%
#
#         distinct(`PowerInsight Encounter Id`)
#
#     saveRDS(pts.sample, "sample/patients.Rds")
# } else {
#     pts.sample <- readRDS("sample/patients.Rds")
# }

test.d <- read_data(dir.sample, "demographics", "skip") %>%
    # filter(`PowerInsight Encounter Id` %in% pts.sample$`PowerInsight Encounter Id`) %>%
    mutate(
        `PowerInsight Encounter Id` = as.character(
            as.numeric(`PowerInsight Encounter Id`) + rnum),
        `Person ID` = as.character(as.numeric(`Person ID`) + rnum),
        `Person Location- Facility (Curr)` = "Hospital"
    )

test.labs <- read_data(dir.sample, "labs") %>%
    mutate(pie.id = as.character(as.numeric(pie.id) + rnum),
           lab.datetime = lab.datetime + days(rdays))

test.diag <- read_data(dir.sample, "diagnosis") %>%
    mutate(pie.id = as.character(as.numeric(pie.id) + rnum))

test.meds.home <- read_data(dir.sample, "meds_home") %>%
    mutate(pie.id = as.character(as.numeric(pie.id) + rnum))

test.meds.cont <- read_data(dir.sample, "meds_cont") %>%
    mutate(pie.id = as.character(as.numeric(pie.id) + rnum),
           order.id = as.character(as.numeric(order.id) + rnum),
           event.id = as.character(as.numeric(event.id) + rnum),
           med.datetime = med.datetime + days(rdays))

test.meds.sched <- read_data(dir.sample, "meds_sched") %>%
    mutate(pie.id = as.character(as.numeric(pie.id) + rnum),
           order.id = as.character(as.numeric(order.id) + rnum),
           event.id = as.character(as.numeric(event.id) + rnum),
           med.datetime = med.datetime + days(rdays))

test.warf <- read_data(dir.sample, "warfarin") %>%
    mutate(pie.id = as.character(as.numeric(pie.id) + rnum),
           warfarin.datetime = warfarin.datetime + days(rdays))


dir <- "../edwr/data-raw/"
write_csv(test.d, "../edwr/inst/extdata/test_demographics.csv")
write_csv(test.labs, paste0(dir, "test_labs.csv"))
write_csv(test.diag, paste0(dir, "test_diag.csv"))
write_csv(test.meds.home, paste0(dir, "test_meds_home.csv"))
write_csv(test.meds.cont, paste0(dir, "test_meds_cont.csv"))
write_csv(test.meds.sched, paste0(dir, "test_meds_sched.csv"))
write_csv(test.warf, paste0(dir, "test_warf.csv"))

# BGTools::concat_encounters(pts.sample$`PowerInsight Encounter Id`)
