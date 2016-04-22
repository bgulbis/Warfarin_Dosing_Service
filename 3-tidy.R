# tidy.R

source("0-library.R")

tmp <- get_rds(dir.tidy)

# make a list of all person id's, then get list of all encounters for those
# patients; use the list to find readmit encounters in study and

tidy.demographics <- read_edw_data(dir.data, "demographics") %>%
    inner_join(pts.include, by = "pie.id") %>%
    distinct(pie.id)

edw.persons <- concat_encounters(tidy.demographics$person.id, 750)
print(edw.persons)

readmits <- c("Inpatient", "OBS Observation Patient", "EC Emergency Center",
              "OBS Day Surgery", "Bedded Outpatient", "Inpatient Rehab",
              "Inpatient Snf", "EC Fast ER Care", "72 Hour ER")

raw.encounters <- read_edw_data(dir.data, "encounters") %>%
    filter(visit.type %in% readmits)

raw.visits <- read_edw_data(dir.data, "visits")

tmp.encounters <- inner_join(raw.encounters, raw.visits, by = c("pie.id", "admit.datetime")) %>%
    select(person.id, pie.id, admit.datetime, discharge.datetime) %>%
    group_by(person.id) %>%
    arrange(admit.datetime) %>%
    summarize(pie.id = first(pie.id),
              study.datetime = first(admit.datetime),
              discharge.datetime = first(discharge.datetime))

excl.readmits <- anti_join(pts.include, tmp.encounters, by = "pie.id")

pts.include <- semi_join(pts.include, tmp.encounters, by = "pie.id")

tmp.encounters <- select(tmp.encounters, -pie.id)

tmp.encounters.after <- left_join(raw.encounters, tmp.encounters, by = "person.id") %>%
    filter(admit.datetime >= discharge.datetime) %>%
    group_by(person.id) %>%
    arrange(admit.datetime) %>%
    mutate(encounter.next = difftime(admit.datetime, discharge.datetime, units = "days")) %>%
    filter(encounter.next <= 180)

