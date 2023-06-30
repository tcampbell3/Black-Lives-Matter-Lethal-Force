
cd "${user}"
tempfile temp

********* Mapping Police Violence ***********

import delimited "C:\Users\travi\Dropbox\BLM Lethal Force\Data\Police Killings\Mapping Police Violence.csv", delimiter(comma) encoding(UTF-8) clear   bindquote(strict)

* Rename variables
rename state stabb
rename street street
rename agency agency
rename ori ORI9
rename latitude Latitude
rename longitude Longitude
rename cause_of_death causeofdeath
rename allegedly_armed unarmed
g video= !inlist(trim(wapo_body_camera),"No") if !inlist(wapo_body_camera,"")

* Date
split date, parse("/")
destring date3, g(year)
destring date2, g(day)
destring date1, g(month)
drop if year>2021

* keep what is used
keep age name gender race city stabb agency causeofdeath unarmed year month day Lat Long ORI9 video

* Relabel certain causes of death (so FE data match up since these typically are not from police homicides)
replace cause=proper(cause)
replace cause = "Asphyxiation" if inlist(cause,"Asphyxiated","Physical Restraint","Taser,Beaten,Asphyxiated","Taser,Physical Restraint","Taser,Beaten,Asphyxiated","Taser,Physical Restraint")
replace cause= "Beaten/Bludgeoned" if inlist(cause,"Bean Bag", "Beaten")
replace cause = "Chemical Agent/Pepper Spray" if inlist(cause, "Pepper Spray", "Chemical Agent")
replace cause = "Gunshot" if inlist(cause,"Gunshot,Taser","Gunshot,Vehicle")
replace cause= "Other" if inlist(cause,"Bomb", "Death In Custody","Hanging")


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
pie(4, color(red%75)) plabel(4 percent, size(*1.5) color(white)) plabel(4 name, size(*1.5) color(white) gap(-7cm)) ///
pie(3, color(orange)) ///
pie(5,  color(teal)) ///
pie(6, color(purple)) ///
pie(7, color(midblue))
graph export "Output/piegraph_mapping_police_all_cases.pdf", replace


********* Pie Graph ***********
preserve

	* Relabel & verify only correct causes kept
	drop if cause=="Other"|cause=="Vehicle"

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
	pie(4, color(red%75)) plabel(4 percent, size(*1.5) color(white)) plabel(4 name, size(*1.5) color(white) gap(-7cm)) ///
	pie(3, color(teal)) ///
	pie(5,  color(purple)) 
	graph export "Output/piegraph_mapping_police.pdf", replace
	
restore

************* Monthly police killings by agency *******************

preserve
	g dummy = mdy(month,day,year)
	g date=mofd(dummy)
	format date %tm
	keep date ORI9
	split ORI9, p(;)
	drop ORI9
	g i=_n
	greshape long ORI9, i(i)
	drop if inlist(ORI9,"") |strlen(ORI9)!=9
	g homicides=1
	gcollapse (sum) homicides, by(ORI9 date)
	gsort ORI9 date
	save DTA/agency_monthly_homicides,replace
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
keep if inlist(fips,"")

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
g homicides_mpv = 1
g homicides_black_mpv =(race=="Black")
g homicides_white_mpv =(race=="White")
g homicides_other_race_mpv =(race!="White"&race!="Black") if !inlist(race,"Unknown race","")
g homicides_female_mpv =(gender=="Female")  if !inlist(gender,"Unknown","Transgender","")
g homicides_male_mpv =(gender=="Male") if !inlist(gender,"Unknown","Transgender","")
g homicides_armed_mpv = (unarmed=="Allegedly Armed") if !inlist(unarmed,"Unclear","")
g homicides_unarmed_mpv = (unarmed=="Unarmed/Did Not Have Actual Weapon") if !inlist(unarmed,"Unclear","")

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


