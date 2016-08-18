# ppt_2015

library(BGTools)
library(dplyr)
library(ggplot2)
library(scales)
library(lubridate)
library(tidyr)
library(stringr)
library(tableone)
library(ReporteRs)

tmp <- get_rds("tidy")
tmp <- get_rds("analysis")
pts.include <- inner_join(pts.include, data.new, by = "pie.id")

doc <- pptx(template = "template.pptx")
# Utilization of Pharmacy Dosing Service ---------------

d <- analyze.utilization %>%
    spread(order, n) %>%
    mutate(warfarin = ifelse(is.na(consult), warfarin, warfarin - consult)) %>%
    gather(order, n, -action.date) %>%
    arrange(action.date)

g <- ggplot(d, aes(x = action.date, y = n, color = order)) +
    geom_line(size = 0.2, alpha = 0.7) +
    geom_smooth() +
    ggtitle("Daily Warfarin Orders Managed by Pharmacy and Traditional") +
    xlab("Date") +
    ylab("Number of Daily Orders") +
    scale_color_brewer(palette = "Set1", labels = c("Pharmacy", "Traditional"), guide = guide_legend(title = NULL)) +
    xlim(c(mdy_hm("1/1/2013 00:00"), mdy_hm("12/31/2015 23:59")))

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Utilization of Pharmacy Dosing Service")
doc <- addPlot(doc, fun = print, x = g)

# Utilization by Medical Services ----------------------
tmp <- analyze.services.all %>%
    mutate(service = ordered(service, levels = names(sort(table(service), decreasing = TRUE)))) %>%
    group_by(service, consult, historical) %>%
    summarize(count = n()) %>%
    arrange(desc(count)) %>%
    filter(service <="Orthopedic Surgery Service") %>%
    group_by(service, historical) %>%
    spread(consult, count) %>%
    mutate(`FALSE` = `FALSE` - `TRUE`)

tmp$`FALSE`[tmp$`FALSE` < 0] <- 0

tmp <- gather(tmp, consult, count, -service, -historical)

d <- filter(tmp, historical == FALSE) %>%
    mutate(group = ifelse(consult == TRUE, "pharmacy", "traditional"))

g <- ggplot(data = d, aes(x = service, y = count, fill = group)) +
    geom_bar(stat = "identity") +
    # facet_grid(historical ~ .) +
    ggtitle("Warfarin Dosing Service Utilization Among\nTop 10 Medical Services Ordering Warfarin") +
    xlab("Medical Service") +
    ylab("Number of Patients") +
    scale_fill_brewer(palette = "Set1", labels = c("Pharmacy", "Traditional"), guide = guide_legend(title = NULL)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 12))

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Utilization by Medical Services")
doc <- addPlot(doc, fun = print, x = g)

# Comparison -------------------------------------------

ul1 <- parProperties(list.style = "unordered", level = 1)
ul2 <- parProperties(list.style = "unordered", level = 2)

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Comparison")
doc <- addParagraph(doc, "Group 1 - Pharmacy Dosing Service",
                    par.properties = ul1)
doc <- addParagraph(doc, "Consult placed within 48 hours of warfarin initiation",
                    par.properties = ul2,
                    append = TRUE)
doc <- addParagraph(doc, "At least 60% of warfarin doses placed by pharmacist",
                    par.properties = ul2,
                    append = TRUE)
doc <- addParagraph(doc, "Group 2 - Traditional Dosing",
                    par.properties = ul1,
                    append = TRUE)

# Methods: Inclusion -----------------------------------

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Methods: Inclusion")
doc <- addParagraph(doc, "January 1, 2015 to December 31, 2015",
                    par.properties = ul1)
doc <- addParagraph(doc, "Age at least 18 years",
                    par.properties = ul1,
                    append = TRUE)
doc <- addParagraph(doc, "Received at least 3 doses of warfarin",
                    par.properties = ul1,
                    append = TRUE)
doc <- addParagraph(doc, "Baseline INR below 1.5",
                    par.properties = ul1,
                    append = TRUE)

# Methods: Exclusion -----------------------------------

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Methods: Exclusion")
doc <- addParagraph(doc, "Concurrent DTI or DOAC",
                    par.properties = ul1)
