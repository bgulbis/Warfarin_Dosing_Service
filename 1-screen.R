# screen.R

source("0-library.R")

# get list of patients receiving warfarin
raw.patients <- read_edw_data(patient.dir, "patients_events_warfarin", "patients") %>%
    filter(age >= 18)

edw.pie <- concat_encounters(raw.patients$pie.id, 750)
print(edw.pie)
