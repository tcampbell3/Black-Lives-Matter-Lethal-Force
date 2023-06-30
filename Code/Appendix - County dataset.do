clear all
tempfile temp
tempvar tframe
cd "${user}"

* Backbone
use "Data\Geography\county_adjacency2010.dta", clear
split countyname, parse(", ")
drop if inlist(countyname2,"PR","VI","MP","AS","GU")
drop countyname1 countyname2
rename fipsneighbor fips_c
split neighborname, parse(", ")
rename neighborname1 county
rename neighborname2 stabb
replace county = substr(county, 1, length(county) - 7)

* Crosswalk: County name -> county fips for police killings data
frame put county stabb fips_c, into(`tframe')
frame `tframe'{
	gduplicates drop
	tempfile cross
	save `cross',replace
}

* Import county population
frame `tframe'{
	import delimited "Data\Population\2000-2010-population.csv", clear
	keep if sumlev == 050 
	keep state county popest*
	save `temp', replace
	import delimited "Data\Population\2010-2020-population.csv", clear
	keep if sumlev == 050 
	merge 1:1 state county using `temp', nogen
	save `temp', replace
	import delimited "Data\Population\2020-2021-population.csv", clear
	keep if sumlev == 050 
	merge 1:1 state county using `temp', nogen
	g dummy = state*1000 + county 
	g fips_c = string(state, "%02.0f")  + string(county, "%03.0f") 
	keep fips_c popestimate20*
	order fips_c popest*, alpha
	save `temp', replace
}
merge m:1 fips_c using `temp', keep(1 3) nogen
greshape long popestimate, i(fipscounty fips_c) j(year)

* Expand data
expand 4
bys fipscounty fips_c year: g quarter=_n
g qtr=year*10+quarter
drop quarter year

* Merge county protests
frame `tframe'{

	* Match census county to census place
	import delimited "Data\Geography\census_place_county.csv", varnames(2) clear
	drop if inlist(placecode,.,99999)
	g fips = string(statecode, "%02.0f")  + string(placecode, "%05.0f") 
	g fips_c =  string(countycode, "%05.0f") 
	keep fips*
	
	* Quarterly data
	expand 22
	bys fips*: g year=1999+_n
	expand 4
	bys fips* year: g qtr=year*10+_n

	* Merge protests
	merge m:1 fips qtr using "DTA\Protests", nogen keep(1 3)
	gcollapse (sum) protests participants, by(fips_c qtr)
	save `temp', replace
}
merge m:1 fips_c qtr using `temp', keep(1 3) nogen

* Merge county lethal force
frame `tframe'{
	* Open data and merge crosswalk
	use "DTA/Fatel_Encounters_Geo", clear
	merge m:1 stabb county using `cross', keep(1 3) nogen
	
	* Save success to append later
	preserve
		keep if fips_c!=""
		tempfile success
		save `success', replace
	restore
	keep if fips_c==""

	* Geocode county fips with long and lat
	cd "Data/Geography"
	unzipfile tl_2010_us_county10.zip
	sleep 10000
	shp2dta using "tl_2010_us_county10.shp" ,data("cb_data.dta") ///
		coor("cb_coor.dta") genid(cid) gencentroids(cent) replace
	geoinpoly Latitude Longitude using "cb_coor.dta"
	cap drop cid
	rename _ID cid
	merge m:1 cid using "cb_data.dta", nogen keep(1 3)
	replace fips_c = STATEFP + COUNTYFP if fips_c == ""
	cap erase "tl_2010_us_county10.dbf"
	cap erase "tl_2010_us_county10.prj"
	cap erase "tl_2010_us_county10.shp"
	cap erase "tl_2010_us_county10.shp.xml"
	cap erase "tl_2010_us_county10.shx"
	cap erase "cb_coor.dta"
	cap erase "cb_data.dta"
	cd ../..	
	append using `success'
	
	* Aggregate and save
	g homicides=1
	gcollapse (sum) homicides, by(fips_c qtr)
	save `temp', replace
}
merge m:1 fips_c qtr using `temp', keep(1 3) nogen

* Clean and save
replace protests=0 if inlist(protest,.)
replace homicides=0 if inlist(homicides,.)
replace participants=0 if inlist(participants,.)
compress
save DTA/Counties, replace