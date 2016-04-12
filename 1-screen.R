# screen.R

source("0-library.R")

# get list of patients receiving warfarin
raw.patients <- read_edw_data(dir.patients, "patients_events_warfarin", "patients") %>%
    filter(age >= 18,
           discharge.datetime < mdy("1/1/2016"))

edw.pie <- concat_encounters(raw.patients$pie.id, 750)
print(edw.pie)

# get total number of patients per year
analyze.patients.all <- raw.patients %>%
    mutate(year.cal = year(discharge.datetime))

save_rds(dir.analysis, "analyze")

raw.warfarin <- read_edw_data(dir.patients, "meds_sched_warfarin", "meds_sched") %>%
    semi_join(raw.patients, by = "pie.id")

# only include patients who received at least 3 doses
tmp.include <- raw.warfarin %>%
    group_by(pie.id) %>%
    summarize(count = n()) %>%
    filter(count > 2)
