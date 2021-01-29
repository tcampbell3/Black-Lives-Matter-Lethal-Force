
* ORI9 FIPS crosswalk -> Protest count
use DTA/backbone, clear
keep ORI7 fips
drop if inlist(ORI7,"-1","")
tempfile ORI7_FIPS
save `ORI7_FIPS', replace

* Annual protest
use "DTA/protests", clear
g year = int(round(qtr/10))
gcollapse (sum) protests popnum, by(fips year)
tempfile blm
save `blm', replace

* Open Crime backbone
use DTA/Crimes, clear

* Merge FIPS
merge m:1 ORI7 using `ORI7_FIPS', nogen keep(1 3) keepus(fips)

* Merge BLM protests
merge m:1 fips year using `blm', nogen keep(1 3) keepus(protests popnum)
drop if inlist(fips,"")
replace protests = 0 if inlist(protest,.)
replace popnum = 0 if inlist(popnum,.)

* Define treated, donor, treatment
bys ORI7 (year): gen cum_protests = sum(protests)
bys ORI7 (year): egen total_protests = sum(protests)	
gen treated=(total_protests>=1)
gen donor=(total_protests==0)
gen treatment = (cum_protests>0)

* Save Body Cam Data
gegen unit = group(ORI7)
order ORI7 unit fips year
sort ORI7 year
compress
save DTA/Agency_panel_crime, replace