# tidy.R

source("0-library.R")

tmp <- get_rds(dir.tidy)

# warfarin indications ----

data.warfarin.indications <- read_edw_data(dir.data, "goals", "warfarin") %>%
    semi_join(pts.include, by = "pie.id") %>%
    make_indications %>%
    group_by(pie.id) %>%
    arrange(warfarin.datetime) %>%
    summarize_each(funs(sum), -pie.id, -warfarin.datetime) %>%
    mutate_each(funs(ifelse(. > 0, TRUE, FALSE)), -pie.id)
