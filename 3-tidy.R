# tidy.R

source("0-library.R")

tmp <- get_rds(dir.tidy)

# demographics -----------------------------------------

data.demographics <- read_edw_data(dir.data, "demographics") %>%
    semi_join(pts.include, by = "pie.id") %>%
    distinct(pie.id)

data.visits <- read_edw_data(dir.data, "visits") %>%
    semi_join(pts.include, by = "pie.id")

# new therapy ------------------------------------------

# get new / previous data from anticoagulation goals
tmp.new <- read_edw_data(dir.data, "goals", "warfarin") %>%
    semi_join(pts.include, by = "pie.id") %>%
    filter(warfarin.event == "warfarin therapy") %>%
    group_by(pie.id) %>%
    summarize(warfarin.result = last(warfarin.result))

raw.meds.home <- read_edw_data(dir.data, "meds_outpt", "home_meds") %>%
    semi_join(pts.include, by = "pie.id") %>%
    filter(med.type == "Recorded / Home Meds")

# get patients with home anticoagulant
anticoag <- c("warfarin", "dabigatran", "rivaroxaban", "apixaban", "edoxaban")
tmp.home.anticoag <- filter(raw.meds.home, med %in% anticoag) %>%
    mutate(home.med = ifelse(med == "warfarin", "warfarin", "doac")) %>%
    select(pie.id, home.med) %>%
    group_by(pie.id) %>%
    arrange(desc(home.med)) %>%
    distinct

# find patients with ICD code for chronic anticoag
# icd9: V58.61; icd10: Z79.01
# tmp.anticoag.icd <- edwr::read_edw_data(dir.data, "diagnosis") %>%
#     filter((code.source == "ICD-9-CM" & diag.code == "V58.61") |
#                (code.source == "ICD-10-CM" & diag.code == "Z79.01")) %>%
#     select(pie.id, diag.code) %>%
#     distinct

raw.labs.inrs <- read_edw_data(dir.data, "labs_coag", "labs") %>%
    semi_join(pts.include, by = "pie.id") %>%
    tidy_data("labs")

tmp.inr <- raw.labs.inrs %>%
    filter(lab == "inr") %>%
    group_by(pie.id) %>%
    arrange(lab.datetime) %>%
    summarize(inr.first = first(lab.result))

data.new <- full_join(tmp.inr, tmp.new, by = "pie.id") %>%
    full_join(tmp.home.anticoag, by = "pie.id") %>%
    # full_join(tmp.anticoag.icd, by = "pie.id") %>%
    mutate(therapy = check_new(warfarin.result, home.med, inr.first)) %>%
    select(pie.id, therapy)

# warfarin indications ---------------------------------

data.warfarin.indications <- read_edw_data(dir.data, "goals", "warfarin") %>%
    semi_join(pts.include, by = "pie.id") %>%
    make_indications %>%
    group_by(pie.id) %>%
    arrange(warfarin.datetime) %>%
    summarize_each(funs(sum), -pie.id, -warfarin.datetime) %>%
    mutate_each(funs(ifelse(. > 0, TRUE, FALSE)), -pie.id)

# inr values -------------------------------------------

data.labs.inrs <- raw.labs.inrs %>%
    inner_join(data.warfarin.dates, by = "pie.id") %>%
    rename(lab.start = warf.start) %>%
    inner_join(data.warfarin.goals, by = "pie.id") %>%
    filter(lab == "inr",
           lab.datetime >= lab.start - days(2),
           lab.datetime <= warf.end + days(2)) %>%
    group_by(pie.id) %>%
    arrange(lab.datetime)


threshold <- list(~lab.result >= goal.low, ~lab.result <= goal.high)

data.inr.inrange <- filter(data.labs.inrs, lab.datetime >= lab.start) %>%
    calc_lab_runtime %>%
    group_by(pie.id, lab) %>%
    calc_perc_time(threshold, meds = FALSE)

threshold <- list(~lab.result >= 4)

data.inr.supratx <- filter(data.labs.inrs, lab.datetime >= lab.start) %>%
    calc_lab_runtime %>%
    group_by(pie.id, lab) %>%
    calc_perc_time(threshold, meds = FALSE)

# warfarin doses ---------------------------------------

