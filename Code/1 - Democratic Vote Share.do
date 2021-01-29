* Prior Estimates
import delimited "Data\Election\City_Votes.csv", clear
gen stfips=string(fips_st,"%02.0f")
gen placefips=string(fips_place,"%05.0f")
gen fips = stfips+placefips
collapse (sum) democrat=dem republican=rep (first) stfips, by(fips)


**** States with missing data in City_Votes dataset ****
* AR (05)
drop if stfips=="05" // make sure no double counting
preserve
	use "Data/Election/AR_2008.dta", clear
	rename precinct city
	* remove numbers
	forvalues i=0/9{
		replace city = subinstr(city, " `i'", "",.) 
		replace city = subinstr(city, "`i'", "",.) 
	}
	* clean city
	replace city = subinstr(city, "'", "",.) 
	replace city=proper(city)
	replace city = subinstr(city, "&", "and",.) 
	replace city = subinstr(city, "N.", "North",.) 
	replace city = subinstr(city, "W.", "West",.) 
	replace city = subinstr(city, "E.", "East",.) 
	replace city = subinstr(city, "S.", "South",.)
	replace city = subinstr(city, " Absenteee", "",.)
	replace city = subinstr(city, "Absenteee", "",.) 
	replace city = subinstr(city, "Saint", "St.",.) 
	foreach word in City Town Rural Ward{
		replace city = subinstr(city, " `word'", "",.) 
	}
	gen lastletter=substr(city,-1,1)
	foreach word in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z{
		replace city = subinstr(city, "`word' ", "",.) 
		replace city = subinstr(city, "`word', ", "",.) 
		replace city = subinstr(city, "`word',", "",.) 
		replace city = subinstr(city, "`word'/", "",.) 
		replace city = subinstr(city, "`word'-", "",.) 
		replace city = subinstr(city, "`word';", "",.) 
		replace city = subinstr(city, "`word'.", "",.) 
	replace city = subinstr(city, "`word'", "",.)  if lastletter=="`word'"
	}
	replace city = subinstr(city, ".", "",.) 
	replace city = subinstr(city, "(", "",.) 
	replace city = subinstr(city, ")", "",.) 
	replace city = subinstr(city, "#", "",.) 
	
	*Parse
	gen dummy=city
	split dummy, parse(" - " " / " ", " "-" "/" "," "Rm")
	replace dummy1=dummy2 if county=="Little River County"|county=="Mississippi County"
	forvalues i=2/20{
		cap replace dummy1=dummy`i' if dummy1==""|dummy1==" "
	}
	* Some palces have large number of spaces seperating locality name
	split dummy1, parse("  ")
	replace city=dummy11
	replace city=dummy2 if county=="Little River County"|county=="Mississippi County"
	replace city=strtrim(city)	// remove leading and ending blanks
	drop if city==""
	collapse (sum) republican=g2008_USP_rv democrat=g2008_USP_dv (first) county, by(state city)
	rename state stabb
	merge 1:1 stabb city using DTA/fips, keep(1 3) nogen
	tempfile temp
	save `temp', replace
restore
append using `temp'
	
	
* MA (25)
drop if stfips=="25" // make sure no double counting
preserve
	use "Data/Election/New England/MA_2008.dta", clear
	rename state stabb
	rename town city
	replace city = subinstr(city, "N.", "North",.) 
	replace city = subinstr(city, "W.", "West",.) 
	replace city = subinstr(city, "E.", "East",.) 
	replace city = subinstr(city, "S.", "South",.) 
	replace city = "Agawam Town" if city == "Agawam"
	replace city = "Amesbury Town" if city == "Amesbury"
	replace city = "Barnstable Town" if city == "Barnstable"
	replace city = "Braintree Town" if city == "Braintree"
	replace city = "Easthampton Town" if city == "Easthampton"
	replace city = "Framingham Town" if city == "Framingham"
	replace city = "Franklin Town" if city == "Franklin"
	replace city = "Greenfield Town" if city == "Greenfield"
	replace city = "Methuen Town" if city == "Methuen"
	replace city = "Palmer Town" if city == "Palmer"
	replace city = "Southbridge Town" if city == "Southbridge"
	replace city = "Watertown Town" if city == "Watertown"
	replace city = "West Springfield Town" if city == "West Springfield"
	replace city = "Weymouth Town" if city == "Weymouth"
	replace city = "Winthrop Town" if city == "Winthrop"
	collapse (sum) republican=g2008_USP_rv democrat=g2008_USP_dv, by(stabb city)
	merge 1:1 stabb city using DTA/fips, keep(1 3) nogen
	tempfile temp
	save `temp', replace
restore
append using `temp'

* ME (23)
drop if stfips=="23" // make sure no double counting
preserve
	use "Data/Election/New England/ME_2008.dta", clear
	rename state stabb
	rename town city
	replace city = subinstr(city, "'", "",.) 
	replace city = proper(city)
	replace city = subinstr(city, "S.", "South",.) 
	replace city = subinstr(city, " Plt.", "",.) 
	replace city = subinstr(city, " Twp.", "",.) 
	replace city = subinstr(city, " Twps.", "",.) 
	replace city = "Isle au Haut" if city == "Isle Au Haut"
	replace city = "Madawaska" if city == "Madawaska Lake"
	collapse (sum) republican=g2008_USP_rv democrat=g2008_USP_dv, by(stabb city)
	merge 1:1 stabb city using DTA/fips, keep(1 3) nogen
	tempfile temp
	save `temp', replace
restore
append using `temp'
	
* RI (44)
drop if stfips=="44" // make sure no double counting
preserve
	use "Data/Election/New England/RI_2008.dta", clear
	rename state stabb
	rename town city
	collapse (sum) republican=g2008_USP_rv democrat=g2008_USP_dv, by(stabb city)
	merge 1:1 stabb city using DTA/fips, keep(1 3) nogen
	tempfile temp
	save `temp', replace
restore
append using `temp'

* DC (11)
drop if stfips=="11" // make sure no double counting
preserve
	use "Data/Election/DC_2008.dta", clear
	collapse (sum) republican=g2008_USP_rv democrat=g2008_USP_dv, by(state)
	rename state stabb
	merge 1:m stabb using DTA/fips, keep(1 3) nogen
	tempfile temp
	save `temp', replace
restore
append using `temp'

* GA (13)
drop if stfips=="13" // make sure no double counting
preserve
	use "Data/Election/GA_2008.dta", clear
	rename precinct city
	* remove numbers
	forvalues i=0/9{
		replace city = subinstr(city, " `i'", "",.) 
		replace city = subinstr(city, "`i'", "",.) 
	}
	* clean city
	replace city = subinstr(city, "'", "",.) 
	replace city=proper(city)
	replace city = subinstr(city, "&", "and",.) 
	replace city = subinstr(city, "N.", "North",.) 
	replace city = subinstr(city, "W.", "West",.) 
	replace city = subinstr(city, "E.", "East",.) 
	replace city = subinstr(city, "S.", "South",.)
	replace city = subinstr(city, " Absenteee", "",.)
	replace city = subinstr(city, "Absenteee", "",.) 
	replace city = subinstr(city, "Saint", "St.",.) 
	foreach word in City Town Rural Ward{
		replace city = subinstr(city, " `word'", "",.) 
	}
	gen lastletter=substr(city,-1,1)
	foreach word in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z{
		replace city = subinstr(city, "`word' ", "",.) 
		replace city = subinstr(city, "`word', ", "",.) 
		replace city = subinstr(city, "`word',", "",.) 
		replace city = subinstr(city, "`word'/", "",.) 
		replace city = subinstr(city, "`word'-", "",.) 
		replace city = subinstr(city, "`word';", "",.) 
		replace city = subinstr(city, "`word'.", "",.) 
		replace city = subinstr(city, "`word'", "",.)  if lastletter=="`word'"

	}
	replace city = subinstr(city, ".", "",.) 
	replace city = subinstr(city, "(", "",.) 
	replace city = subinstr(city, ")", "",.) 
	replace city = subinstr(city, "#", "",.)
	* Parse
	gen dummy=city
	split dummy, parse(" - " " / " ", " "-" "/" "," "Rm")
	forvalues i=2/20{
		cap replace dummy1=dummy`i' if dummy1==""|dummy1==" "
	}
	* Some palces have large number of spaces seperating locality name
	split dummy1, parse("  ")
	replace city=dummy1
	replace city=strtrim(city)	// remove leading and ending blanks
	drop if city==""
	collapse (sum) republican=g2008_USP_rv democrat=g2008_USP_dv (first) county, by(state city)
	rename state stabb
	merge 1:1 stabb city using DTA/fips, keep(1 3) nogen
	tempfile temp
	save `temp', replace
restore
append using `temp'


* KY (21)
drop if stfips=="21" // make sure no double counting
preserve
	use "Data/Election/KY_2008.dta", clear
	rename precinct city
	* remove numbers
	forvalues i=0/9{
		replace city = subinstr(city, " `i'", "",.) 
		replace city = subinstr(city, "`i'", "",.) 
	}
	* clean city
	replace city = subinstr(city, "'", "",.) 
	replace city=proper(city)
	replace city = subinstr(city, "&", "and",.) 
	replace city = subinstr(city, "N.", "North",.) 
	replace city = subinstr(city, "W.", "West",.) 
	replace city = subinstr(city, "E.", "East",.) 
	replace city = subinstr(city, "S.", "South",.)
	replace city = subinstr(city, " Absenteee", "",.)
	replace city = subinstr(city, "Absenteee", "",.) 
	replace city = subinstr(city, "Saint", "St.",.) 
	replace city = subinstr(city, "  ", " ",.) 
	foreach word in City Town Rural Ward{
		replace city = subinstr(city, " `word'", "",.) 
	}
	gen lastletter=substr(city,-1,1)
	foreach word in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z{
		replace city = subinstr(city, "`word' ", "",.) 
		replace city = subinstr(city, "`word', ", "",.) 
		replace city = subinstr(city, "`word',", "",.) 
		replace city = subinstr(city, "`word'/", "",.) 
		replace city = subinstr(city, "`word'-", "",.) 
		replace city = subinstr(city, "`word';", "",.) 
		replace city = subinstr(city, "`word'.", "",.) 
		replace city = subinstr(city, "`word'", "",.)  if lastletter=="`word'"

	}
	foreach word in a b c d e{
		replace city = "Somerset" if city=="Somerset`word'"
	}
	replace city = subinstr(city, ".", "",.) 
	replace city = subinstr(city, "(", "",.) 
	replace city = subinstr(city, ")", "",.) 
	replace city = subinstr(city, "#", "",.)
	* Parse
	gen dummy=city
	split dummy, parse(" - " " / " ", " "-" "/" "," "Rm")
	forvalues i=2/20{
		cap replace dummy1=dummy`i' if dummy1==""|dummy1==" "
	}
	* Some palces have large number of spaces seperating locality name
	split dummy1, parse("  ")
	replace city=dummy1
	replace city=strtrim(city)	// remove leading and ending blanks
	drop if city==""
	collapse (sum) republican=g2008_USP_rv democrat=g2008_USP_dv (first) county, by(state city)
	rename state stabb
	merge 1:1 stabb city using DTA/fips, keep(1 3) nogen
	tempfile temp
	save `temp', replace
restore
append using `temp'

* MT

* OR (41)
drop if stfips=="41" // make sure no double counting
preserve
	use "Data/Election/OR_2008.dta", clear
	rename precinct_name city
	* remove numbers
	forvalues i=0/9{
		replace city = subinstr(city, " `i'", "",.) 
		replace city = subinstr(city, "`i'", "",.) 
	}
	* clean city
	replace city = subinstr(city, "'", "",.) 
	replace city=proper(city)
	replace city = subinstr(city, "&", "and",.) 
	replace city = subinstr(city, "N.", "North",.) 
	replace city = subinstr(city, "W.", "West",.) 
	replace city = subinstr(city, "E.", "East",.) 
	replace city = subinstr(city, "S.", "South",.)
	replace city = subinstr(city, " Absenteee", "",.)
	replace city = subinstr(city, "Absenteee", "",.) 
	replace city = subinstr(city, "Saint", "St.",.) 
	replace city = subinstr(city, "  ", " ",.) 
	foreach word in City Town Rural Ward{
		replace city = subinstr(city, " `word'", "",.) 
	}
	gen lastletter=substr(city,-1,1)
	foreach word in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z{
		replace city = subinstr(city, "`word' ", "",.) 
		replace city = subinstr(city, "`word', ", "",.) 
		replace city = subinstr(city, "`word',", "",.) 
		replace city = subinstr(city, "`word'/", "",.) 
		replace city = subinstr(city, "`word'-", "",.) 
		replace city = subinstr(city, "`word';", "",.) 
		replace city = subinstr(city, "`word'.", "",.) 
		replace city = subinstr(city, "`word'", "",.)  if lastletter=="`word'"

	}
	foreach word in a b c d e{
		replace city = "Somerset" if city=="Somerset`word'"
	}
	replace city = subinstr(city, ".", "",.) 
	replace city = subinstr(city, "(", "",.) 
	replace city = subinstr(city, ")", "",.) 
	replace city = subinstr(city, "#", "",.)
	* Parse
	gen dummy=city
	split dummy, parse(" - " " / " ", " "-" "/" "," "Rm")
	forvalues i=2/20{
		cap replace dummy1=dummy`i' if dummy1==""|dummy1==" "
	}
	* Some palces have large number of spaces seperating locality name
	split dummy1, parse("  ")
	replace city=dummy1
	replace city=strtrim(city)	// remove leading and ending blanks
	drop if city==""
	collapse (sum) republican=g2008_USP_rv democrat=g2008_USP_dv (first) county, by(state city)
	rename state stabb
	merge 1:1 stabb city using DTA/fips, keep(1 3) nogen
	tempfile temp
	save `temp', replace
restore
append using `temp'

* UT (49)
drop if stfips=="49" // make sure no double counting
preserve
	use "Data/Election/UT_2008.dta", clear
	rename precinct city
	* remove numbers
	forvalues i=0/9{
		replace city = subinstr(city, " `i'", "",.) 
		replace city = subinstr(city, "`i'", "",.) 
	}
	* clean city
	replace city = subinstr(city, "'", "",.) 
	replace city=proper(city)
	replace city = subinstr(city, "&", "and",.) 
	replace city = subinstr(city, "N.", "North",.) 
	replace city = subinstr(city, "W.", "West",.) 
	replace city = subinstr(city, "E.", "East",.) 
	replace city = subinstr(city, "S.", "South",.)
	replace city = subinstr(city, " Absenteee", "",.)
	replace city = subinstr(city, "Absenteee", "",.) 
	replace city = subinstr(city, "Saint", "St.",.) 
	replace city = subinstr(city, "  ", " ",.) 
	foreach word in City Town Rural Ward{
		replace city = subinstr(city, " `word'", "",.) 
	}
	gen lastletter=substr(city,-1,1)
	foreach word in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z{
		replace city = subinstr(city, "`word' ", "",.) 
		replace city = subinstr(city, "`word', ", "",.) 
		replace city = subinstr(city, "`word',", "",.) 
		replace city = subinstr(city, "`word'/", "",.) 
		replace city = subinstr(city, "`word'-", "",.) 
		replace city = subinstr(city, "`word';", "",.) 
		replace city = subinstr(city, "`word'.", "",.) 
		replace city = subinstr(city, "`word'", "",.)  if lastletter=="`word'"

	}
	foreach word in a b c d e{
		replace city = "Somerset" if city=="Somerset`word'"
	}
	replace city = subinstr(city, ".", "",.) 
	replace city = subinstr(city, "(", "",.) 
	replace city = subinstr(city, ")", "",.) 
	replace city = subinstr(city, "#", "",.)
	replace city = "Salt Lake City" if county=="Salt Lake"
	* Parse
	gen dummy=city
	split dummy, parse(":" "," "-" "/")
	forvalues i=2/20{
		cap replace dummy1=dummy`i' if dummy1==""|dummy1==" "
	}
	* Some palces have large number of spaces seperating locality name
	split dummy1, parse("  ")
	replace city=dummy1
	replace city=strtrim(city)	// remove leading and ending blanks
	drop if city==""
	gen test=strlen(city)
	drop if test<3
	collapse (sum) republican=g2008_USP_rv democrat=g2008_USP_dv (first) county, by(state city)
	rename state stabb
	merge 1:1 stabb city using DTA/fips, keep(1 3) nogen
	drop if county=="Weber County"
	tempfile temp
	save `temp', replace
restore
append using `temp'


* Save dataset (all states + DC except WV)
preserve
	keep if fips!=""
	collapse (sum) republican democrat, by(fips)
	save DTA/vote, replace
restore

* Forward Geocode unmatched
keep if fips==""
gen country="United States of America"
gen n=_n

	* create 3 datasets
	preserve
		keep if n<=2500
		save DTA/temp1, replace
	restore
	
	preserve
		keep if n <= 5000 & n > 2500
		save DTA/temp2, replace
	restore
	
	preserve
		keep if n > 5000
		save DTA/temp3, replace
	restore


use DTA/temp1, clear
opencagegeo, key(${key1}) city(city) state(stabb) country(country) county(county) // 2,500 max calls per 24 hours
destring g_lat, gen(Latitude)
destring g_lon, gen(Longitude)
save DTA/temp1_geo,replace

use DTA/temp2, clear
opencagegeo, key(${key2}) city(city) state(stabb) country(country) county(county) // 2,500 max calls per 24 hours
destring g_lat, gen(Latitude)
destring g_lon, gen(Longitude)
save DTA/temp2_geo,replace

use DTA/temp3, clear
opencagegeo, key(${key3}) city(city) state(stabb) country(country) county(county) // 2,500 max calls per 24 hours
destring g_lat, gen(Latitude)
destring g_lon, gen(Longitude)
save DTA/temp3_geo,replace



* stack geocoded temp files
use DTA/temp1_geo, clear
forvalues i=2/3{
	append using DTA/temp`i'_geo
}

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

keep stabb city republican democrat fips
drop if fips==""
append using DTA/vote
collapse (sum) republican democrat , by(fips)
g pol_dem_share = democrat / (democrat+republican)
rename democrat pol_democrat
rename republican pol_republican
save DTA/vote,replace

