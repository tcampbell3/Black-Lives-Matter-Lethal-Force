
********* Fatal Encounters ***********

cd "${user}"
import excel "Data\Police Killings\FATAL ENCOUNTERS.xlsx", firstrow clear case(lower)
drop if inlist(uniqueid,.)

* Fix typo
replace latitude = subinstr(latitude, ",", "",.)
destring latitude, gen(Latitude)
destring longitude, gen(Longitude)
drop latitude longitude

* Fatal encounters - mapping police violence crosswalk
tempname tempframe
frame put Latitude Longitude uniqueid, into(`tempframe')
frame `tempframe'{
	rename uniqueid fatalencountersid
	save DTA/fatal_encounters_geocode, replace
}
frame drop `tempframe'

* Names
foreach var in city county zipcode{
rename locationofdeath`var' `var'
}
rename state stabb
rename locationofinjuryaddress street
rename agency agency

* Date
gen year=year(dateofinjuryresultingindea)
gen month=month(dateofinjuryresultingindea)
g day = day(dateofinjuryresultingindea)

* Drop suicides
gen dummy = dispositionsexclusionsinternal
split dummy, parse(" " "/")
local variables=r(varlist)
foreach var in `variables'{
	drop if `var'=="Suicide" | `var' == "suicide"
}
drop dummy*

* Drop certain causes of death
rename highestlevelof causeofdeath
replace cause=proper(cause)
replace cause="Asphyxiation" if inlist(cause,"Asphyxiated/Restrained", "Asphyxiation/Restrain", "Restrain/Asphyxiation","Asphyxiation/Restrained")
replace cause= "Other" if cause=="Drug Overdose"
replace cause= "Other" if cause=="Drug overdose"
replace cause= "Other" if cause=="Burned"
replace cause= "Other" if cause=="Drowned"
replace cause= "Other" if cause=="Fell From A Height"
replace cause= "Other" if cause=="Stabbed"
replace cause= "Other" if cause=="Medical Emergency"
replace cause= "Other" if cause=="Less-Than-Lethal Force"
replace cause= "Other" if cause=="Undetermined"
replace cause= "Other" if cause=="Burned/Smoke Inhalation"
replace cause= "Other" if cause==""
replace cause= "Beaten/Bludgeoned" if cause=="Beaten/Bludgeoned With Instrument"
replace cause="Taser" if cause=="Tasered"

* keep whats used
keep age name gender race city stabb zipcode county street agency causeofdeath year month day Longitude Latitude

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
pie(4, color(red%75)) plabel(4 percent, size(*1.5) color(white)) plabel(4 name, size(*1.5) color(white) gap(-7cm)) ///
pie(3, color(orange)) ///
pie(5,  color(teal)) ///
pie(6, color(purple)) ///
pie(7, color(midblue)) plabel(7 percent, size(*1.5) color(white)) plabel(7 name, size(*1.5) color(white) gap(-7cm)) 
graph export "Output/piegraph_fatal_encounter_all_cases.pdf", replace


********* Pie Graph ***********

* Relabel & verify only correct causes kept
drop if cause=="Other"|cause=="Vehicle"

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
pie(4, color(red%75)) plabel(4 percent, size(*1.5) color(white)) plabel(4 name, size(*1.5) color(white) gap(-7cm)) ///
pie(3, color(teal)) ///
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
keep  name fips stabb city county qtr month day year Longitude Latitude

*save full geocoded data
save "DTA/Fatel_Encounters_Geo", replace


********* Daily and Quarterly Files ***********

* Outcomes
g homicides = 1

* save daily file
drop if fips==""
g date = mdy(month,day,year)
format date %d
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