doc <- addParagraph(doc, "Liver dysfunction",
                    par.properties = ul1,
                    append = TRUE)
doc <- addParagraph(doc, "AST and ALT > 5x ULN (concurrently)",
                    par.properties = ul2,
                    append = TRUE)
doc <- addParagraph(doc, "ALT > 10x ULN",
                    par.properties = ul2,
                    append = TRUE)
doc <- addParagraph(doc, "T.Bili > 3x ULN",
                    par.properties = ul2,
                    append = TRUE)
doc <- addParagraph(doc, "Missing goals of therapy data",
                    par.properties = ul1,
                    append = TRUE)
doc <- addParagraph(doc, "Readmission encounters",
                    par.properties = ul1,
                    append = TRUE)

# Demographics ----

total <- pts.include %>%
    group_by(group, year) %>%
    summarize(total = n())

demograph <- pts.include %>%
    inner_join(data.demographics, by = "pie.id") %>%
    inner_join(data.measures, by = "pie.id") %>%
    mutate(sex = factor(sex, levels = c("Female", "Male")),
           race = str_replace_all(race, "Oriental", "Asian"),
           race = factor(race, exclude = c("", "Unknown")))

names(demograph) <- str_to_title(names(demograph))
names(demograph)[9] <- "Length of Stay"
names(demograph)[15] <- "BMI"

vars <- c("Age", "Sex", "BMI", "Race", "Length of Stay", "Therapy")
fvars <- c("Sex", "Race", "Therapy")
d <- filter(demograph, Year == "current")
tbl <- CreateTableOne(vars, "Group", d, fvars)
ptbl <- print(tbl, nonnormal = c("Age", "BMI", "Length of Stay"), printToggle = FALSE, cramVars = "Therapy")
# rownames(ptbl)[6:10] <- str_c("-", rownames(ptbl)[6:10])

ft <- FlexTable(ptbl[, 1:3],
                add.rownames = TRUE,
                body.par.props = parProperties(padding = 8),
                body.text.props = textProperties(font.size = 16, font.family = "Calibri"),
                header.text.props = textProperties(font.size = 20, font.family = "Calibri", font.weight = "bold"),
                header.par.props = parProperties(padding = 4))

ft <- setFlexTableWidths(ft, widths = c(3, 2.25, 2.25, 1.5))
ft[, to = "header"] <- parCenter()
ft[, 2:4] <- parCenter()

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Demographics")
doc <- addFlexTable(doc, ft)

# Anticoagulation Indications --------------------------

counts <- pts.include %>%
    inner_join(data.warfarin.indications, by = "pie.id") %>%
    gather(indication, value, -pie.id, -group, -year, -therapy) %>%
    filter(value == TRUE,
           year == "current") %>%
    group_by(group, year, indication) %>%
    summarize(n = n()) %>%
    left_join(total, by = c("group", "year")) %>%
    mutate(perc = n / total)

g <- ggplot(data = counts, aes(x = indication, fill = group)) +
    geom_bar(aes(y = perc), stat = "identity", position = "dodge") +
    # facet_grid(year ~ .) +
    ggtitle("Indications for warfarin use") +
    xlab("Indication") +
    ylab("Patients") +
    scale_y_continuous(labels = percent) +
    scale_fill_brewer(palette = "Set1", labels = c("Pharmacy", "Traditional"), guide = guide_legend(title = NULL)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 12))

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Anticoagulation Indications")
doc <- addPlot(doc, fun = print, x = g)

# Inpatient Dosing Days --------------------------------

d <- pts.include %>%
    inner_join(data.labs.inrs, by = "pie.id") %>%
    calc_lab_runtime(units = "days") %>%
    filter(year == "current")

df <- d %>%
    group_by(pie.id, group) %>%
    summarize(num.days = first(warf.days))

p <- kruskal.test(x = df$num.days, g = as.factor(df$group))
lab <- str_c("p-value = ", round(p$p.value, 3))

g <- ggplot(df, aes(x = group, y = num.days)) +
    geom_boxplot() +
    ggtitle("Inpatient Dosing Days") +
    xlab("Group") +
    ylab("Days") +
    annotate("text", x = 1.5, y = 12.5, label = lab, size = 8) +
    # coord_cartesian(ylim = c(0, 20))
    ylim(c(0, 20))

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Inpatient Dosing Days")
doc <- addPlot(doc, fun = print, x = g)

