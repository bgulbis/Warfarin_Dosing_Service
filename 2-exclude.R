# exclude.R

source("0-library.R")

tmp <- get_rds(dir.tidy)

excl <- list()
pts.include <- pts.screen

# exclude if concurent DTI or DOAC given
excl.dti <- read_edw_data(dir.exclude, "dti", "meds_continuous") %>%
    inner_join(data.warfarin.dates, by = "pie.id") %>%
    filter(med.datetime >= warf.start,
           med.datetime <= warf.end) %>%
    distinct(pie.id)

excl$Concurrent_DTIs <- nrow(excl.dti)

pts.include <- anti_join(pts.include, excl.dti, by = "pie.id")

excl.doac <- read_edw_data(dir.exclude, "doac", "meds_sched") %>%
    semi_join(pts.include, by = "pie.id") %>%
    inner_join(data.warfarin.dates, by = "pie.id") %>%
    filter(med.datetime >= warf.start,
           med.datetime <= warf.end) %>%
    distinct(pie.id)

excl$Concurrent_DOAcs <- nrow(excl.doac)

pts.include <- anti_join(pts.include, excl.doac, by = "pie.id")

# exclude if elevated LFTs: t.bili > 5.4; ast > 185 + alt > 430; alt > 860
raw.lfts <- read_edw_data(dir.exclude, "labs_lfts", "labs") %>%
    semi_join(pts.include, by = "pie.id") %>%
    inner_join(data.warfarin.dates, by = "pie.id") %>%
    filter(lab.datetime >= warf.start - days(2),
           lab.datetime <= warf.end) %>%
    mutate(result.high = str_detect(lab.result, ">"),
           result.low = str_detect(lab.result, "<"),
           lab.result = as.numeric(lab.result))

tmp.lfts.tbili.alt <- raw.lfts %>%
    filter((lab == "bili total" & (lab.result > 5.4 | result.high == TRUE)) |
               (lab == "alt" & (lab.result > 860 | result.high == TRUE))) %>%
    distinct(pie.id)

tmp.lfts.ast.alt <- raw.lfts %>%
    filter((lab == "ast" & (lab.result > 185 | result.high == TRUE)) |
           (lab == "alt" & (lab.result > 430 | result.high == TRUE))) %>%
    mutate(lab.result = ifelse(is.na(lab.result) & result.high == TRUE, 1000, lab.result)) %>%
    distinct(pie.id, lab.datetime, lab) %>%
    group_by(pie.id, lab.datetime) %>%
    select(pie.id:lab.result) %>%
    spread(lab, lab.result) %>%
    filter(ast > 185,
           alt > 430) %>%
    distinct(pie.id)

excl.lfts <- bind_rows(tmp.lfts.tbili.alt, tmp.lfts.ast.alt) %>%
    distinct(pie.id)

excl$Elevated_LFTs <- nrow(excl.lfts)

pts.include <- anti_join(pts.include, excl.lfts, by = "pie.id")

# exclude patients without an INR goal
raw.goals <- read_edw_data(dir.exclude, "goals", "warfarin") %>%
    semi_join(pts.include, by = "pie.id") %>%
    filter(warfarin.event == "inr range")

excl.goals <- anti_join(pts.include, raw.goals, by = "pie.id")

excl$Missing_INR_Goals <- nrow(excl.goals)

pts.include <- anti_join(pts.include, excl.goals, by = "pie.id")

save_rds(dir.tidy, "excl$")
save_rds(dir.tidy, "pts.include")

edw.pie <- concat_encounters(pts.include$pie.id, 750)
print(edw.pie)
