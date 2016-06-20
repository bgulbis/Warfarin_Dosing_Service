Warfarin Pharmacy Dosing Service Analysis
========================================================
author: Brian Gulbis
date: June 2016
autosize: true

Annual Warfarin Utilization
========================================================






![plot of chunk graph_utilization](warfarin_analysis-figure/graph_utilization-1.png)

Utilization of Pharmacy Dosing Service
========================================================
![plot of chunk dose_service_use](warfarin_analysis-figure/dose_service_use-1.png)

Orders by Pharmacy Dosing Service
========================================================
![plot of chunk dose_service_use2](warfarin_analysis-figure/dose_service_use2-1.png)

Utilization by Medical Services
========================================================
![plot of chunk ds_med_service_curr](warfarin_analysis-figure/ds_med_service_curr-1.png)

Comparison
========================================================

* Group 1 - Pharmacy Dosing Service
    - Consult placed within 48 hours of warfarin initiation
    - &ge; 60% of warfarin doses placed by pharmacist
* Group 2 - Traditional Dosing

Methods: Inclusion
========================================================

* January 1, 2015 to December 31, 2015
* Age &ge; 18 years
* Received at least 3 doses of warfarin
* Baseline INR < 1.5

Methods: Exclusion
========================================================

* Concurrent DTI or TSOAC
* Liver dysfunction
    - AST and ALT > 5x ULN (concurrently)
    - ALT > 10x ULN
    - T.Bili > 3x ULN
* Missing goals of therapy data
* Readmission encounters

Demographics
========================================================

|                              |pharmacy             |traditional          |p      |
|:-----------------------------|:--------------------|:--------------------|:------|
|n                             |402                  |285                  |       |
|Age (median [IQR])            |58.00 [42.25, 68.75] |64.00 [54.00, 72.00] |<0.001 |
|Sex = Male (%)                |240 (59.7)           |182 (64.1)           |0.279  |
|BMI (median [IQR])            |28.48 [24.40, 33.54] |29.32 [25.18, 33.68] |0.277  |
|Race (%)                      |                     |                     |0.096  |
|-   African American          |104 (28.4)           |74 (27.9)            |       |
|-   Asian                     |12 ( 3.3)            |1 ( 0.4)             |       |
|-   Native Am.                |0 ( 0.0)             |1 ( 0.4)             |       |
|-   Other                     |78 (21.3)            |59 (22.3)            |       |
|-   White/Caucasian           |172 (47.0)           |130 (49.1)           |       |
|Length of Stay (median [IQR]) |12.10 [7.71, 19.83]  |13.71 [8.04, 24.17]  |0.103  |
|Therapy = New/Previous (%)    |270/132 (67.2/32.8)  |143/142 (50.2/49.8)  |<0.001 |

Anticoagulation Indications
========================================================
![plot of chunk indications](warfarin_analysis-figure/indications-1.png)

Disposition
========================================================
![plot of chunk disposition](warfarin_analysis-figure/disposition-1.png)

Inpatient Dosing Days
========================================================
![plot of chunk dosing_days](warfarin_analysis-figure/dosing_days-1.png)

Inpatient Dosing Days - Closer Look
========================================================
![plot of chunk dosing_days2](warfarin_analysis-figure/dosing_days2-1.png)

INR Response
========================================================
![plot of chunk inr](warfarin_analysis-figure/inr-1.png)

Change in INR
========================================================
![plot of chunk inr2](warfarin_analysis-figure/inr2-1.png)

Time in Therapeutic Range
========================================================
![plot of chunk ttr](warfarin_analysis-figure/ttr-1.png)

Time with Critical INR Values
========================================================
![plot of chunk time_above4](warfarin_analysis-figure/time_above4-1.png)

Hemoglobin Response
========================================================
![plot of chunk hgb](warfarin_analysis-figure/hgb-1.png)

Change in Hemoglobin
========================================================
![plot of chunk hgb2](warfarin_analysis-figure/hgb2-1.png)

Historical Comparison
========================================================

* Pharmacy Dosing Service 2015 vs. 2013-2014
* Same inclusion and exclusion criteria

Historical Demographics
========================================================

|                               |current              |historical           |p     |
|:------------------------------|:--------------------|:--------------------|:-----|
|n                              |402                  |866                  |      |
|Age (median [IQR])             |58.00 [42.25, 68.75] |59.00 [46.00, 71.00] |0.048 |
|Sex = Male (%)                 |240 (59.7)           |505 (58.3)           |0.685 |
|BMI (mean (sd))                |29.95 (8.50)         |29.90 (9.26)         |0.926 |
|Race (%)                       |                     |                     |0.189 |
|-   African American           |104 (28.4)           |245 (31.2)           |      |
|-   Asian                      |12 ( 3.3)            |15 ( 1.9)            |      |
|-   Latin American             |0 ( 0.0)             |1 ( 0.1)             |      |
|-   Other                      |78 (21.3)            |133 (16.9)           |      |
|-   White/Caucasian            |172 (47.0)           |392 (49.9)           |      |
|-Length of Stay (median [IQR]) |12.10 [7.71, 19.83]  |11.85 [7.38, 18.62]  |0.172 |
|Therapy = New/Previous (%)     |270/132 (67.2/32.8)  |604/262 (69.7/30.3)  |0.390 |

Utilization by Medical Services
========================================================
![plot of chunk ds_med_service](warfarin_analysis-figure/ds_med_service-1.png)

Anticoagulation Indications
========================================================
![plot of chunk indications_hist](warfarin_analysis-figure/indications_hist-1.png)

Disposition
========================================================
![plot of chunk disposition_hist](warfarin_analysis-figure/disposition_hist-1.png)

INR Response
========================================================
![plot of chunk inr_hist](warfarin_analysis-figure/inr_hist-1.png)

Time in Therapeutic Range
========================================================
![plot of chunk ttr_hist](warfarin_analysis-figure/ttr_hist-1.png)

Time Critical INR
========================================================
![plot of chunk critical_hist](warfarin_analysis-figure/critical_hist-1.png)

Hemoglobin Response
========================================================
![plot of chunk hgb_hist](warfarin_analysis-figure/hgb_hist-1.png)

Change in Hemoglobin
========================================================
![plot of chunk hgb2_hist](warfarin_analysis-figure/hgb2_hist-1.png)