# INR Response -----------------------------------------

g <- ggplot(d, aes(x = run.time, y = lab.result, group = group)) +
    geom_point(alpha = 0.3, size = 0.5) +
    # geom_vline(xintercept = 0, linetype = "dashed", color = "dark blue") +
    geom_smooth(aes(color = group)) +
    ggtitle("INR response after starting warfarin") +
    xlab("Day") +
    ylab("INR") +
    scale_x_continuous(breaks = seq(0, 10, by = 2), limits = c(0, 10)) +
    ylim(c(1, 3)) +
    scale_color_brewer(palette = "Set1", labels = c("Pharmacy", "Traditional"), guide = guide_legend(title = NULL))
    # coord_cartesian(xlim = c(0, 10), ylim = c(1, 3))

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "INR Response")
doc <- addPlot(doc, fun = print, x = g)

# Change in INR ----------------------------------------

df <- d %>%
    group_by(pie.id, group, year) %>%
    summarize(first.inr = first(lab.result),
              last.inr = last(lab.result)) %>%
    mutate(change.inr = last.inr - first.inr)

p <- kruskal.test(x = df$change.inr, g = as.factor(df$group))
lab <- str_c("p-value = ", round(p$p.value, 3))

g <- ggplot(df, aes(x = group, y = change.inr)) +
    geom_boxplot() +
    annotate("text", x = 1.5, y = 3, label = lab, size = 8) +
    ggtitle("Change in INR") +
    xlab("Group") +
    ylab("INR Difference")

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Change in INR")
doc <- addPlot(doc, fun = print, x = g)

# Time in Therapeutic Range ----------------------------

d <- pts.include %>%
    inner_join(data.inr.inrange, by = "pie.id") %>%
    filter(year == "current")

p <- kruskal.test(x = d$perc.time, g = as.factor(d$group))

g <- ggplot(d, aes(x = group, y = perc.time)) +
    geom_boxplot() +
    ggtitle("Percent of time INR is within therapeutic range") +
    xlab("Group") +
    ylab("Time in Therapeutic Range") +
    scale_y_continuous(labels = percent)

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Time in Therapeutic Range")
doc <- addPlot(doc, fun = print, x = g)

# Time with Critical INR Values ------------------------

d <- pts.include %>%
    inner_join(data.inr.supratx, by = "pie.id") %>%
    filter(year == "current")

p <- kruskal.test(x = d$perc.time, g = as.factor(d$group))

g <- ggplot(d, aes(x = group, y = perc.time)) +
    geom_boxplot() +
    ggtitle("Percent of time INR is critical (at or above 4)") +
    xlab("Group") +
    ylab("Time with Critical INR") +
    scale_y_continuous(labels = percent)

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Time with Critical INR Values")
doc <- addPlot(doc, fun = print, x = g)

# Change in Hemoglobin ---------------------------------

df <- pts.include %>%
    inner_join(data.labs.hgb, by = "pie.id") %>%
    calc_lab_runtime(units = "days") %>%
    filter(year == "current") %>%
    group_by(pie.id, group, year) %>%
    summarize(first.inr = first(lab.result),
              last.inr = last(lab.result)) %>%
    mutate(change.inr = last.inr - first.inr)

p <- kruskal.test(x = df$change.inr, g = as.factor(df$group))
lab <- str_c("p-value = ", round(p$p.value, 3))

g <- ggplot(df, aes(x = group, y = change.inr)) +
    geom_boxplot() +
    annotate("text", x = 1.5, y = 2.5, label = lab, size = 8) +
    ggtitle("Change in Hemoglobin") +
    xlab("Group") +
    ylab("Hemoglobin Difference (g/dL)")

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Change in Hemoglobin")
doc <- addPlot(doc, fun = print, x = g)

# Historical Comparison --------------------------------

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Historical Comparison")
doc <- addParagraph(doc, "Pharmacy Dosing Service 2015 vs. 2013-2014",
                    par.properties = ul1)
doc <- addParagraph(doc, "Same inclusion and exclusion criteria",
                    par.properties = ul1,
                    append = TRUE)

# Historical Demographics ------------------------------

d <- filter(demograph, Group == "pharmacy")

