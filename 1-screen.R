# screen.R

source("0-library.R")

# get list of patients receiving warfarin
raw.patients <- read_edw_data(dir.patients, "patients_events_warfarin", "patients") %>%
    filter(age >= 18,
           discharge.datetime < mdy_hm("1/1/2016 00:00"))

edw.pie.all <- concat_encounters(raw.patients$pie.id, 900)
# print(edw.pie.all)

# get total number of patients per year
analyze.patients.all <- raw.patients %>%
    mutate(year.cal = year(discharge.datetime))

raw.warfarin <- read_edw_data(dir.patients, "meds_sched_warfarin", "meds_sched") %>%
    semi_join(raw.patients, by = "pie.id")

# only include patients who received at least 3 doses
pts.screen <- raw.warfarin %>%
    group_by(pie.id) %>%
    summarize(count = n()) %>%
    filter(count > 2)

edw.pie <- concat_encounters(pts.screen$pie.id, 900)

# find first and last doses of warfarin
tmp.warfarin.dates.all <- raw.warfarin %>%
    group_by(pie.id) %>%
    arrange(med.datetime) %>%
    summarize(warf.start = first(med.datetime),
              warf.end = last(med.datetime))

data.warfarin.dates <- tmp.warfarin.dates.all %>%
    semi_join(pts.screen, by = "pie.id")

# find out which service patients were on at time of warfarin initiation
raw.services <- read_edw_data(dir.patients, "services_warfarin", "services") %>%
    group_by(pie.id) %>%
    arrange(start.datetime)

# this is an ugly hack, not sure why pie.id 113105540 won't run correctly if any
# of these 4 are in the data_frame
tmp <- filter(raw.services, pie.id %in% c("113104277", "113105042", "113105231", "113105428")) %>%
    tidy_data("services")

tmp2 <- filter(raw.services, !(pie.id %in% c("113104277", "113105042", "113105231", "113105428"))) %>%
    tidy_data("services")

raw.services <- bind_rows(tmp, tmp2)

analyze.services.all <- raw.services %>%
    inner_join(tmp.warfarin.dates.all, by = "pie.id") %>%
    filter(start.datetime <= warf.start,
           end.datetime >= warf.start)

# find hospital unit where warfarin was started
raw.locations <- read_edw_data(dir.patients, "locations") %>%
    tidy_data("locations")

analyze.locations.all <- raw.locations %>%
    inner_join(tmp.warfarin.dates.all, by = "pie.id") %>%
    filter(arrive.datetime <= warf.start,
           depart.datetime >= warf.start)

raw.inr <- read_edw_data(dir.patients, "warfarin_coags", "labs") %>%
    semi_join(pts.screen, by = "pie.id") %>%
    filter(lab == "inr")

# only inlcude patients with a baseline INR < 1.5 (last prior to warfarin start)
pts.screen <- raw.inr %>%
    inner_join(data.warfarin.dates, by = "pie.id") %>%
    filter(lab.datetime <= warf.start) %>%
    group_by(pie.id) %>%
    arrange(lab.datetime) %>%
    mutate(inr.time.prior = as.numeric(difftime(last(lab.datetime),
                                                warf.start, units = "days"))) %>%
    summarize(inr.baseline = last(lab.result),
              inr.time.prior = last(inr.time.prior)) %>%
    filter(inr.baseline < 1.5)

edw.pie <- concat_encounters(pts.screen$pie.id, 900)

data.warfarin.dates <- semi_join(data.warfarin.dates, pts.screen, by = "pie.id")

save_rds(dir.analysis, "analyze")
save_rds(dir.tidy, "pts")
save_rds(dir.tidy, "^data")

print(edw.pie)
