
rnum <- sample.int(100000, 1)

test <- read_data("data", "demographics") %>%
    sample_n(10) %>%
    mutate(`PowerInsight Encounter Id` = as.character(as.numeric(`PowerInsight Encounter Id`) + rnum),
           `Person ID` = as.character(as.numeric(`Person ID`) + rnum),
           `Person Location- Facility (Curr)` = "Hospital")

readr::write_csv(test, "test_demographics.csv")

test.censor <- read_data("data", "labs_coag") %>%
    filter(str_detect(`Clinical Event Result`, ">|<")) %>%
    sample_n(5) %>%
    mutate(`PowerInsight Encounter Id` = as.character(as.numeric(`PowerInsight Encounter Id`) + rnum))

test <- read_data("data", "labs_coag") %>%
    sample_n(10) %>%
    mutate(`PowerInsight Encounter Id` = as.character(as.numeric(`PowerInsight Encounter Id`) + rnum))

test <- bind_rows(test, test.censor)

readr::write_csv(test, "test_labs.csv")

# tmp <- read_edw_data("./", "test_labs.csv", "labs")
