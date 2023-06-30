
* Map: synthetic control
use DTA/Stacked_counties, clear
gcollapse (max) treated (max) _wt_unit, by(fips)
g county=fips
replace _wt_unit=2 if inlist(treated,1)
maptile _wt_unit, geo(county2010) cutv(.01 .1 1.5) stateoutline(medium) 		///
	fc(midblue%15 midblue%40 midblue orange_red*.6) 							///
	twopt(legend(pos(5) order(5 "Treated" 4 "Control: .10-1" 3 "Control: .01-.10" 2 "Control: <.01"))) 
graph export "Output/county_map_synth.png", replace

* Map: contiguous counties
use DTA/contiguous_counties, clear
gcollapse (max) treated, by(fips)
g county=fips
maptile treated, geo(county2010) cutv(.5) twopt(legend(pos(5) order(3 "Treated" 2 "Control"))) fc(BuRd) stateoutline(medium)
graph export "Output/county_map_contiguous.png", replace
