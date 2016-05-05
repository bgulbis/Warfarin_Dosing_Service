# exclude.R

source("0-library.R")

tmp <- get_rds(dir.tidy)

pts.exclude <- list(Screen = pts.screen$pie.id)
pts.include <- pts.screen

# dti/doac ---------------------------------------------
# exclude if concurent DTI or DOAC given
excl.dti <- read_edw_data(dir.data, "^dti", "meds_continuous") %>%
    inner_join(data.warfarin.dates, by = "pie.id") %>%
    filter(med.datetime >= warf.start,
           med.datetime <= warf.end) %>%
    distinct(pie.id)

pts.exclude$Concurrent_DTIs <- excl.dti$pie.id

pts.include <- anti_join(pts.include, excl.dti, by = "pie.id")

excl.doac <- read_edw_data(dir.data, "^doac", "meds_sched") %>%
    semi_join(pts.include, by = "pie.id") %>%
    inner_join(data.warfarin.dates, by = "pie.id") %>%
    filter(med.datetime >= warf.start,
           med.datetime <= warf.end) %>%
    distinct(pie.id)

pts.exclude$Concurrent_DOAcs <- excl.doac$pie.id

pts.include <- anti_join(pts.include, excl.doac, by = "pie.id")

# lfts -------------------------------------------------
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
    mutate(lab.result = ifelse(is.na(lab.result) & result.high == TRUE,
                               1000, lab.result)) %>%
    distinct(pie.id, lab.datetime, lab) %>%
    group_by(pie.id, lab.datetime) %>%
    select(pie.id:lab.result) %>%
    spread(lab, lab.result) %>%
    filter(ast > 185,
           alt > 430) %>%
    distinct(pie.id)

excl.lfts <- bind_rows(tmp.lfts.tbili.alt, tmp.lfts.ast.alt) %>%
    distinct(pie.id)

pts.exclude$Elevated_LFTs <- excl.lfts$pie.id

pts.include <- anti_join(pts.include, excl.lfts, by = "pie.id")

# inr goal ---------------------------------------------
# exclude patients without an INR goal
data.warfarin.goals <- read_edw_data(dir.data, "goals", "warfarin") %>%
    semi_join(pts.include, by = "pie.id") %>%
    make_inr_ranges %>%
    filter(!is.na(goal.low),
           !is.na(goal.high)) %>%
    group_by(pie.id) %>%
    arrange(warfarin.datetime) %>%
    summarize(goal.low = last(goal.low),
              goal.high = last(goal.high))

excl.goals <- anti_join(pts.include, data.warfarin.goals, by = "pie.id")

pts.exclude$Missing_INR_Goals <- excl.goals$pie.id

pts.include <- anti_join(pts.include, excl.goals, by = "pie.id")

# baseline inr -----------------------------------------
# remove if baseline INR is > 1.5; must be within 48 hours of warfarin
tmp.inrs <- read_edw_data(dir.data, "labs_coag", "labs") %>%
    semi_join(pts.include, by = "pie.id") %>%
    filter(lab == "inr") %>%
    group_by(pie.id) %>%
    arrange(lab.datetime) %>%
    inner_join(data.warfarin.dates, by = "pie.id") %>%
    filter(lab.datetime < warf.start) %>%
    mutate(inr.time = as.numeric(difftime(lab.datetime, warf.start,
                                          units = "days")),
           lab.result = as.numeric(lab.result))

excl.inr <- tmp.inrs %>%
    filter(inr.time >= -2, lab.result > 1.5) %>%
    distinct(pie.id)

tmp <- tmp.inrs %>%
    group_by(pie.id) %>%
    summarize(inr.time = last(inr.time)) %>%
    filter(inr.time < -2) %>%
    distinct(pie.id)

excl.inr <- bind_rows(excl.inr["pie.id"], tmp["pie.id"])

pts.exclude$Elevated_Baseline_INR <- excl.inr$pie.id

pts.include <- anti_join(pts.include, excl.inr, by = "pie.id")

# readmits ---------------------------------------------
# make a list of all person id's, then get list of all encounters for those
# patients; use the list to find readmit encounters in study and
raw.demographics <- read_edw_data(dir.data, "demographics") %>%
    inner_join(pts.include, by = "pie.id") %>%
    distinct(pie.id)

