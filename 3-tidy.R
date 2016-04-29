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

tmp.indication <- filter(raw.goals, warfarin.event == "warfarin indication") %>%
    mutate(afib = str_detect(warfarin.result, "Atrial fibrillation"),
           dvt = str_detect(warfarin.result, "Deep vein thrombosis"),
           pe = str_detect(warfarin.result, "Pulmonary embolism"),
           valve = str_detect(warfarin.result, "Heart valve \\(Mech/porc/bioprost\\)"),
           other = str_detect(warfarin.result, "Other:"))

tmp <- filter(tmp.indication, other == TRUE)
