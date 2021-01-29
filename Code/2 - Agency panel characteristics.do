
* ORI9 FIPS crosswalk -> Protest count
use DTA/backbone, clear
keep ORI9 fips
drop if inlist(ORI9,"-1","")
tempfile ORI9_FIPS
save `ORI9_FIPS', replace

* Annual protest
use "DTA/protests", clear
g year = int(round(qtr/10))
gcollapse (sum) protests popnum, by(fips year)
tempfile blm
save `blm', replace

* Open LEMAS backbone
use DTA/LEMAS_2013, clear
append using DTA/LEMAS_2016

* Merge fips
merge m:1 ORI9 using `ORI9_FIPS', nogen keep(1 3) keepus(fips)

* Merge BLM protests
merge m:1 fips year using `blm', nogen keep(1 3) keepus(protests popnum)
drop if inlist(fips,"")
replace protests = 0 if inlist(protest,.)
replace popnum = 0 if inlist(popnum,.)

* Define treated, donor, treatment
bys ORI9 (year): gen cum_protests = sum(protests)
bys ORI9 (year): egen total_protests = sum(protests)	
gen treated=(total_protests>=1)
gen donor=(total_protests==0)
gen treatment = (cum_protests>0)

* Drop agency characteristics that are not repeated in each survey
foreach var of varlist  ag_* {
	cap drop _test
	bys ORI9: gegen _test = count(`var')
	sum `test', meanonly
	if r(max) !=2{
		drop `var'
	}
}

* Drop agencies that are incomplete for all agency characteristics
cap drop _test*
foreach var of varlist  ag_* {
	bys ORI9: gegen _test_`var' = count(`var')
}
by ORI9: gegen _test = max(_test*)
drop if !inlist(_test,2)
drop _test*

* Make totals
foreach v of varlist ag_officers_male ag_officers_white ag_officers_black ag_new_officers ag_cp_nsara ag_cp_npatrol{
	g `v'_total = `v' * ag_officers
}

* Save Body Cam Data
gegen unit = group(ORI9)
rename FINALWT weight
order ORI9 unit fips year
sort ORI9 year
compress
save DTA/Agency_panel_characteristics, replace