edw.persons <- concat_encounters(raw.demographics$person.id, 900)
print(edw.persons)

readmits <- c("Inpatient", "OBS Observation Patient", "EC Emergency Center",
              "OBS Day Surgery", "Bedded Outpatient", "Inpatient Rehab",
              "Inpatient Snf", "EC Fast ER Care", "72 Hour ER")

raw.encounters <- read_edw_data(dir.data, "encounters") %>%
    filter(visit.type %in% readmits)

raw.visits <- read_edw_data(dir.data, "visits")

tmp.encounters <- inner_join(raw.encounters, raw.visits,
                             by = c("pie.id", "admit.datetime")) %>%
    select(person.id, pie.id, admit.datetime, discharge.datetime) %>%
    group_by(person.id) %>%
    arrange(admit.datetime) %>%
    summarize(pie.id = first(pie.id),
              study.datetime = first(admit.datetime),
              discharge.datetime = first(discharge.datetime))

excl.readmits <- anti_join(pts.include, tmp.encounters, by = "pie.id")

pts.exclude$Readmission_Encounters <- excl.readmits$pie.id

pts.include <- semi_join(pts.include, tmp.encounters, by = "pie.id")

tmp.encounters <- select(tmp.encounters, -pie.id)

data.encounters.after <- left_join(raw.encounters, tmp.encounters,
                                   by = "person.id") %>%
    filter(admit.datetime >= discharge.datetime) %>%
    group_by(person.id) %>%
    arrange(admit.datetime) %>%
    mutate(encounter.next = difftime(admit.datetime, discharge.datetime,
                                     units = "days")) %>%
    filter(encounter.next <= 180)

# make groups ------------------------------------------
raw.consults <- read_edw_data(dir.data, "consults", "orders") %>%
    semi_join(pts.include, by = "pie.id")

pts.consults <- semi_join(pts.include, raw.consults, by = "pie.id")
pts.control <- anti_join(pts.include, raw.consults, by = "pie.id")

# find when consult started in relation to warfarin start
# remove patients who were consulted > 2 days after warfarin was started
tmp.consults <- raw.consults %>%
    filter(!str_detect(order, regex("(hold|discontinue)",
                                    ignore_case = TRUE))) %>%
    group_by(pie.id) %>%
    arrange(order.datetime) %>%
    summarize(consult.start = first(order.datetime)) %>%
    inner_join(data.warfarin.dates, by = "pie.id") %>%
    mutate(start.days = as.numeric(difftime(consult.start, warf.start,
                                            units = "days"))) %>%
    filter(start.days <= 2)

excl.mult.groups <- anti_join(pts.consults, tmp.consults, by = "pie.id")

pts.exclude$Changed_Groups <- excl.mult.groups$pie.id

pts.consults <- semi_join(pts.consults, tmp.consults, by = "pie.id")

pts.include <- anti_join(pts.include, excl.mult.groups, by = "pie.id") %>%
    select(pie.id) %>%
    mutate(group = ifelse(pie.id %in% pts.consults$pie.id, "pharmacy",
                          "traditional"))

data.identifiers <- read_edw_data(dir.data, "identifiers", "id") %>%
    semi_join(pts.include, by = "pie.id")

data.encounters.after <- semi_join(data.encounters.after, data.identifiers,
                                   by = "person.id")

pts.exclude$Included <- pts.include$pie.id
pts.exclude$Pharmacy <- pts.consults$pie.id
pts.exclude$Traditional <- pts.control$pie.id

data.warfarin.dates <- semi_join(data.warfarin.dates, pts.include, by = "pie.id")
data.warfarin.goals <- semi_join(data.warfarin.goals, pts.include, by = "pie.id")

# current patients -------------------------------------

tmp.2015 <- inner_join(pts.include, data.warfarin.dates, by = "pie.id") %>%
    filter(year(warf.start) == 2015)

pts.include <- mutate(pts.include, year = ifelse(pie.id %in% tmp.2015$pie.id,
                                                 "current", "historical"))

# save data --------------------------------------------
save_rds(dir.tidy, "pts")
save_rds(dir.tidy, "data")

edw.pie <- concat_encounters(pts.include$pie.id, 900)
print(edw.pie)
