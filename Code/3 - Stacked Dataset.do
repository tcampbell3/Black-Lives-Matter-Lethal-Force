* Open Summary Data
clear all
use DTA/Summary, clear

* Number events
bys fips: egen dummy_time = min(qtr) if treatment==1
bys fips (dummy_time): replace dummy_time = dummy_time[_n-1] if dummy_time == .
egen event=group(dummy_time)
drop dummy*
sum event,meanonly
local last=r(max)

* Event Time
egen dummy_time = group(qtr)
bys fips: egen dummy_min=min(dummy_time) if treatment==1

* set post window length in years
local window=5

* Loop through events and stack
tempvar tframe
frame create stack
quietly{
forvalues i=1/`last'{
		
	* temp frame of cohort
	cap frame drop `tframe'
	frame put if inlist(event,`i',.), into(`tframe')
	frame `tframe'{

		* drop outside of event window
		sum dummy_min if event==`i'
		local min=r(mean)
		drop if dummy_time>=`min'+`window'*4
		
		* Event time
		gen time=dummy_time-`min'
		bys qtr (time):replace time=time[_n-1] if time==.

		* label event and save stack
		replace event=`i'
		drop dummy*
		tempfile temp
		save `temp'
	}
	
	* Stack
	frame stack{
		if `i'==1{
			use `temp', clear
		}
		else{
			append using `temp'
		}
	}
}	
}
frame change stack
frame drop default
frame drop `tframe'
order event fips time
sort event fips time

* Periods (4 pre, 5 post)
local last = `window'*2-1
forvalues i=1/`last'{
	gen t_`i'=(time >= -(`window'*4)+`i'*4 & time < -(`window'*4)+`i'*4 +4 & treated == 1)
}

* Extra Variables
cap drop FIPS
encode fips, gen(FIPS)

*  IPW weights
global controls = "popest ag_* crime_* acs_* geo_* pol_* h_* consent_*"
global outcome="homicides"
do "Do Files/3 - ipw"
do "Do Files/3 - unit" 
do "Do Files/3 - time"

* Clean and save	
compress
gsort event fips time
save DTA/Stacked, replace
clear all
