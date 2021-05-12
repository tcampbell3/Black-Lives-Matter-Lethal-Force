
cd "${user}"
tempfile temp

********* Mapping Police Violence ***********

import excel "Data\Police Killings\MPVDatasetDownload.xlsx", firstrow clear case(lower)

* merge FE longitude and latitude
merge m:1 fatalencountersid using "DTA/fatal_encounters_geocode", keep(1 3) nogen

* Rename variables
foreach var in age name gender race{
	rename victims`var' `var'
}
rename state stabb
rename dateofin date
rename street street
rename agency agency
rename oria ORI9
g video= !inlist(trim(bodycam),"No") if !inlist(bodycam,"")

* Date
gen year=year(date)
gen month=month(date)
gen day=day(date)
drop if year>2019

* keep what is used
keep age name gender race city stabb zipcode county street agency causeofdeath unarmed year month day Lat Long ORI9 video
drop if name==""

* Relabel certain causes of death (so FE data match up since these typically are not from police homicides)
replace cause=proper(cause)
split cause, parse("/" ",")
ds cause*
local vars `r(varlist)'
local omit causeofdeath1
local want : list vars - omit 
drop `want'
rename causeofdeath1 causeofdeath
replace cause= "Other" if inlist(cause,"Drug Overdose","Drowned","Fall To Death","Undetermined","Unknown","Bomb", "Death In Custody","Hanging")

* Relabel & verify only correct causes kept
replace cause="Asphyxiated" if cause=="Physical Restraint"
replace cause="Beaten" if inlist(cause,"Baton","Bean Bag","Beanbag Gun", "Beating")
replace cause="Taser" if cause=="Tasered"


********* Pie Graph All Cases***********

* save total fatel encounters
tempname scs
file open `scs' using "Output\Notes\total_mapping_police_all_cases.txt", text write replace
sum year if year>=2013
local output=r(N)
di %15.0fc `output'
file write `scs' `" `: display %15.0fc `output' ' "' _n

* police killings pie graph
graph pie if year>=2013 ,over(causeofdeath)  legend(size(small)) scheme(plotplain) ///
legend(subtitle("N = `output'",position(11))) ///
pie(1,  color(olive_teal)) ///
pie(2, color(green)) ///
pie(3, color(red%75)) plabel(3 percent, size(*1.5) color(white)) plabel(3 name, size(*1.5) color(white) gap(-7cm)) ///
pie(4, color(orange)) ///
pie(5,  color(teal)) ///
pie(6, color(purple)) ///
pie(7, color(midblue))
graph export "Output/piegraph_mapping_police_all_cases.pdf", replace


********* Pie Graph ***********
preserve

	* Relabel & verify only correct causes kept
	drop if cause=="Other"|cause=="Vehicle"
	keep if inlist(cause,"Asphyxiated","Beaten","Pepper Spray","Gunshot","Taser")

	* save total fatal encounters
	tempname scs
	file open `scs' using "Output\Notes\total_mapping_police.txt", text write replace
	sum year if year>=2013
	local output=r(N)
	di %15.0fc `output'
	file write `scs' `" `: display %15.0fc `output' ' "' _n

	* police killings pie graph
	graph pie if year>=2013 ,over(causeofdeath)  legend(size(small)) scheme(plotplain) ///
	legend(subtitle("N = `output'",position(11))) ///
	pie(1,  color(olive_teal)) ///
	pie(2, color(green)) ///
	pie(3, color(red%75)) plabel(3 percent, size(*1.5) color(white)) plabel(3 name, size(*1.5) color(white) gap(-7cm)) ///
	pie(4, color(teal)) ///
	pie(5,  color(purple)) 
	graph export "Output/piegraph_mapping_police.pdf", replace
	
restore

************* PLACE FIPS *******************

* merge crosswalk
merge m:1 stabb city using DTA/fips, keep(1 3) nogen

* Save success to append later
preserve
	keep if fips!=""
	tempfile success
	save `success', replace
restore

* Save failures that are geocoded
keep if fips==""
drop if city == "" | stabb == ""
preserve
	keep if Longitude!=.
	tempfile geocode
	save `geocode', replace
restore

* Forward Geocode unmatched
keep if Longitude==.
preserve
	keep city stabb
	duplicates drop
	gen country="United States of America"
	opencagegeo, key(${key}) city(city) state(stabb) country(country) // 2,500 max calls per 24 hours
	destring g_lat, gen(Latitude)
	destring g_lon, gen(Longitude)
	save `temp', replace
restore
merge m:1 stabb city using `temp' , keep(1 3) nogen update
	
* keep accurate data
drop if g_quality<4 // data not accurate at city level or less

* keep precise data (within approx 12.5 miles)
destring g_confidence, replace
drop if g_confidence<3 // precision below 20km

* Append geocoded failures from above
append using `geocode'

* geocode place fips with long and lat
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
keep if fips !=""

* Append success
append using `success'

* Make data qtryly
sort stabb year month
cap drop qtr
gen qtr=year*10+floor((month-1)/3)+1

* Full file
save "DTA/Mapping_Police_Geo", replace


********* Daily and Quarterly Files ***********

* Outcomes
destring age, replace force
g homicides_mpv = 1
g homicides_black_mpv =(race=="African-American/Black"|race=="Black")
g homicides_white_mpv =(race=="European-American/White"|race=="European-American/White"|race=="White")
g homicides_other_race_mpv =(race!="Unknown Race"|race!="Unknown race"|race != "Race unspecified")
replace homicides_other_race_mpv = 0 if homicides_white == 1 | homicides_black == 1
g homicides_female_mpv =(gender=="Female"|gender=="Femalr")
g homicides_male_mpv =(gender=="Male")
g homicides_armed_mpv = (unarmed=="Allegedly Armed")
g homicides_unarmed_mpv = (unarmed=="Unarmed")
g homicides_black_male_mpv =(gender=="Male"&race=="African-American/Black"|race=="Black"&gender=="Male")
g homicides_young_black_male_mpv =(gender=="Male"&race=="African-American/Black"&age<35|gender=="Male"&race=="Black"&age<35)
g homicides_young_male_mpv =(gender=="Male"&age<35)
g homicides_gun_mpv = (causeofdeath=="Gunshot")

* save daily file
drop if fips==""
g date = mdy(month,day,year)
format date %d
preserve
	keep fips date name
	bys fips date: g j=_n
	greshape wide name, i(fips date) j(j)
	g name=name1
	foreach v of varlist name*{
		if !inlist("`v'","name1","name"){
			replace name=name+","+`v' if !inlist(`v',"")
		}
	}
	keep name fips date
	tempfile temp
	save `temp',replace
restore
collapse (sum) homicides* video (first) stabb city qtr, by(fips date)
merge 1:1 fips date using `temp', nogen
order fips stabb city date
sort fips date
compress
save "DTA/Mapping_Police_Daily", replace

* save quarterly file
collapse (sum) homicides* video (first) stabb city , by(fips qtr)
order fips stabb city qtr
sort fips qtr
compress
save "DTA/Mapping_Police_Quarterly", replace


