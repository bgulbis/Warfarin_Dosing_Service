# tidy.R

source("0-library.R")

tmp <- get_rds(dir.tidy)

# inr ranges ----

raw.goals <- read_edw_data(dir.data, "goals", "warfarin") %>%
    semi_join(pts.include, by = "pie.id")

tmp.goals.inr <- make_inr_ranges(raw.goals) %>%
    group_by(pie.id) %>%
    arrange(warfarin.datetime)


tmp <- tmp.goals.inr %>%
    filter(warfarin.result != "") %>%
    dmap_at("warfarin.result", str_replace_all, pattern = regex("(INR|Goal)|-\\.|\\(.*\\)|=", ignore_case = TRUE), replacement = "") %>%
    dmap_at("warfarin.result", str_replace_all, pattern = regex("above|greater( than)?", ignore_case = TRUE), replacement = ">") %>%
    dmap_at("warfarin.result", str_replace_all, pattern = "\\.\\.", replacement = ".") %>%
    dmap_at("warfarin.result", str_replace_all, pattern = "--|to|/", replacement = "-") %>%
    dmap_at("warfarin.result", str_replace_all, pattern = "[0-9\\.]+( )[0-9\\.]+", replacement = "-") %>%
    dmap_at("warfarin.result", str_replace_all, pattern = "[1-9\\.]+([0])[1-9\\.]+", replacement = "-") %>%
    extract(warfarin.result, c("goal.low", "goal.high"), "([0-9\\.]+ ?)-( ?[0-9\\.]+)", remove = FALSE, convert = TRUE) %>%
    mutate(temp.result = as.numeric(warfarin.result),
           goal.low = ifelse(str_detect(warfarin.result, ">"), str_replace(warfarin.result, ">", ""), goal.low),
           goal.high = ifelse(str_detect(warfarin.result, ">"), as.character(as.numeric(goal.low) + 1), goal.high),
           goal.low = ifelse(is.na(goal.low) & temp.result >= 2, temp.result - 0.5, goal.low),
           goal.high = ifelse(is.na(goal.high) & temp.result >= 2, temp.result + 0.5, goal.high),
           goal.low = ifelse(is.na(goal.low) & temp.result >= 1.5 & temp.result < 2, "1.5", goal.low),
           goal.high = ifelse(is.na(goal.high) & temp.result >= 1.5 & temp.result < 2, "2", goal.high)) %>%
    # dmap_at(c("goal.low", "goal.high"), as.numeric) %>%
    filter(!is.na(goal.low),
           !is.na(goal.high)) %>%
    select(-warfarin.result, -temp.result)
