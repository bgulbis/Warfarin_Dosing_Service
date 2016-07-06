
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

x <- read_data(dir.sample, "labs")
test.labs <- x %>%
    filter(lab %in% c("hgb", "platelet", "wbc", "inr", "ptt")) %>%
    mutate(pie.id = as.character(as.numeric(pie.id) + rnum),
           lab.datetime = lab.datetime + days(rdays))
class(test.labs) <- class(x)

x <- read_data(dir.sample, "diagnosis")
test.diag <- x %>%
    mutate(pie.id = as.character(as.numeric(pie.id) + rnum))
class(test.diag) <- class(x)

x <- read_data(dir.sample, "meds_home")
test.meds.home <- x %>%
    mutate(pie.id = as.character(as.numeric(pie.id) + rnum))
class(test.meds.home) <- class(x)

med.sample <- read_data(dir.sample, "meds_cont") %>%
    filter(med == "heparin") %>%
    distinct(pie.id) %>%
    sample_n(3)

x <- read_data(dir.sample, "meds_cont")
test.meds.cont <- x %>%
    filter(pie.id %in% med.sample$pie.id) %>%
    mutate(pie.id = as.character(as.numeric(pie.id) + rnum),
           order.id = as.character(as.numeric(order.id) + rnum),
           event.id = as.character(as.numeric(event.id) + rnum),
           med.datetime = med.datetime + days(rdays))
class(test.meds.cont) <- class(x)

x <- read_data(dir.sample, "meds_sched")
test.meds.sched <- x %>%
    filter(pie.id %in% med.sample$pie.id) %>%
    mutate(pie.id = as.character(as.numeric(pie.id) + rnum),
           order.id = as.character(as.numeric(order.id) + rnum),
           event.id = as.character(as.numeric(event.id) + rnum),
           med.datetime = med.datetime + days(rdays))
class(test.meds.sched) <- class(x)

x <- read_data(dir.sample, "warfarin")
test.warf <- x %>%
    mutate(pie.id = as.character(as.numeric(pie.id) + rnum),
           warfarin.datetime = warfarin.datetime + days(rdays))
class(test.warf) <- class(x)

dir <- "../edwr/data-raw/"
write_csv(test.d, "../edwr/inst/extdata/test_demographics.csv")
saveRDS(test.labs, paste0(dir, "test_labs.Rds"))
saveRDS(test.diag, paste0(dir, "test_diag.Rds"))
saveRDS(test.meds.home, paste0(dir, "test_meds_home.Rds"))
saveRDS(test.meds.cont, paste0(dir, "test_meds_cont.Rds"))
saveRDS(test.meds.sched, paste0(dir, "test_meds_sched.Rds"))
saveRDS(test.warf, paste0(dir, "test_warf.Rds"))

rm(rnum, rdays)
# BGTools::concat_encounters(pts.sample$`PowerInsight Encounter Id`)