data.meds <- read_edw_data(dir.data, "meds_sched") %>%
    semi_join(pts.include, by = "pie.id")

tmp.warf <- filter(data.meds, med == "warfarin") %>%
    mutate(dose.date = floor_date(med.datetime, unit = "day")) %>%
    group_by(pie.id, dose.date) %>%
    summarize(med.dose = sum(med.dose))

# hgb drop ---------------------------------------------

data.labs.hgb <- read_edw_data(dir.data, "labs_cbc", "labs") %>%
    semi_join(pts.include, by = "pie.id") %>%
    tidy_data("labs") %>%
    inner_join(data.warfarin.dates, by = "pie.id") %>%
    rename(lab.start = warf.start) %>%
    filter(lab == "hgb",
           lab.datetime >= lab.start - days(2),
           lab.datetime <= warf.end + days(2)) %>%
    group_by(pie.id) %>%
    arrange(lab.datetime)

tmp.hgb.drop <- filter(data.labs.hgb, lab.datetime >= lab.start) %>%
    lab_change(-2, max)

data.hgb.drop <- group_by(tmp.hgb.drop, pie.id) %>%
    summarize(lab.datetime = first(lab.datetime),
              change = first(change))

# bleeding ---------------------------------------------

library(icd)
library(readr)

# find patients with ICD codes for bleeding
raw.diag <- edwr::read_edw_data(dir.data, "diagnosis") %>%
    semi_join(pts.include, by = "pie.id")

# fix codes which are categorized incorrectly
# tmp.diag <- filter(raw.diag, code.source == "ICD-10-CM") %>%
#     icd10_filter_invalid(icd_name = "diag.code") %>%
#     mutate(code.source == "ICD-9-CM")


tmp.icd9 <- filter(raw.diag, code.source == "ICD-9-CM") %>%
    icd9_filter_valid(icd_name = "diag.code")

tmp.icd10 <- filter(raw.diag, code.source == "ICD-10-CM") %>%
    icd10_filter_valid(icd_name = "diag.code")

bleed.major <- read_csv("icd_bleed_major.csv", col_types = "ccc")
bleed.minor <- read_csv("icd_bleed_minor.csv", col_types = "ccc")

tmp.bleed.icd9 <- list(major9 = bleed.major$icd9,
                 minor9 = bleed.minor$icd9)

tmp.bleed9 <- icd9_comorbid(tmp.icd9, tmp.bleed.icd9, visit_name = "pie.id",
                            icd_name = "diag.code") %>%
    icd_comorbid_mat_to_df("pie.id", stringsAsFactors = FALSE)

tmp.bleed.icd10 <- list(major10 = bleed.major$icd10,
                  minor10 = bleed.minor$icd10)

tmp.bleed10 <- icd10_comorbid(tmp.icd10, tmp.bleed.icd10, visit_name = "pie.id",
                              icd_name = "diag.code") %>%
    icd_comorbid_mat_to_df("pie.id", stringsAsFactors = FALSE)

data.bleed <- full_join(tmp.bleed9, tmp.bleed10, by = "pie.id") %>%
    group_by(pie.id) %>%
    mutate(major = ifelse(sum(major9, major10, na.rm = TRUE) >= 1, TRUE, FALSE),
           minor = ifelse(sum(minor9, minor10, na.rm = TRUE) >= 1, TRUE, FALSE)) %>%
    select(pie.id, major, minor)

# body mass index --------------------------------------

raw.measures <- read_edw_data(dir.data, "measures") %>%
    semi_join(pts.include, by = "pie.id")

tmp.height <- raw.measures %>%
    filter(measure == "Height",
           measure.units == "cm") %>%
    group_by(pie.id) %>%
    arrange(measure.datetime) %>%
    summarize(height = last(measure.result))

tmp.weight <- raw.measures %>%
    filter(measure == "Weight",
           measure.units == "kg") %>%
    group_by(pie.id) %>%
    arrange(measure.datetime) %>%
    summarize(weight = last(measure.result))

data.measures <- full_join(tmp.height, tmp.weight, by = "pie.id") %>%
    mutate(bmi = weight / (height / 100)^2)

# save data --------------------------------------------

save_rds(dir.tidy, "data")