vars <- c("Age", "Sex", "BMI", "Race", "Length of Stay", "Therapy")
fvars <- c("Sex", "Race", "Therapy")

tbl <- CreateTableOne(vars, "Year", d, fvars)
ptbl <- print(tbl, nonnormal = c("Age", "Length of Stay"), printToggle = FALSE, cramVars = "Therapy")
# rownames(ptbl)[6:11] <- str_c("-", rownames(ptbl)[6:11])

ft <- FlexTable(ptbl[, 1:3],
                add.rownames = TRUE,
                body.par.props = parProperties(padding = 8),
                body.text.props = textProperties(font.size = 16, font.family = "Calibri"),
                header.text.props = textProperties(font.size = 20, font.family = "Calibri", font.weight = "bold"),
                header.par.props = parProperties(padding = 4))

ft <- setFlexTableWidths(ft, widths = c(3, 2.25, 2.25, 1.5))
ft[, to = "header"] <- parCenter()
ft[, 2:4] <- parCenter()

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Historical Demographics")
doc <- addFlexTable(doc, ft)

# Utilization by Medical Services ----------------------

d <- filter(tmp, consult == TRUE) %>%
    mutate(year = ifelse(historical == TRUE, "historical", "current"),
           count = ifelse(historical == TRUE, count / 2, count))

g <- ggplot(d, aes(x = service, y = count, fill = year)) +
    geom_bar(stat = "identity", position = "dodge") +
    # facet_grid(historical ~ .) +
    ggtitle("Warfarin Dosing Service Utilization Among\nTop 10 Medical Services Ordering Warfarin") +
    xlab("Medical Service") +
    ylab("Number of Patients (Annualized)") +
    scale_fill_brewer(palette = "Set1", labels = c("Current", "Historical"), guide = guide_legend(title = NULL)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 12))

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Utilization by Medical Services")
doc <- addPlot(doc, fun = print, x = g)

# Anticoagulation Indications --------------------------

counts <- pts.include %>%
    inner_join(data.warfarin.indications, by = "pie.id") %>%
    gather(indication, value, -pie.id, -group, -year) %>%
    filter(value == TRUE, group == "pharmacy") %>%
    group_by(group, year, indication) %>%
    summarize(n = n()) %>%
    left_join(total, by = c("group", "year")) %>%
    mutate(perc = n / total)

g <- ggplot(data = counts, aes(x = indication, fill = year)) +
    geom_bar(aes(y = perc), stat = "identity", position = "dodge") +
    # facet_grid(year ~ .) +
    ggtitle("Indications for warfarin use") +
    xlab("Indication") +
    ylab("Patients") +
    scale_y_continuous(labels = percent) +
    scale_fill_brewer(palette = "Set1", labels = c("Current", "Historical"), guide = guide_legend(title = NULL)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 12))

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Anticoagulation Indications")
doc <- addPlot(doc, fun = print, x = g)

# Inpatient Dosing Days --------------------------------

d <- pts.include %>%
    inner_join(data.labs.inrs, by = "pie.id") %>%
    calc_lab_runtime(units = "days") %>%
    filter(group == "pharmacy")

df <- d %>%
    group_by(pie.id, year) %>%
    summarize(num.days = first(warf.days))

p <- kruskal.test(x = df$num.days, g = as.factor(df$year))

g <- ggplot(df, aes(x = year, y = num.days)) +
    geom_boxplot() +
    ggtitle("Inpatient Dosing Days") +
    xlab("Group") +
    ylab("Days") +
    # coord_cartesian(ylim = c(0, 20))
    ylim(c(0, 20))

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Inpatient Dosing Days")
doc <- addPlot(doc, fun = print, x = g)

# INR Response -----------------------------------------

d <- pts.include %>%
    inner_join(data.labs.inrs, by = "pie.id") %>%
    filter(group == "pharmacy") %>%
    calc_lab_runtime(units = "days")

