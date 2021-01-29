
* ORI9 FIPS crosswalk -> Protest count
use DTA/backbone, clear
keep ORI9 fips
drop if inlist(ORI9,"-1","")
tempfile temp
save `temp', replace

* Open bodycam backbone
use DTA/LEMAS_body_cam, clear

* Merge FIPS
merge m:1 ORI9 using `temp', nogen keep(1 3) keepus(fips)

* Merge BLM protests
merge m:1 fips qtr using DTA/protests, nogen keep(1 3) keepus(protests popnum)
drop if inlist(fips,"")
replace protests = 0 if inlist(protest,.)
replace popnum = 0 if inlist(popnum,.)

* Define treated, donor, treatment
bys ORI9 (qtr): gen cum_protests = sum(protests)
bys ORI9 (qtr): egen total_protests = sum(protests)	
gen treated=(total_protests>=1)
gen donor=(total_protests==0)
gen treatment = (cum_protests>0)

* Save Body Cam Data
gegen unit = group(ORI9)
rename FINALWEIGHT weight
order ORI9 unit fips qtr year
sort ORI9 year
compress
save DTA/Agency_panel_bodycam, replace