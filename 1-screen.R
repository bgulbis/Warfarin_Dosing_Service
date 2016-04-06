# screen.R

source("0-library.R")

pts.charge <- read_edw_data(patient.dir, "patients_warfarin", "charges",
                            check.distinct = FALSE) %>%
    group_by(pie.id) %>%
    summarize(count = n(),
              first.date = first(service.date))

pts.events <- read_edw_data(patient.dir, "patients_events", "patients")

pts <- full_join(pts.charge, pts.events, by = "pie.id")

missing.event <- anti_join(pts.charge, pts.events, by = "pie.id")
missing.charge <- anti_join(pts.events, pts.charge, by = "pie.id")

pie.charge <- concat_encounters(missing.event$pie.id)
print(pie.charge)

pie.event <- concat_encounters(missing.charge$pie.id)
print(pie.event)

missing.event <- read_edw_data(patient.dir, "facility_warfarin_missing_event",
                               "facility")
missing.charge <- read_edw_data(patient.dir, "facility_warfarin_missing_charge",
                                "facility")

fins.charge <- read_edw_data(patient.dir, "identifiers_warfarin_charge", "id")
fins.event <- read_edw_data(patient.dir, "identifiers_warfarin_event", "id")
