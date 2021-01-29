
**************************************************
	// 1) Webscrape-- 2015q4 to present events
**************************************************	

import delimited "Data\BLM Protests\protests_scrape.csv", varnames(1) clear 
duplicates drop

// Remove Sport and Political Protests
	split subject, parse("| ")
	local subjects = r(varlist)
	foreach s in `subjects'{
	
		drop if `s' == "National Anthem"
		drop if `s' == "Donald Trump"
		drop if `s' == "NFL"
		drop if `s' == "Trump"
		drop if `s' == "Neo-Nazism"
		drop if `s' == "Milo Yiannopoulos"
		drop if `s' == "Minimum Wage"
		drop if `s' == "Confederate Symbols"
		drop if `s' == "Confederacy"
		drop if `s' == "Ben Shapiro"
		drop if `s' == "Bill Clinton"
		drop if `s' == "Hillary Clinton"
		drop if `s' == "White Nationalism"
		
	}
	drop `subjects'
	
// Remove Non-In-Person Meetings, Sport and Political Protests
	split desc, parse(" " "|")
	local descs = r(varlist)
	foreach s in `descs'{
	
		drop if `s' == "WNBA's"
		drop if `s' == "WNBA"
		drop if `s' == "NFL"
		drop if `s' == "basketball"
		drop if `s' == "anthem"
		drop if `s' == "boycott"
	}
	drop `descs'


// State
	split location, parse("| ")
	rename location3 stabb
	replace stabb=location2 if stabb==""
	
// delete all nonstates, identified by having more than 2 characters. These are outside of the USA.
	cap drop test
	gen test = strlen(stabb)
	drop if test>2
	
// City
	rename location2 city
	cap drop test
	gen test = strlen(city)
	replace city = location1 if test==2
	replace city = subinstr(city, "|", "",.) 

// Participants (popnum)
	g popnum=.
	split participants, parse("-" " ")
	local dummies = r(varlist)
	foreach d in `dummies'{
		
		replace `d' = lower(`d')
		replace `d' = subinstr(`d', "+", "",.)  
		replace `d' = subinstr(`d', "+", "",.)  
		destring `d', gen(_`d') force
		
		replace popnum = _`d' if popnum == .
		replace popnum = 200 if `d' == "hundreds"
		replace popnum = 2000 if `d' == "thousands"
		replace popnum = 24 if `d' == "dozens"

		drop _`d'
	}
	drop `dummies'
	
// Year
	split date, parse("| ")
	destring date3, gen(year)
	sum year
	assert r(min)==2014

// Quarter
	split date2
	gen qtr=1
	replace qtr=2 if(date21=="April"|date21=="May"|date21=="June")
	replace qtr=3 if(date21=="July"|date21=="August"|date21=="September")
	replace qtr=4 if(date21=="October"|date21=="November"|date21=="December")
	replace qtr=year*10+qtr
	sum qtr
	assert r(min)==20143

//Month
	gen month = 1 if date21 == "January"
	replace month = 2 if date21 == "February"
	replace month = 3 if date21 == "March"
	replace month = 4 if date21 == "April"
	replace month = 5 if date21 == "May"
	replace month = 6 if date21 == "June"
	replace month = 7 if date21 == "July"
	replace month = 8 if date21 == "August"
	replace month = 9 if date21 == "September"
	replace month = 10 if date21 == "October"
	replace month = 11 if date21 == "November"
	replace month = 12 if date21 == "December"
	mdesc month
	assert r(percent) == 0
	
// Day
	destring date22, gen(day)

// Date
	drop date*
	gen date = year * 10000 + month * 100 +day
	
// Drop events during published data timeframe: before September 2015
	drop if date < 20150901
	keep city stabb qtr popnum date
	
// Clean city name
	replace city="Ithaca" if city=="Ithaca CollegeIthaca"
	replace city="Louisville" if city=="Lousville"
	replace city="Washington" if stabb=="DC"
	replace city="Salt Lake City" if city=="Salt Lake"
	replace city="San Francisco" if city=="San Fransico"|city=="San Franciso"
	replace city="Portland" if city=="Porland"	
	replace city="Foxborough" if city=="Foxboro"
	replace city="Tucson" if city=="Tuscon"
	replace city="St. Joseph" if city=="St Joseph"
	replace city="New York" if city=="Bronx"|city=="Brooklyn"|city=="Manhattan"|city=="New York City"|city=="Staten Island"
	replace city="College Station" if city=="Bryan/College Station"
	replace city="Fort Lauderdale" if city=="Ft. Lauderdale"
	replace city = strtrim(city)
	
// save tempfile to append to published data
	tempfile temp
	save `temp', replace



**************************************************
	// 2) Append BLM Harvard -- 2014 events
**************************************************

//Data downloaded on 5/17/2019 from https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/L2GSK6
	import excel "Data\BLM Protests\BLM_protests_2014.08.09-2015.08.09.xlsx", sheet("BLM_protests_2014.08.09-2015.08") firstrow allstring clear case(lower) 
	
//generate qtr
	split date, parse("/")
	destring date1, replace
	destring date3, replace
	gen qtr=date3*10+floor((date1-1)/3)+1

// Date
	drop date
	destring date2,replace
	g date = date3*10000 + date1*100 + date2
	
// Protest size
	replace popnum="" if popnum=="NA"
	destring popnum, replace

//Append webscrape
	rename st stabb
	keep city stabb qtr popnum date fips
	append using `temp'	
	drop if city==""|stabb==""
	
**************************************************
	          // 3) Match FIPS
**************************************************

* Clean harvard fips data
gsort + stabb city - fips
bys stabb city: replace fips = fips[_n-1] if inlist(fips,"")
destring fips, gen(FIPS)
drop fips
g fips =  string(FIPS,"%07.0f")
replace fip = "" if strlen(trim(fips))!=7

* Test correct fips
merge m:1  fips using DTA/fips, keep(1 3)  
replace fips = "" if inlist(_merge,1)
drop _merge

* Merge by matching variable "City"
merge m:1 city stabb using DTA/fips, keep(1 3 4 5) nogen replace update

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
	opencagegeo, key(${key}) city(city) state(stabb) country(country) // 2,5000 max calls per 24 hours
	destring g_lat, gen(Latitude)
	destring g_lon, gen(Longitude)
	save `temp', replace
restore
merge m:1 stabb city using `temp' , keep(1 3) nogen

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
drop if fips==""
append using `success'

* save daily file
g protests=1
collapse (sum)  protests popnum  (first) stabb city qtr, by(fips date)	
replace popnum = . if popnum == 0
order fips stabb city date
sort fips date
compress
save "DTA/Protest_Daily", replace

* Collapse into quarterly data	
collapse (sum) protests popnum (first) stabb city, by(fips qtr)
replace popnum = . if popnum == 0
compress
save DTA/Protests, replace	

	
