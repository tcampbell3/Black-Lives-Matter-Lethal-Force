

****** 1) Setup data **********

* Import data
clear all
cd "${user}\Data\Law Enforcement Management and Administrative Statistics"
unzipfile "LEMAS 2016 Body Camera", replace
use "ICPSR_37302/DS0001/37302-0001-Data", clear
do "ICPSR_37302/DS0001/37302-0001-Supplemental_syntax.do"
cd "${user}"

****** 2) Define Variables **********

* Sampling strata
rename STRATA strata

* Location (recode agency names with missing ORI number to match backbone)
g agency = upper(AGENCY_NAME)
rename AGENCY_STATE stabb
replace agency = "PINE BEACH POLICE" if inlist(agency, "BOROUGH OF PINE BEACH POLICE DEPARTMENT")
rename CITY city

* Body cameras
g ag_bodycam = Q_11_Y*10 + floor((Q_11_M-1)/3) +1
replace ag_bodycam = 20001 if ag_bodycam < 20001 & ag_bodycam != .

* Recode variables as zero if agency reports not having body worn cameras
foreach v of varlist ag_* {
	replace `v' = 0 if Q_10A == 2
}



****** 3) Reformat to quarterly dataset **********

* Keep what is needed
drop if inlist(ORI9,"")
drop if ag_bodycam == .
keep ORI9 ag_* FINAL strata Q16M*

* Collapse into ORI means
gcollapse ag_* Q16M* FINAL strata [aw=FINAL] , by(ORI9)

* make Quarterly panel from 2000-2016
expand 68
bys ORI9: gen year = 2000+ floor((_n-1)/4) 
bys ORI9 year: g qtr = _n
replace qtr = year * 10 + qtr

* Fix dummy
replace ag_bodycam = qtr >= ag_bodycam & ag_bodycam!=0

****** 3) Clean and Save **********

* save file
compress
save DTA/LEMAS_body_cam, replace

* Delete unused directory to save memory
sleep 5000
shell rmdir "Data/Law Enforcement Management and Administrative Statistics/ICPSR_37302" /s /q
cap rmdir "Data/Law Enforcement Management and Administrative Statistics/ICPSR_37302"


