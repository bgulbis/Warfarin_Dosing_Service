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

pattern <- "Atrial fibrillation|Deep vein thrombosis|Pulmonary embolism|Heart valve \\(Mech/porc/bioprost\\)|Other:"
library(purrr)
tmp.indication <- filter(raw.goals, warfarin.event == "warfarin indication") %>%
    mutate(afib = str_detect(warfarin.result, regex("Atrial fibrillation|a(.*)?fib|a(.*)?flutter", ignore_case = TRUE)),
           dvt = str_detect(warfarin.result, regex("Deep vein thrombosis|DVT|VTE", ignore_case = TRUE)),
           pe = str_detect(warfarin.result, regex("Pulmonary embolism|PE", ignore_case = TRUE)),
           valve = str_detect(warfarin.result, regex("Heart valve \\(Mech/porc/bioprost\\)|valve|avr|mvr", ignore_case = TRUE)),
           stroke = str_detect(warfarin.result, regex("st(ro|or)ke|cva", ignore_case = TRUE)),
           vad = str_detect(warfarin.result, regex("vad|hm[ ]?ii|heart( )?mate|heartware|syncardia|total artificial heart|tah", ignore_case = TRUE)),
           thrombus = str_detect(warfarin.result, regex("(?!(Deep vein))throm|clot|(?!(pulmonary ))emboli", ignore_case = TRUE)),
           hypercoag = str_detect(warfarin.result, regex("malig|antiphos|lupus|hypercoag|deficien|leiden|fvl|factor v", ignore_case = TRUE)),
           other = ifelse(afib == FALSE & dvt == FALSE & pe == FALSE & valve == FALSE & stroke == FALSE & vad == FALSE & thrombus == FALSE & hypercoag == FALSE, TRUE, FALSE)) %>%
    dmap_at("warfarin.result", str_replace_all, pattern = pattern, replacement = "") %>%
    dmap_at("warfarin.result", str_trim, side = "both")

tmp <- filter(tmp.indication, other == TRUE)
