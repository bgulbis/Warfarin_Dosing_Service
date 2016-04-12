# screen.R

source("0-library.R")

# get list of patients receiving warfarin
raw.patients <- read_edw_data(patient.dir, "patients_events_warfarin", "patients") %>%
    filter(age >= 18)

edw.pie <- concat_encounters(raw.patients$pie.id, 750)
print(edw.pie)

raw.warfarin <- read_edw_data(patient.dir, "meds_sched_warfarin", "meds_sched")

# only include patients who received at least 3 doses
tmp.include <- raw.warfarin %>%
    group_by(pie.id) %>%
    summarize(count = n()) %>%
    filter(count > 2)
