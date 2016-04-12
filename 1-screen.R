# screen.R

source("0-library.R")

# get list of patients receiving warfarin
raw.patients <- read_edw_data(dir.patients, "patients_events_warfarin", "patients") %>%
    filter(age >= 18,
           discharge.datetime < mdy("1/1/2016"))

edw.pie.all <- concat_encounters(raw.patients$pie.id, 750)
# print(edw.pie.all)

# get total number of patients per year
analyze.patients.all <- raw.patients %>%
    mutate(year.cal = year(discharge.datetime))

save_rds(dir.analysis, "analyze")

raw.warfarin <- read_edw_data(dir.patients, "meds_sched_warfarin", "meds_sched") %>%
    semi_join(raw.patients, by = "pie.id")

# only include patients who received at least 3 doses
pts.include <- raw.warfarin %>%
    group_by(pie.id) %>%
    summarize(count = n()) %>%
    filter(count > 2)

edw.pie <- concat_encounters(pts.include$pie.id, 750)

# only inlcude patients with a baseline INR < 1.5 (last prior to warfarin start)
tmp.warfarin.start <- raw.warfarin %>%
    semi_join(pts.include, by = "pie.id") %>%
    group_by(pie.id) %>%
    arrange(med.datetime) %>%
    summarize(warf.start = first(med.datetime))

raw.inr <- read_edw_data(dir.patients, "warfarin_coags", "labs") %>%
    semi_join(pts.include, by = "pie.id") %>%
    filter(lab == "inr")

pts.include <- raw.inr %>%
    inner_join(tmp.warfarin.start, by = "pie.id") %>%
    filter(lab.datetime <= warf.start) %>%
    group_by(pie.id) %>%
    arrange(lab.datetime) %>%
    mutate(inr.time.prior = as.numeric(difftime(last(lab.datetime),
                                                warf.start, units = "days"))) %>%
    summarize(inr.baseline = last(lab.result),
              inr.time.prior = last(inr.time.prior)) %>%
    filter(inr.baseline < 1.5)

edw.pie <- concat_encounters(pts.include$pie.id, 750)

print(edw.pie)
