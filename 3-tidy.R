# tidy.R

source("0-library.R")

tmp <- get_rds(dir.tidy)

# warfarin indications ---------------------------------

data.warfarin.indications <- read_edw_data(dir.data, "goals", "warfarin") %>%
    semi_join(pts.include, by = "pie.id") %>%
    make_indications %>%
    group_by(pie.id) %>%
    arrange(warfarin.datetime) %>%
    summarize_each(funs(sum), -pie.id, -warfarin.datetime) %>%
    mutate_each(funs(ifelse(. > 0, TRUE, FALSE)), -pie.id)

# inr values -------------------------------------------

tmp.labs.coags <- read_edw_data(dir.data, "labs_coag", "labs") %>%
    semi_join(pts.include, by = "pie.id") %>%
    inner_join(data.warfarin.dates, by = "pie.id") %>%
    inner_join(data.warfarin.goals, by = "pie.id") %>%
    filter(lab == "inr",
           lab.datetime >= warf.start,
           lab.datetime <= warf.end + days(2)) %>%
    group_by(pie.id) %>%
    arrange(lab.datetime) %>%
    mutate(censored = str_detect(lab.result, ">|<"),
           lab.result = as.numeric(lab.result),
           duration = as.numeric(difftime(lab.datetime, lag(lab.datetime), units = "hours")),
           duration = ifelse(is.na(duration), 0, duration),
           run.time = as.numeric(difftime(lab.datetime, warf.start,
                                          units = "hours")))

threshold <- list(~lab.result >= goal.low, ~lab.result <= goal.high)

tmp.inr.inrange <- group_by(tmp.labs.coags, pie.id, lab) %>%
    # select(pie.id, lab, lab.result, goal.low, goal.high, run.time) %>%
    calc_perc_time(threshold, meds = FALSE)


# hgb drop ---------------------------------------------

tmp.hgb.drop <- read_edw_data(dir.data, "labs_cbc", "labs") %>%
    semi_join(pts.include, by = "pie.id") %>%
    inner_join(data.warfarin.dates, by = "pie.id") %>%
    filter(lab == "hgb",
           lab.datetime >= warf.start,
           lab.datetime <= warf.end + days(2)) %>%
    lab_change(-2, max)

data.hgb.drop <- group_by(tmp.hgb.drop, pie.id) %>%
    summarize(lab.datetime = first(lab.datetime),
              change = first(change))
