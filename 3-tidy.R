# tidy.R

source("0-library.R")

tmp <- get_rds(dir.tidy)

# inr ranges ----

raw.goals <- read_edw_data(dir.data, "goals", "warfarin") %>%
    semi_join(pts.include, by = "pie.id")

tmp.goals.inr <- make_inr_ranges(raw.goals) %>%
    filter(!is.na(goal.low),
           !is.na(goal.high)) %>%
    group_by(pie.id) %>%
    arrange(warfarin.datetime)

tmp.indications <- make_indications(raw.goals)
