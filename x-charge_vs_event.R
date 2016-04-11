# charge_vs_event.R

# compare patient lists by charge data vs. clinical event (medication adminiatration) data

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

pie.missing.event <- concat_encounters(missing.event$pie.id)
print(pie.missing.event)

pie.missing.charge <- concat_encounters(missing.charge$pie.id)
print(pie.missing.charge)

tmp <- read_edw_data(patient.dir, "facility_warfarin_missing_event", "facility")

missing.event <- inner_join(missing.event, tmp, by = "pie.id")

# tmp.missing.charge <- read_edw_data(patient.dir, "facility_warfarin_missing_charge", "facility")

# fins.charge <- read_edw_data(patient.dir, "identifiers_warfarin_charge", "id")
tmp <- read_edw_data(patient.dir, "identifiers_warfarin_missing_event", "id")

missing.event <- inner_join(missing.event, tmp, by = "pie.id") %>%
    filter(admit.datetime >= mdy("07/01/2012"))

# there are a small number of patients different in this sample
