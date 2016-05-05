# tidy.R

source("0-library.R")

tmp <- get_rds(dir.tidy)

# demographics -----------------------------------------

data.demographics <- read_edw_data(dir.data, "demographics") %>%
    semi_join(pts.include, by = "pie.id") %>%
    distinct(pie.id)

data.visits <- read_edw_data(dir.data, "visits") %>%
    semi_join(pts.include, by = "pie.id")

# warfarin indications ---------------------------------

data.warfarin.indications <- read_edw_data(dir.data, "goals", "warfarin") %>%
    semi_join(pts.include, by = "pie.id") %>%
    make_indications %>%
    group_by(pie.id) %>%
    arrange(warfarin.datetime) %>%
    summarize_each(funs(sum), -pie.id, -warfarin.datetime) %>%
    mutate_each(funs(ifelse(. > 0, TRUE, FALSE)), -pie.id)

# inr values -------------------------------------------

data.labs.inrs <- read_edw_data(dir.data, "labs_coag", "labs") %>%
    semi_join(pts.include, by = "pie.id") %>%
    tidy_data("labs") %>%
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

# save data --------------------------------------------

save_rds(dir.tidy, "data")


