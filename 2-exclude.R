# exclude.R

source("0-library.R")

tmp <- get_rds(dir.tidy)

pts.exclude <- list(Screen = nrow(pts.screen))
pts.include <- pts.screen

# dti/doac ----
# exclude if concurent DTI or DOAC given
excl.dti <- read_edw_data(dir.data, "^dti", "meds_continuous") %>%
    inner_join(data.warfarin.dates, by = "pie.id") %>%
    filter(med.datetime >= warf.start,
           med.datetime <= warf.end) %>%
    distinct(pie.id)

pts.exclude$Concurrent_DTIs <- nrow(excl.dti)

pts.include <- anti_join(pts.include, excl.dti, by = "pie.id")

excl.doac <- read_edw_data(dir.data, "^doac", "meds_sched") %>%
    semi_join(pts.include, by = "pie.id") %>%
    inner_join(data.warfarin.dates, by = "pie.id") %>%
    filter(med.datetime >= warf.start,
           med.datetime <= warf.end) %>%
    distinct(pie.id)

pts.exclude$Concurrent_DOAcs <- nrow(excl.doac)

pts.include <- anti_join(pts.include, excl.doac, by = "pie.id")

# lfts ----
# exclude if elevated LFTs: t.bili > 5.4; ast > 185 + alt > 430; alt > 860
raw.lfts <- read_edw_data(dir.data, "labs_lfts", "labs") %>%
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

pts.exclude$Elevated_LFTs <- nrow(excl.lfts)

pts.include <- anti_join(pts.include, excl.lfts, by = "pie.id")

# inr goal ----
# exclude patients without an INR goal
raw.goals <- read_edw_data(dir.data, "goals", "warfarin") %>%
    semi_join(pts.include, by = "pie.id") %>%
    filter(warfarin.event == "inr range")

excl.goals <- anti_join(pts.include, raw.goals, by = "pie.id")

pts.exclude$Missing_INR_Goals <- nrow(excl.goals)

pts.include <- anti_join(pts.include, excl.goals, by = "pie.id")

# baseline inr ----
# remove if baseline INR is > 1.5; must be within 48 hours of warfarin
tmp.inrs <- read_edw_data(dir.data, "labs_coag", "labs") %>%
    semi_join(pts.include, by = "pie.id") %>%
    filter(lab == "inr") %>%
    group_by(pie.id) %>%
    arrange(lab.datetime) %>%
    inner_join(data.warfarin.dates, by = "pie.id") %>%
    filter(lab.datetime < warf.start) %>%
    mutate(inr.time = as.numeric(difftime(lab.datetime, warf.start, units = "days"))) %>%
    summarize(inr.baseline = last(lab.result),
              inr.time = last(inr.time))

excl.inr <- tmp.inrs %>%
    filter(inr.time < -2 | inr.baseline > 1.5)

pts.exclude$Elevated_Baseline_INR <- nrow(excl.inr)

pts.include <- anti_join(pts.include, excl.inr, by = "pie.id")

# make groups ----
raw.consults <- read_edw_data(dir.data, "consults", "orders") %>%
    semi_join(pts.include, by = "pie.id")

pts.consults <- semi_join(pts.include, raw.consults, by = "pie.id")
pts.control <- anti_join(pts.include, raw.consults, by = "pie.id")

# find when consult started in relation to warfarin start
# remove patients who were consulted > 2 days after warfarin was started
tmp.consults <- raw.consults %>%
    filter(!str_detect(order, regex("(hold|discontinue)", ignore_case = TRUE))) %>%
    group_by(pie.id) %>%
    arrange(order.datetime) %>%
    summarize(consult.start = first(order.datetime)) %>%
    inner_join(data.warfarin.dates, by = "pie.id") %>%
    mutate(start.days = as.numeric(difftime(consult.start, warf.start, units = "days"))) %>%
    filter(start.days <= 2)

excl.mult.groups <- anti_join(pts.consults, tmp.consults, by = "pie.id")

pts.exclude$Changed_Groups <- nrow(excl.mult.groups)

pts.consults <- semi_join(pts.consults, tmp.consults, by = "pie.id")

pts.include <- anti_join(pts.include, excl.mult.groups, by = "pie.id") %>%
    select(pie.id) %>%
    mutate(group = ifelse(pie.id %in% pts.consults$pie.id, "pharmacy", "traditional"))

pts.exclude$Included <- nrow(pts.include)
pts.exclude$Pharmacy <- nrow(pts.consults)
pts.exclude$Traditional <- nrow(pts.control)

# save data ----
save_rds(dir.tidy, "pts")

edw.pie <- concat_encounters(pts.include$pie.id, 750)
print(edw.pie)
