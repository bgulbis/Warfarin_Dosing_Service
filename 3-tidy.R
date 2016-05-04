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
