* Save LEMAS data
use DTA/LEMAS_2013, clear
append using DTA/LEMAS_2016
drop if inlist(ORI9, "")
bys ORI9: gegen test=count(FINAL)
keep if inlist(test,2)
drop test
tempfile temp
save `temp', replace

* ORI9 FIPS crosswalk -> Protest count
use DTA/backbone, clear
drop if inlist(ORI9,"-1","")
expand 22
bys id: g year=_n+1999
expand 4
bys id: g qtr=year*10+_n
drop if inlist(ORI7,"-1")

* Merge BLM protests
merge m:1 fips qtr using DTA/protests, nogen keep(1 3) keepus(protests participants)
replace protests = 0 if inlist(protest,.)
replace participants = 0 if inlist(participants,.)
gcollapse (sum) protests participants, by(ORI9 year) 

* Drop agencies without protests ever
bys ORI9 (year): gegen total_protests_2021 = sum(protests)
drop if inlist(total_protests_2021,0) 

* Merge LEMAS 
merge 1:1 ORI9 year using `temp', keep(3) nogen

* Define treated, donor, treatment
bys ORI9 (year): g cum_protests = sum(protests)
bys ORI9 (year): gegen total_protests = sum(protests)	
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

* Adjust stata (random sampling in stata for less than 100 officers. All agencies asked above 100 officers.)
gegen unit = group(ORI9)
replace strata = strata + unit*1000 if inlist(strata,101,201,301)

* Replace strings with coded numeric to save storage space
encode ORI9, gen(ori9)
drop ORI9

* Coursen controls
fasterxtile  pop_c=population, n(10)

* Save dataset
rename FINALWT weight
order unit ori9 year
gsort unit ori9 year
compress
save DTA/Agency_panel_characteristics, replace
