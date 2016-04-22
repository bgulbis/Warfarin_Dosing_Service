# tidy.R

source("0-library.R")

tmp <- get_rds(dir.tidy)

tidy.demographics <- read_edw_data(dir.data, "demographics") %>%
    inner_join(pts.include, by = "pie.id")

edw.persons <- concat_encounters(tidy.demographics$person.id, 750)
print(edw.persons)