g <- ggplot(d, aes(x = run.time, y = lab.result, group = year)) +
    # facet_grid(year ~ .) +
    geom_point(alpha = 0.3, size = 0.5) +
    # geom_vline(xintercept = 0, linetype = "dashed", color = "dark blue") +
    geom_smooth(aes(color = year)) +
    ggtitle("Change in INR after starting warfarin") +
    xlab("Day") +
    ylab("INR") +
    scale_x_continuous(breaks = seq(0, 10, by = 2), limits = c(0, 10)) +
    ylim(c(1, 3)) +
    scale_color_brewer(palette = "Set1", labels = c("Current", "Historical"), guide = guide_legend(title = NULL))

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "INR Response")
doc <- addPlot(doc, fun = print, x = g)

# Time in Therapeutic Range ----------------------------

d <- pts.include %>%
    inner_join(data.inr.inrange, by = "pie.id") %>%
    filter(group == "pharmacy")

p <- kruskal.test(x = d$perc.time, g = as.factor(d$year))
lab <- str_c("p-value = ", round(p$p.value, 3))

g <- ggplot(d, aes(x = year, y = perc.time)) +
    geom_boxplot() +
    ggtitle("Percent of time INR is within therapeutic range") +
    xlab("Group") +
    ylab("Time in Therapeutic Range") +
    scale_y_continuous(labels = percent)

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Time in Therapeutic Range")
doc <- addPlot(doc, fun = print, x = g)

# Time Critical INR ------------------------------------

df <- pts.include %>%
    inner_join(data.inr.supratx, by = "pie.id") %>%
    filter(group == "pharmacy")

g <- ggplot(df, aes(x = year, y = perc.time)) +
    geom_boxplot() +
    # facet_grid(year ~ .) +
    ggtitle("Percent of time INR is critical (at or above 4)") +
    xlab("Group") +
    ylab("Time with Critical INR") +
    scale_y_continuous(labels = percent)

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Time Critical INR")
doc <- addPlot(doc, fun = print, x = g)

# Change in Hemoglobin ---------------------------------

df <- pts.include %>%
    inner_join(data.labs.hgb, by = "pie.id") %>%
    calc_lab_runtime(units = "days") %>%
    filter(group == "pharmacy") %>%
    group_by(pie.id, year) %>%
    summarize(first.inr = first(lab.result),
              last.inr = last(lab.result)) %>%
    mutate(change.inr = last.inr - first.inr)

p <- kruskal.test(x = df$change.inr, g = as.factor(df$year))
lab <- str_c("p-value = ", round(p$p.value, 3))

g <- ggplot(df, aes(x = year, y = change.inr)) +
    geom_boxplot() +
    annotate("text", x = 1.5, y = 2.5, label = lab, size = 8) +
    ggtitle("Change in Hemoglobin") +
    xlab("Group") +
    ylab("Hemoglobin Difference (g/dL)")

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Change in Hemoglobin")
doc <- addPlot(doc, fun = print, x = g)

# Conclusions ------------------------------------------

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Conclusions")
doc <- addParagraph(doc, "Utilization of Pharmacy Dosing Service continues to increase",
                    par.properties = ul1)
doc <- addParagraph(doc, "Patients managed by the Pharmacy Dosing Service had:",
                    par.properties = ul1,
                    append = TRUE)
doc <- addParagraph(doc, "Larger median increase in INR",
                    par.properties = ul2,
                    append = TRUE)
doc <- addParagraph(doc, "Smaller median decrease in Hgb (p = 0.053)",
                    par.properties = ul2,
                    append = TRUE)
doc <- addParagraph(doc, "No differences found in historical comparison",
                    par.properties = ul1,
                    append = TRUE)

# Ongoing Analysis ------------------------------------------

doc <- addSlide(doc, slide.layout = "Alternate Title and Content")
doc <- addTitle(doc, "Ongoing Analysis")
doc <- addParagraph(doc, "Creating a Pharmacy Dosing Dervice dashboard",
                    par.properties = ul1)
doc <- addParagraph(doc, "Will allow for more real-time monitoring of utilization and quality",
                    par.properties = ul1,
                    append = TRUE)
doc <- addParagraph(doc, "Demo available at:",
                    par.properties = ul1,
                    append = TRUE)

link <- pot("https://bgulbis.github.io/Warfarin_Dashboard/report/dashboard.html",
            hyperlink = "https://bgulbis.github.io/Warfarin_Dashboard/report/dashboard.html")
doc <- addParagraph(doc, link, par.properties = ul2, append = TRUE)

writeDoc(doc, file = "warfarin_analysis_2015.pptx")
