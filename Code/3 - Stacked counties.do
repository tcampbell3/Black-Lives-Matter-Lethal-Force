* Open county data, drop extra pairs for contiguous county sample
clear all
use "DTA/Counties", clear
destring fips_c, g(fips)
keep fips popest county stabb qtr protests participants homicides
gduplicates drop
drop if inlist(popest,.)

* Number events
gegen dummy_time = group(qtr)
bys fips: gegen start_treatment = min(dummy_time) if protests>0
bys fips (start_treatment): replace start_treatment = start_treatment[_n-1] if inlist(start_treatment,.)
gegen event=group(start_treatment)
sum event,meanonly
local last=r(max)

* Drop data after covid (2020 quarter 1)
drop if qtr>20201

* Drop never treated
drop if inlist(start_treatment,.)

* Loop through cohorts and stack
g treated=.
tempvar tframe
frame create stack
quietly{
forvalues i=1/`last'{

	* Start of treatment
	sum start_treatment if inlist(event,`i'), meanonly
	local start=r(mean)
		
	* temp frame of cohort
	cap frame drop `tframe'
	frame put if inlist(event,`i') | floor((start_treatment-`start')/4)>=${post} , into(`tframe')
	frame `tframe'{
		
		* Event time
		sum start_treatment if inlist(event,`i'), meanonly
		gen time=dummy_time-r(min)
		
		* Donors
		replace treated=inlist(event,`i')
		
		* Drop outside of event window
		keep if time >= -${pre}*4 & time < ${post}*4
		
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
frame stack: save `temp', replace
use `temp',clear
frame drop `tframe'
order event fips time
gsort event fips time
g treatment = time>=0 & inlist(treated,1)

* Drop events without full posttreatment data (or compositional changes can drive results)
cap drop test
bys event: gegen test = nunique(qtr)
sum test, meanonly
drop if test<r(max)

* Pretreatment dummies
forvalues i=2/$pre {
	gen t_pre`i'=inlist(treated,1) & (time >= -`i'*4 & time < -(`i'-1)*4)
}

* Posttreatment dummies
forvalues i=1/$post {
	local j=`i'-1
	gen t_post`j'=inlist(treated,1) & (time >= `j'*4 & time < (`j'+1)*4)
}

* SDID weights
fasterxtile  pop_c=popest, n(10)
do "Do Files/sdid" homicides fips qtr pop

* Clean and save	
keep event fips time qtr homicides t_* treatment treated pop_c _wt* participants popest protests
compress
gsort event fips time
save DTA/Stacked_counties, replace
clear all