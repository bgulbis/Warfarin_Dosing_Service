# screen.R

source("0-library.R")

pts.charge <- read_edw_data(patient.dir, "patients_warfarin", "charges",
                            check.distinct = FALSE) %>%
    distinct(pie.id)

pts.events <- read_edw_data(patient.dir, "patients_events", "patients",
                            check.distinct = FALSE) %>%
    distinct(pie.id)

pts <- full_join(pts.charge, pts.events, by = "pie.id")

