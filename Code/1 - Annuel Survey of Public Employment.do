

clear
cd "${user}"
tempfile temp

*Loop over years until no more, creating ID file, employment file, merging, then appending

local true = 0
local i = -1
while `true' < 1{

	local i=`i'+1
	local j : di %02.0f `i'
	cap confirm file "Data/Annual Survey of Public Employment/ID/`j'empid.txt"
	if _rc==0{
	
		****   ID File   ****
	
		infix str id 1-14 str city 15-78 region 79-79 str county 80-109 str stnum 110-111 str county_fips 112-114 str place_fips 115-119 fips_msa 120-123 csma_fips 124-125 ///
			using "Data/Annual Survey of Public Employment/ID/`j'empid.txt", clear

		* City
		replace city = proper(city) // lower case all but first letter of each word

		* Keep correct level (Rest -> Municipal)
		gen code = substr(id,3,1)
		keep if code == "2" 

		* Gernerate fips (place fips works for both new england also)
		gen fips = stnum + place_fips

		* clean up
		keep id city stnum fips
		compress
		save `temp', replace


		****   Employment File   ****

		* Import employment data
		if `j'<7{
			infix str id 1-14 str code 18-20  full_time_emp 21-30 full_time_pay 31-42 part_time_emp 43-52 part_time_pay 53-64 part_time_hours 65-74 full_time_eqv_emp 75-84 ///
				using "Data/Annual Survey of Public Employment/Employment/`j'empst.txt", clear
		}
		else{
			infix str id 1-14  str code 18-20  full_time_emp 21-30 full_time_pay 33-44 part_time_emp 47-56 part_time_pay 59-70 part_time_hours 73-82 full_time_eqv_emp 85-94 ///
				using "Data/Annual Survey of Public Employment/Employment/`j'empst.txt", clear
		}
		* generate wage - Total pay over total hours, assuming full time cops work 40 hours a week. 
		gen ag_wage = (full_time_pay)/(full_time_emp*40*(31/7)) // payroll is over march, 31 days
		label var ag_wage "Average Police Wage"

		* number of cops
		rename full_time_emp ag_officers
		label var ag_officers "Number of full time police"

		* keep police officers only
		keep if code=="062"

		* merge with id
		merge 1:1 id using `temp', keep(3) nogen

		* clean up
		keep ag_officers ag_wage city stnum fips
		gen year = 20`j'
		order fips stnum city year
		compress
		save `temp', replace
		
		
		****   Append Files   ****
		
		if `j' == 0 {
			preserve
		}
		else {
			restore
			append using `temp'
			
			* test for correctness
			unique stnum
			assert r(unique) == 51
			
			preserve
		}
		
		
	}
	else{
		* End Loop
		local true = 1
		restore
		
		* test for correctness
		unique stnum
		assert r(unique) == 51

	}
}


	
****   Fix FIPS   ****

* test for fips of length 2
gen test = strlen(fips)
destring fips, gen(FIPS)

* create variable of places FIPs code if ever correct, starting in 2007, stops includnig place fips
replace FIPS = . if test == 2
by stnum city (FIPS), sort: replace FIPS = FIPS[_n-1] if FIPS == .
cap drop corrected
gen corrected = string(FIPS, "%07.0f") if stnum != "15" & FIPS!=.
replace corrected = string(FIPS, "%05.0f") if stnum == "15"
replace fips= corrected

* Remove some duplicate observations and deal with places that report different obs for same year
gduplicates drop
collapse (first) fips (sum) ag_officers (mean) ag_wage [aw=ag_officers], by(stnum city year)
order fips


****   MERGE FIPS   ****

* fix typos
replace city="Foxborough" if city=="Foxboro"
replace city="La Fayette" if city=="Lafayette"
replace city="Washington" if city=="District of Columbia"
replace city="New York" if city=="Bronx"|city=="Brooklyn"|city=="Manhattan"|city=="New York City"|city=="Staten Island"|city=="Staten Island New York"
replace city = subinstr(city, " (Wendover)", "",.)	
replace city = subinstr(city, "/", "-",.)
replace city = subinstr(city, ",", "-",.) 
replace city = subinstr(city, "Mt ", "Mt. ",.) 
replace city = subinstr(city, "St ", "St. ",.) 
drop if stnum==""|city==""
	
* merge missing fips
preserve
	use DTA/fips, clear
	replace city=proper(city)
	save `temp',replace
restore
merge m:1 stnum city using `temp', keep(1 3 4 5) nogen update

* merge state abbriviations
merge m:1 stnum using DTA/statecode, nogen keep(1 3 4 5) update

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
	geocodeopen, key(${key}) city(city) state(stabb)
	save `temp', replace
restore
merge m:1 stabb city using `temp' , keep(1 3) nogen

* keep high enough quality
keep if inlist(geo_quality,"CITY")
drop geo_*

* Reverse Geocode
cd Data/Geography/2018
forvalues i = 1/78{
	local j : di %02.0f `i'
	cap confirm file "tl_2018_`j'_place/tl_2018_`j'_place.shp"
	if _rc == 0{
	sleep 1000
	shp2dta using "tl_2018_`j'_place/tl_2018_`j'_place.shp" ,data("cb_data.dta") coor("cb_coor.dta") genid(cid) gencentroids(cent) replace
	geoinpoly latitude longitude using "cb_coor.dta"
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
collapse (sum) ag_officers (mean) ag_wage (first) city stabb [aw=ag_officers], by(fips year)
order fips stabb city year
compress
save DTA/ASPE, replace


