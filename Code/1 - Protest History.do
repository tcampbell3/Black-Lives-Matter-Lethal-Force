
* import data
use "Data/Historic Protest/final_data_v10.dta", clear

* outcomes
gen h_protest=1

* Pro-Black civil rights protest
gen h_black_civil = 0
forvalues i = 1/4{
	replace h_black_civil = 1 if claim`i' >= 1500 & claim`i' < 1600 & claim`i' !=. & val`i' == 1
}

* Pro-Anti-police Brutality (all races)
gen h_police_brutality = 0
forvalues i = 1/4{
	replace h_police_brutality =1 if claim`i' == 1518 & val`i' == 1 | claim`i' == 1611 & val`i' == 1 | claim`i' == 1708 & val`i' == 1 | claim`i' == 1808 & val`i' == 1 | claim`i' == 1912 & val`i' == 1 | claim`i' == 2006 & val`i' == 1
}

* Black Initating Protest (any type of protest)
gen h_black_protest =0
forvalues i = 1/3{
	replace h_black_protest = 1 if igrp`i'c1 == 401
	replace h_black_protest = 1 if igrp`i'c2 == 401
}

* Racist events
gen h_racist_attacks = 0
forvalues i = 1/3{
	replace h_racist_attacks = 1 if claim`i' >= 2500  & claim`i' < 2525 & claim`i' !=. & val`i' == 1
}
gen h_racist_protests = 0
forvalues i = 1/3{
	* Against black civil rights
	replace h_racist_protests = 1 if claim`i' >= 1500 & claim`i' < 1600 & claim`i' !=. & val`i' == 2
	* Against other races civil rights
	replace h_racist_protests = 1 if claim`i' >= 1700 & claim`i' < 2100 & claim`i' !=. & val`i' == 2 
}

* reshape
keep h_* state1 state2 city1 city2
g i = _n
reshape long city state, i(i) j(test)
drop if city=="" | state ==""

* cleanup city
replace city=proper(city)
replace city = "Washington" if state=="DC"
replace state = "DC" if city == "Washington" 
replace city="New York" if city=="Bronx"&state=="NY"|city=="Brooklyn"&state=="NY"|city=="Manhattan"&state=="NY"|city=="New York City"&state=="NY"|city=="Staten Island"&state=="NY"|city=="Queens"&state=="NY"
drop if city==""|state==""
rename state  stabb
replace stabb = "WA" if stabb == "Washington"
replace city = subinstr(city, "Saint", "St.",.)  
drop if city=="Unknown"|city=="Statewide"

* total
collapse (sum)  h_* , by(stabb city)

	
	
	
	
	
	
	
	
	
*** Merge ***	

* merge
merge m:1 city stabb using DTA/fips, keep(1 3) nogen // 75% match

* Save successful matches to append later
preserve
	drop if fips==""
	tempfile success
	save `success', replace
restore

* Forward Geocode unmatched
keep if fips==""
preserve
	keep city stabb
	duplicates drop
	gen country="United States of America"
	local key="${key}" // exires in one month. See https://opencagedata.com/dashboard
	opencagegeo, key(`key') city(city) state(stabb) country(country) // 2,5000 max calls per 24 hours
	destring g_lat, gen(Latitude)
	destring g_lon, gen(Longitude)
	tempfile temp
	save `temp', replace
restore
merge m:1 stabb city using `temp' , keep(1 3) nogen update

* keep accurate data
drop if g_quality<4 // data not accurate at city level or less

* keep precise data (within approx 12.5 miles)
destring g_confidence, replace
drop if g_confidence<3 // precision below 20km

* Reverse Geocode
cd Data/Geography/2018
forvalues i = 1/78{
	local j : di %02.0f `i'
	cap confirm file "tl_2018_`j'_place/tl_2018_`j'_place.shp"
	if _rc == 0{
	sleep 1000
	shp2dta using "tl_2018_`j'_place/tl_2018_`j'_place.shp" ,data("cb_data.dta") coor("cb_coor.dta") genid(cid) gencentroids(cent) replace
	geoinpoly Latitude Longitude using "cb_coor.dta"
	cap drop cid
	rename _ID cid
	merge m:1 cid using "cb_data.dta", nogen keep(1 3)
	replace fips = STATEFP + PLACEFP if fips == ""
	drop x_cent y_cent STATEFP PLACEFP GEOID
	}
}
cd ../../..
keep if fips !=""


* Save Final Dataset
append using `success'
drop if fips==""
collapse (sum) h_* (first) city stabb, by(fips)
order fips stabb city 
compress
save DTA/Historic_Protests, replace	
	
	
	
	

	
	
	
	
