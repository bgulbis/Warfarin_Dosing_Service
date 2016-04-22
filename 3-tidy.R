# tidy.R

source("0-library.R")

tmp <- get_rds(dir.tidy)

tidy.demographics <- read_edw_data(dir.data, "demographics") %>%
    inner_join(pts.include, by = "pie.id")

edw.persons <- concat_encounters(tidy.demographics$person.id, 750)
print(edw.persons)

readmits <- c("Inpatient", "OBS Observation Patient", "EC Emergency Center",
              "OBS Day Surgery", "Bedded Outpatient", "Inpatient Rehab",
              "Inpatient Snf", "EC Fast ER Care", "72 Hour ER")

raw.encounters <- read_edw_data(dir.data, "encounters") %>%
    filter(visit.type %in% readmits)
