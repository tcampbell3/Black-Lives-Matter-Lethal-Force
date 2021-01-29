
**** 1) Merge police agency level data ****

* Open backbone
use DTA/backbone, clear
unique fips ORI9 ORI7 stname agency
assert r(N) == r(unique)
expand 20														// 20 years, 4 qtr (2000-2019)
bys fips ORI9 ORI7 stname agency: g year = 2000+_n-1

* Merge Lemas
tempfile temp
forvalues y = 2013(3)2016{

	if `y' == 2013{
		local ORI = "ORI7"
	}
	else{
		local ORI = "ORI9"
	}

	preserve
		use DTA/LEMAS_`y', clear
		drop if inlist(`ORI',"")
		save `temp', replace
	restore

	merge m:1 `ORI' year using `temp', nogen 	update
	
	preserve
		use DTA/LEMAS_`y', clear
		drop if !inlist(`ORI',"")
		save `temp', replace
	restore

	merge m:1 agency year using `temp', nogen 	update

}

* Merge Crimes
merge m:1 ORI7 year using DTA/Crimes, nogen keep(1 3)

* Merge LEMAS body worn camera supplement
expand 4
bys fips ORI9 ORI7 stname agency year: g qtr = _n
replace qtr = year*10 + qtr
merge m:1 ORI9 qtr using DTA/LEMAS_body_cam, nogen 	update

* Collapse into city-qtr means
ds fips qtr agency ORI9 ORI7 agency_type stname city stnum stabb FINALWT, not
local vars = r(varlist)
replace ORI9 = "" if ORI9 =="-1"
replace ORI7 = "" if ORI7 =="-1"
replace FINALWT=1 if FINALWT==.
drop if inlist(fips,"")
gcollapse (mean) `vars' [aw=FINALWT], by(fips qtr)
save `temp', replace


**** 2) City level data ****

* Open Population Data
use DTA/Population, clear
merge m:1 fips qtr using `temp', nogen keep(1 3)

* Population Screen
bys fips: egen dummy = min(popest)
drop if dummy<20000|popest==.
drop dummy

* Merge BLM Protets
merge 1:1 fips qtr using DTA/Protests, nogen keep(1 3)

* Merge Fatal Encounters
merge 1:1 fips qtr using DTA/Fatel_Encounters_Quarterly, nogen keep(1 3)

* Merge ACS 5 year
merge m:1 fips year using DTA/ACS_5yr, nogen keep(1 3)
foreach v in acs_hispanic acs_white acs_black{
	g `v'_total = `v'
	replace `v' = `v'_total / popestimate
	replace `v' = 1 if `v'>1
}

* Mapping Police Violence
merge 1:1 fips qtr using DTA/Mapping_Police_Quarterly, nogen keep(1 3)

* Merge Number of Police
merge m:1 fips year using DTA/ASPE, nogen keep(1 3 4 5) update

* Merge Voting Data (no data for WV and MT)
merge m:1 fips using DTA/vote, nogen keep(1 3)

* Merge Historic Protest Data
merge m:1 fips using DTA/Historic_Protests, nogen keep(1 3)

* merge with census region
merge m:1 stabb using "DTA/census_region", nogen keep(1 3)

* merge with geography
merge m:1 fips using DTA/size_00, nogen keep(1 3)
merge m:1 fips using DTA/size_10, nogen keep(1 3)
foreach var in geo_housing geo_land{
	g `var'=`var'_10
	replace `var'=`var'_00 if year<2010
	drop `var'_10 `var'_00
}


**** 3) Define variables ****

* Replace missing values with zeros for protests and killings
foreach var of varlist  homicides* protests* h_* {
	replace `var' = 0 if `var' == .
}
replace popnum =0 if protest==0

* Define Treated
bys fips: egen total_protests = sum(protests)
gen treated=(total_protests>=1)
gen donor=(total_protests==0)

* Define Treatment
gen treatment = (protest>0)
bys fips (qtr): replace treatment=treatment[_n-1] if treatment[_n-1] == 1

* Per capita outcomes
foreach var of varlist homicides* {
	gen `var'_p=`var'/popestimate
}	

* Population Density
bys fips (qtr): replace geo_housing=geo_housing[_n-1] if geo_housing==.
bys fips (qtr): replace geo_land=geo_land[_n-1] if geo_land==.
gen geo_density_pop_house=popestimate/geo_housing
gen geo_density_pop_land=popestimate/geo_land
gen geo_density_house_land=geo_housing/geo_land

* Coarsen Controls
g ag_policing= (ag_officers)/popestimate
g crime = (crime_violent + crime_property)/popestimate
g crime_officer_safety = (crime_officer_felony+crime_officer_assaulted)/ag_officers
replace crime_officer_safety =1 if crime_officer_safety >1
fastxtile  pop_c=popestimate, n(10) 
foreach var of varlist acs_* crime* ag_officers ag_policing{
	fastxtile `var'_c = `var', n(10)
}

* gen qtr of year FE
cap drop season
g season=qtr-year*10

* Save Summary Data
sort fips qtr
aorder
order fips stname city qtr treated treatment donor
compress
save DTA/Summary, replace
