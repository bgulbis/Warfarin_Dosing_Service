# screen.R

source("0-library.R")
# library(edwr)

# get list of patients receiving warfarin
tmp.patients <- read_edw_data(dir.patients, "patients")

raw.patients <- tmp.patients %>%
    filter(age >= 18,
           discharge.datetime < mdy_hm("1/1/2016 00:00"))

extra.patients <- tmp.patients %>%
    filter(age >= 18,
           discharge.datetime >= mdy_hm("1/1/2016 00:00"))

concat_encounters(extra.patients$pie.id)

edw.pie.all <- concat_encounters(raw.patients$pie.id, 900)
# print(edw.pie.all)

# get total number of patients per year
analyze.patients.all <- raw.patients %>%
    mutate(year.cal = year(discharge.datetime))

raw.warfarin <- read_edw_data(dir.patients, "meds_sched") %>%
    semi_join(raw.patients, by = "pie.id")

raw.orders <- edwr::read_edw_data(dir.patients, "orders") %>%
    filter(action.type == "Order") %>%
    mutate(action.date = floor_date(action.datetime, unit = "day"),
           consult = !str_detect(order, "^warfarin$"))

analyze.utilization <- raw.orders %>%
    group_by(pie.id, action.date, consult) %>%
    select(pie.id, action.date, consult) %>%
    arrange(action.date) %>%
    distinct %>%
    group_by(pie.id, action.date) %>%
    mutate(value = TRUE,
           consult = ifelse(consult == TRUE, "consult", "warfarin")) %>%
    spread(consult, value) %>%
    mutate(warfarin = ifelse(consult == TRUE & is.na(warfarin), TRUE, warfarin)) %>%
    gather(order, value, consult, warfarin) %>%
    arrange(action.date) %>%
    filter(!is.na(value)) %>%
    group_by(pie.id, action.date, order) %>%
    summarize(n = n()) %>%
    group_by(action.date, order) %>%
    summarize(n = n())

tmp.consults <- read_edw_data(dir.data, "consults", "orders") %>%
    semi_join(raw.patients, by = "pie.id") %>%
    filter(!str_detect(order, regex("(hold|discontinue)", ignore_case = TRUE))) %>%
    mutate(order.date = floor_date(order.datetime, unit = "month")) %>%
    group_by(pie.id) %>%
    arrange(order.date) %>%
    summarize(consult.date = first(order.date))

# analyze.utilization <- raw.warfarin %>%
#     mutate(dose.date = floor_date(med.datetime, unit = "month")) %>%
#     group_by(pie.id, dose.date) %>%
#     summarize(doses = n()) %>%
#     left_join(tmp.consults, by = "pie.id")

# identify unique warfarin courses; criteria are first dose in hospital, more
# than 5 days since prior warfarin dose, or 2-4 since last warfarin dose and the
# INR is < 1.5 during this time
# tmp.warfarin.doses <- raw.warfarin %>%
#     mutate(dose.date = floor_date(med.datetime, unit = "day")) %>%
#     group_by(pie.id, dose.date) %>%
#     summarize(med.dose = sum(med.dose),
#               num.dose = n()) %>%
#     group_by(pie.id) %>%
#     mutate(days.prev = difftime(dose.date, lag(dose.date), units = "days"))
#
# tmp.dates <- tmp.warfarin.doses %>%
#     group_by(pie.id) %>%
#     summarize(first.date = first(dose.date),
#               last.date = last(dose.date))
#
# tmp.inr <- read_edw_data(dir.patients, "inr", "labs") %>%
#     mutate(inr.date = floor_date(lab.datetime, unit = "day"),
#            lab.result = as.numeric(lab.result)) %>%
#     inner_join(tmp.dates, by = "pie.id") %>%
#     filter(inr.date >= first.date,
#            inr.date <= last.date) %>%
#     group_by(pie.id, inr.date) %>%
#     summarize(inr = max(lab.result))
#
# # convert NA's to 0 before using cumsum function
# cumsum_na <- function(x) {
#     x[is.na(x)] <- 0
#     cumsum(x)
# }
#
# data.warfarin.courses <- tmp.warfarin.doses %>%
#     full_join(tmp.inr, by = c("pie.id", "dose.date" = "inr.date")) %>%
#     arrange(pie.id, dose.date) %>%
#     mutate(new.dose = ifelse((!is.na(med.dose) & is.na(days.prev)) | days.prev > 5 |
#                                  (days.prev > 2 & lag(inr) < 1.5), TRUE, FALSE),
#            course = cumsum_na(new.dose))

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
    semi_join(pts.screen, by = "pie.id") %>%
    mutate(warf.days = as.numeric(difftime(warf.end, warf.start, units = "days")))

# find out which service patients were on at time of warfarin initiation
raw.services <- read_edw_data(dir.patients, "services_warfarin", "services") %>%
    group_by(pie.id) %>%
    arrange(start.datetime)

# this is an ugly hack, not sure why pie.id 113105540 won't run correctly if any
# of these 4 are in the data_frame
pie <- c("113104277", "113105042", "113105231", "113105428")

tmp <- filter(raw.services, pie.id %in% pie) %>%
    tidy_data("services")

tmp2 <- filter(raw.services, !(pie.id %in% pie)) %>%
    tidy_data("services")

raw.services <- bind_rows(tmp, tmp2)

analyze.services.all <- raw.services %>%
    inner_join(tmp.warfarin.dates.all, by = "pie.id") %>%
    filter(start.datetime <= warf.start,
           end.datetime >= warf.start) %>%
    mutate(consult = pie.id %in% tmp.consults$pie.id,
           historical = warf.start < mdy_hm("1/1/2015 00:00"))

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
