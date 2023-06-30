* Setup
tempfile temp
tempvar tframe
frame create `tframe'

**** 1) Merge police agency level data ****

* Open backbone
use DTA/backbone, clear
expand 20														// 20 years, 4 qtr (2000-2019)
bys id: g year = 2000+_n-1

* Count crimes by census fips, merge later
preserve
	merge m:1 ORI7 year using DTA/Crimes, nogen keep(1 3)
	gcollapse (nansum) crime_*, by(fips year)
	tempfile ucr
	save `ucr', replace
restore

* Merge Lemas
frame `tframe'{
	use DTA/LEMAS_2013, clear
	drop if inlist(ORI7,"")
	save `temp', replace
}
merge m:1 ORI7 year using `temp', nogen keep(1 3)

* Merge LEMAS body worn camera supplement
expand 4
bys id year: g qtr = _n
replace qtr = year*10 + qtr
merge m:1 ORI9 qtr using DTA/LEMAS_body_cam, nogen keep(1 3)

* Collapse into city-qtr means
ds fips qtr agency ORI9 ORI7 agency_type stname city stnum stabb FINALWT, not
local vars = r(varlist)
replace ORI9 = "" if ORI9 =="-1"
replace ORI7 = "" if ORI7 =="-1"
replace FINALWT=1 if FINALWT==.
drop if inlist(fips,"")
gcollapse (mean) `vars' [aw=FINALWT], by(fips qtr)

* Merge UCR
merge m:1 fips year using  `ucr', nogen
save `temp', replace

**** 2) City level data ****

* Open Population Data
use DTA/Population, clear
merge m:1 fips qtr using `temp', nogen keep(1 3)

*  Twitter
frame `tframe'{
	use DTA/Twitter, clear
	gcollapse (rawsum) tweet_ct=sub_tweet_counts (mean) tweet_polarity = sub_polarity [aw=sub_twe], by(fips year) 
	save `temp', replace
}
merge m:1 fips year using `temp', nogen keep(1 3)

* Population Screen
bys fips: gegen dummy = min(popest)
drop if dummy<20000|popest==.
drop dummy

* Merge BLM Protets
merge 1:1 fips qtr using "DTA/protests", nogen keep(1 3)

* Merge Fatal Encounters
merge 1:1 fips qtr using DTA/Fatel_Encounters_Quarterly, nogen keep(1 3)

* Merge ACS 5 year
merge m:1 fips year using DTA/ACS_5yr, nogen keep(1 3)
replace acs_black_pov = acs_black_pov*100
foreach v in acs_hispanic acs_white acs_black{
	g `v'_total = `v'
	replace `v' = min(`v'_total / popestimate * 100, 100) if !inlist(`v'_total,.)
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

* Replace missing values with zeros for protests, killings, and tweets
foreach var of varlist  homicides* protests* h_* video tweet* {
	replace `var' = 0 if `var' == .
}
replace participants =0 if protests==0

* Define Treated
bys fips: egen total_protests = sum(protests)
gen treated=(total_protests>=1)
gen donor=(total_protests==0)

* Define Treatment
gen treatment = (protests>0)
bys fips (qtr): replace treatment=treatment[_n-1] if treatment[_n-1] == 1

* Per capita outcomes
foreach var of varlist homicides* {
	gen `var'_p=`var'/popestimate
}

* Crime rates
g ag_policing= (ag_officers)/popestimate
g crime = (crime_violent_rpt + crime_property_rpt)/popestimate
g crime_officer_safety = min((crime_officer_felony+crime_officer_assaulted)/ag_officers, 1)
foreach v of varlist crime_property* crime_murder* crime_violent* {
	replace `v' = `v' / popestimate
}

* Population Density
bys fips (qtr): replace geo_housing=geo_housing[_n-1] if geo_housing==.
bys fips (qtr): replace geo_land=geo_land[_n-1] if geo_land==.
gen geo_density_pop_house=popestimate/geo_housing
gen geo_density_pop_land=popestimate/geo_land
gen geo_density_house_land=geo_housing/geo_land

* Coarsen Controls
fasterxtile  pop_c=popestimate, n(10) 
foreach var of varlist acs_* crime* ag_officers ag_policing{
	fasterxtile `var'_c = `var', n(10)
}

* Save Summary Data
sort fips qtr
aorder
order fips stname city qtr treated treatment donor
drop population strata id FINALWEIGHT											// unused variables
compress
save DTA/Summary, replace
