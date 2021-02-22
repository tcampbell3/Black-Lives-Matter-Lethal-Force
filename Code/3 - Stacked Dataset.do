* Save Summary Data
use DTA/Summary, clear

* Move events with less than 20 people or in solidarity into control group
drop donor treat* total

* treatment
bys fips: egen total_protests = sum(protests)
gen treated_eventually=(total_protests>0)
gen treatment = (protests>0)
bys fips (qtr): replace treatment = 1 if treatment[_n-1] == 1

* Number events
bys fips: egen dummy_time = min(qtr) if treatment==1
bys fips (dummy_time): replace dummy_time = dummy_time[_n-1] if dummy_time == .
egen e_num=group(dummy_time)
drop dummy*
sum e_num
local last=r(max)

* Event Time
egen dummy_time = group(qtr)
bys fips: egen dummy_min=min(dummy_time) if treatment==1

* set post window length in years
local window=5

* Loop through events and stack
save DTA/dummy, replace
quietly{
forvalues i=1/`last'{

	preserve
		use DTA/dummy, clear
		
		* drop outside of event window
		sum dummy_min if e_num==`i'
		local min=r(mean)
		drop if dummy_time>=`min'+`window'*4
		
		* label event
		gen event=`i'
		
		* label treated, treatment donor (include treated states as donors if treated outside of event window)
		sort dummy_min
		bys fips: egen dummy=max(treatment)
		gen donor = (dummy == 0)
		gen treated = (dummy == 1)
		replace treatment=0 if treated==0
		keep if e_num==`i'|donor==1
		replace dummy_min=dummy_min[_n-1] if dummy_min==.
		gen time=dummy_time-dummy_min
		bys qtr (time):replace time=time[_n-1] if time==.
		drop dummy* e_num
		tempfile temp
		save `temp'
	restore
	
	if `i'==1{
		use `temp', clear
	}
	else{
		append using `temp'
	}
}	
}
erase DTA/dummy.dta
order event fips time
sort event fips time

* test for erros
sum time
assert r(max)==`window'*4-1
sum protests if donor==1
assert r(max)==0
sum protests if treated==1
assert r(max)>0
cap drop test
gen test=donor+treated
sum test
assert r(mean)==1
drop test
tabstat treated_even if donor==1, by(event) // should be zero for most, but not first couple


* Periods (4 pre, 5 post)
local last = `window'*2-1
forvalues i=1/`last'{
	gen t_`i'=(time >= -(`window'*4)+`i'*4 & time < -(`window'*4)+`i'*4 +4 & treated == 1)
}

* Extra Variables
cap drop FIPS
encode fips, gen(FIPS)


* remove events with less than 4 years post treatment and  save percent of events being considered to text file
	
	* open file
	tempname scs
	file open `scs' using "Output\events_in_sample.txt", text write replace
	
	* count number of events
	unique fips if treated==1
	local total_events = r(unique)
	
	
	* drop events without enough post treatment data
	bys event: egen test = max(time)
	
	* count number of events with at least four years of post treatment data
	unique fips if treated==1 & test >= `window'*2-1
	local sample_events = r(unique)
	
	* drop events without enough post treatment data
	drop if test < `window'*2-1
	drop test

	* save text file
	local output = trim("`: display %10.2f `sample_events'/`total_events'*100'")
	file write `scs' `" `: display "`output'" ' "' _n
	
	* save text file of total events
	tempname scs
	file open `scs' using "Output\total_events.txt", text write replace
	file write `scs' `" `: display "`total_events'" ' "' _n


compress
save DTA/Stacked, replace

