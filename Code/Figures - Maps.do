
* Geocode Places
cd "${user}/Data/Geography/2018"
local counter=1
forvalues i = 1/78{
	local j : di %02.0f `i'
	cap confirm file "tl_2018_`j'_place/tl_2018_`j'_place.shp"
	if _rc == 0{
	shp2dta using "tl_2018_`j'_place/tl_2018_`j'_place.shp" ,data("cb_data.dta") coor("cb_coor.dta") genid(cid) gencentroids(cent) replace
	use "cb_data", clear
	rename GEOID fips 
	rename NAME city
	rename x_cent Longitude
	rename y_cent Latitude
	keep city Latitude Longitude  fips STATEFP
	save cb_data,replace
	
	* Append datasets
	if `counter' == 1{
		use cb_data
		local counter = 2
		preserve
	}
	else{
		restore
		append using cb_data
		preserve
	}
	}
}
restore
save  "${user}/Data/Geography/2018/Place_FIPS_Long_Lat.dta", replace




* Create DTA of use coordinate map following https://www.stata.com/support/faqs/graphics/spmap-and-maps/
cd "${user}/Data/Geography/US Geo State"
shp2dta using "s_11au16", database(usdb) coordinates(uscoord) genid(_ID) replace


* Identify places to delete. Cannot merge with base file or it will not work.
use usdb, clear
destring FIPS, gen(stfips)
drop if LON==0|LAT==0
g stnum = FIPS
merge 1:1 stnum using ../../../DTA/census_region,
levelsof _ID if _merge==1
local deleteme = r(levels)
levelsof _ID if NAME=="Hawaii", clean
local hawaii = r(levels)
levelsof _ID if NAME=="Alaska", clean
local alaska = r(levels)
save usdb, replace

* delete territories , labels in usbd.dta
use uscoord.dta,clear
foreach v in `deleteme'{
	drop if _ID == `v'
}

* reformat hawaii
gen order = _n
drop if _X < -165 & _X != . &  _ID == `hawaii'
replace _X = _X  + 55  if  _X != .  &  _ID == `hawaii'
replace _Y = _Y  + 4  if _Y != .  &  _ID == `hawaii'

* reformat Alaska
replace _X = _X*.4  -55 if  _X !=  . &  _ID == `alaska'
replace _Y = _Y*.4  + 1 if _Y != .  & _ID == `alaska'
drop if _X > -10 & _X != . & _ID == `alaska'
sort order 
sort _ID
drop order

save uscoord,replace

* Creat dummy dataset of police killings
use "${user}/DTA/Fatel_Encounters_Geo", clear
rename stabb STATE
merge m:1 STATE using usdb, nogen
rename Longitude _X
rename Latitude _Y
drop if _X < -165 & _X != . &  _ID == `hawaii'
replace _X = _X  + 55  if  _X != .  &  _ID == `hawaii'
replace _Y = _Y  + 4  if _Y != .  &  _ID == `hawaii'
replace _X = _X*.4  -55 if  _X !=  . &  _ID == `alaska'
replace _Y = _Y*.4  + 1 if _Y != .  & _ID == `alaska'
drop if _X > -10 & _X != . & _ID == `alaska'
replace _X = -_X if _X>0 // fix an error in data
sort _ID
gen variable=1
save "dummy", replace


* map protests style 1
use "${user}/DTA/Protest_Daily", clear
rename stabb STATE
merge m:1 STATE using usdb, nogen
collapse (sum) protests, by(_ID)
spmap protests using uscoord  , id(_ID) point(data("dummy") xcoord(_X) ycoord(_Y) fcolor(red%10) size(small) osize(none)) fcolor(blue%10 blue%50 blue%70 blue%95) legstyle(2)    legend(pos(5) size(*2.5))
graph export "${user}/Output/State_Totals.png", replace width(1920)

* map protests style 2
use "${user}/DTA/Protest_Daily", clear
merge m:1 fips using "${user}/Data/Geography/2018/Place_FIPS_Long_Lat.dta", keep(3)
rename stabb STATE
merge m:1 STATE using usdb, nogen
rename Longitude _X
rename Latitude _Y
drop if _X < -165 & _X != . &  _ID == `hawaii'
replace _X = _X  + 55  if  _X != .  &  _ID == `hawaii'
replace _Y = _Y  + 4  if _Y != .  &  _ID == `hawaii'
replace _X = _X*.4  -55 if  _X !=  . &  _ID == `alaska'
replace _Y = _Y*.4  + 1 if _Y != .  & _ID == `alaska'
drop if _X > -10 & _X != . & _ID == `alaska'
replace _X = -_X if _X>0 // fix an error in data
sort _ID
gen variable=2
append using dummy
label define var 1 "Police Homicides" 2 "BLM Protests", replace
label values variable var
save "dummy", replace

use usdb, clear
spmap using uscoord  , id(_ID) point(data("dummy") by(variable) xcoord(_X) ycoord(_Y) fcolor(red%15 blue%10) size(small) osize(none none) legenda(on) leglabel()) legstyle(2)    legend(pos(5) size(*2.5) region(lcolor(black))) 
graph export "${user}/Output/Dots.png", replace width(1920)
 
 cd "${user}"