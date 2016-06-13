Warfarin Pharmacy Dosing Service Analysis
========================================================
author: Brian Gulbis
date: June 2016
autosize: true

Annual Warfarin Utilization
========================================================






![plot of chunk graph_utilization](warfarin_analysis-figure/graph_utilization-1.png)

Utilization of Pharmacy Warfarin Dosing Service
========================================================
![plot of chunk dose_service_use](warfarin_analysis-figure/dose_service_use-1.png)

Utilization of Pharmacy Warfarin Dosing Service
========================================================
![plot of chunk dose_service_use2](warfarin_analysis-figure/dose_service_use2-1.png)

Utilization by Medical Service
========================================================
![plot of chunk graph_services](warfarin_analysis-figure/graph_services-1.png)

Dosing Service Utilization by Medical Service
========================================================
![plot of chunk ds_med_service_curr](warfarin_analysis-figure/ds_med_service_curr-1.png)

Utilization by Hospital Unit
========================================================
![plot of chunk graph_locations](warfarin_analysis-figure/graph_locations-1.png)

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

Demographics
========================================================

|                     |pharmacy             |traditional          |p      |
|:--------------------|:--------------------|:--------------------|:------|
|n                    |402                  |287                  |       |
|Age (Median [Iqr])   |58.00 [42.25, 68.75] |64.00 [54.00, 72.00] |<0.001 |
|Sex = Male (%)       |240 (59.7)           |183 (64.0)           |0.290  |
|Race (%)             |                     |                     |0.093  |
|-   African American |104 (28.4)           |74 (27.7)            |       |
|-   Asian            |12 ( 3.3)            |1 ( 0.4)             |       |
|-   Native Am.       |0 ( 0.0)             |1 ( 0.4)             |       |
|-   Other            |78 (21.3)            |59 (22.1)            |       |
|-   White/Caucasian  |172 (47.0)           |132 (49.4)           |       |
|Length of Stay       |12.10 [7.71, 19.83]  |13.71 [8.02, 24.12]  |0.110  |

Anticoagulation Indications
========================================================
![plot of chunk indications](warfarin_analysis-figure/indications-1.png)

Disposition
========================================================
![plot of chunk disposition](warfarin_analysis-figure/disposition-1.png)

Changes in INR
========================================================
![plot of chunk inr](warfarin_analysis-figure/inr-1.png)

Time in Therapeutic Range
========================================================
![plot of chunk ttr](warfarin_analysis-figure/ttr-1.png)

Time with Critical INR Values
========================================================
![plot of chunk time_above4](warfarin_analysis-figure/time_above4-1.png)

Changes in Hemoglobin
========================================================
![plot of chunk hgb](warfarin_analysis-figure/hgb-1.png)

Historical Comparison
========================================================

* January 1, 2013 to December 31, 2014
* Same inclusion and exclusion criteria

Historical Demographics
========================================================

|                     |pharmacy             |traditional          |p      |
|:--------------------|:--------------------|:--------------------|:------|
|n                    |866                  |894                  |       |
|Age (Median [Iqr])   |59.00 [46.00, 71.00] |62.00 [51.00, 73.00] |<0.001 |
|Sex = Male (%)       |505 (58.3)           |526 (58.9)           |0.840  |
|Race (%)             |                     |                     |0.434  |
|-   African American |245 (31.2)           |228 (28.1)           |       |
|-   Asian            |15 ( 1.9)            |13 ( 1.6)            |       |
|-   Latin American   |1 ( 0.1)             |0 ( 0.0)             |       |
|-   Native Am.       |0 ( 0.0)             |1 ( 0.1)             |       |
|-   Other            |133 (16.9)           |131 (16.2)           |       |
|-   White/Caucasian  |392 (49.9)           |437 (54.0)           |       |
|Length of Stay       |11.85 [7.38, 18.62]  |10.94 [6.89, 17.28]  |0.024  |

Dosing Service Utilization by Medical Service (vs. Historical)
========================================================
![plot of chunk ds_med_service](warfarin_analysis-figure/ds_med_service-1.png)

Anticoagulation Indications (vs. Historical)
========================================================
![plot of chunk indications_hist](warfarin_analysis-figure/indications_hist-1.png)

Disposition (vs. Historical)
========================================================
![plot of chunk disposition_hist](warfarin_analysis-figure/disposition_hist-1.png)

Changes in INR (vs. Historical)
========================================================
![plot of chunk inr_hist](warfarin_analysis-figure/inr_hist-1.png)

Time in Therapeutic Range (vs. Historical)
========================================================
![plot of chunk ttr_hist](warfarin_analysis-figure/ttr_hist-1.png)

Time Critical INR (vs. Historical)
========================================================
![plot of chunk critical_hist](warfarin_analysis-figure/critical_hist-1.png)

Changes in Hemoglobin (vs. Historical)
========================================================
![plot of chunk hgb_hist](warfarin_analysis-figure/hgb_hist-1.png)

