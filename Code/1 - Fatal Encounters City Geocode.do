
********* Fatal Encounters ***********

cd "${user}"
import excel "Data\Police Killings\FATAL ENCOUNTERS.xlsx", firstrow clear case(lower)

* Fix typo
destring latitude, gen(Latitude)
destring longitude, gen(Longitude)
drop latitude longitude
replace Longitude = -Longitude if Longitude>0

* Fatal encounters - mapping police violence crosswalk
tempname tempframe
frame put  Latitude Longitude uniqueid, into(`tempframe')
frame `tempframe'{
	rename uniqueid fatalencountersid
	save DTA/fatal_encounters_geocode, replace
}
frame drop `tempframe'

* Delte Non-fact checked encounters
gen nofactcheck=(subjectsname=="Items below this row have not been fact-checked.") // <- gives row
gen dummyrow=_n
sum dummyrow if nofactcheck==1
drop if dummyrow>=r(mean)

* Names
foreach var in age name gender race{
	rename subjects`var' `var'
}
foreach var in city county zipcode{
rename locationofdeath`var' `var'
}
rename locationofdeathstate stabb
rename locationofinjuryaddress street
rename agency agency

* Date
gen year=year(dateofinjuryresultingindeat)
gen month=month(dateofinjuryresultingindeat)
g day = day(dateofinjuryresultingindeat)
drop if year >2019

* Drop suicides
gen dummy = dispositionsexclusionsinternal
split dummy, parse(" " "/")
local variables=r(varlist)
foreach var in `variables'{
	drop if `var'=="Suicide" | `var' == "suicide"
}
drop dummy*

* Drop certain causes of death
replace cause=proper(cause)
split cause, parse("/")
ds cause*
local vars `r(varlist)'
local omit causeofdeath1
local want : list vars - omit 
drop `want'
rename causeofdeath1 causeofdeath
replace cause= "Other" if cause=="Drug Overdose"
replace cause= "Other" if cause=="Burned"
replace cause= "Other" if cause=="Drowned"
replace cause= "Other" if cause=="Fell From A Height"
replace cause= "Other" if cause=="Stabbed"
replace cause= "Other" if cause=="Medical Emergency"
replace cause= "Other" if cause=="Criminal"
replace cause= "Other" if cause=="Undetermined"
replace cause= "Other" if cause==""
replace cause="Taser" if cause=="Tasered"
replace cause="Pepper Spray" if cause=="Chemical Agent"

* Local City Department
g homicides_local = 1 
g dummy = agency
split dummy, parse(" " ",")
foreach var of varlist dummy* {
	replace homicides_local = 0 if `var' == "County" | `var' == "State"
}
drop dummy*

* keep whats used
keep homicides_local age name gender race city stabb zipcode county street agency causeofdeath year month day Longitude Latitude


********* Pie Graph All Cases***********

* save total fatel encounters
tempname scs
file open `scs' using "Output\Notes\total_fatal_encounters_all_cases.txt", text write replace
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
pie(7, color(midblue)) plabel(7 percent, size(*1.5) color(white)) plabel(7 name, size(*1.5) color(white) gap(-7cm)) 
graph export "Output/piegraph_fatal_encounter_all_cases.pdf", replace


********* Pie Graph ***********

* Relabel & verify only correct causes kept
drop if cause=="Other"|cause=="Vehicle"
keep if inlist(cause,"Asphyxiated","Beaten","Pepper Spray","Gunshot","Taser")
assert r(N_drop)==0 	// verify only these causes remain

* save total fatel encounters
tempname scs
file open `scs' using "Output\Notes\total_fatal_encounters.txt", text write replace
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
graph export "Output/piegraph_fatal_encounter.pdf", replace


************* PLACE FIPS *******************

* merge crosswalk
merge m:1 stabb city using DTA/fips, keep(1 3) nogen

* Save success to append later
preserve
	keep if fips!=""
	tempfile success
	save `success', replace
restore

keep if fips==""

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

* Append success
append using `success'

* Make data qtryly
sort stabb year month
cap drop qtr
gen qtr=year*10+floor((month-1)/3)+1

* keep what is needed
keep homicides_local name fips stabb city qtr month day year Longitude Latitude

*save full geocoded data
save "DTA/Fatel_Encounters_Geo", replace


********* Daily and Quarterly Files ***********

* Outcomes
g homicides = 1

* save daily file
drop if fips==""
g date = year*10000+month*100+day
collapse (sum) homicides* (first) stabb city qtr, by(fips date)	
order fips stabb city date
sort fips date
compress
save "DTA/Fatel_Encounters_Daily", replace

* save quarterly file
collapse (sum) homicides* (first) stabb city , by(fips qtr)
order fips stabb city qtr
sort fips qtr
compress
save "DTA/Fatel_Encounters_Quarterly", replace
