* Open Summary Data
clear all
use DTA/Summary, clear

* Drop never treated
bys fips: gegen test=max(protests)
drop if inlist(test,0)
drop test

* Drop places with protests other than high profile protests in other areas
g localscandal = protests > protests_s
bys fips: gegen test = max(localscandal)
drop if inlist(test,1) 

* Drop cities with high profile killings if missed in last step
preserve
	use  DTA/case_studies, clear
	keep fips
	gduplicates drop
	tempfile temp
	save `temp'
restore
merge m:1 fips using `temp', keep(1) nogen

* Drop data after covid (2020 quarter 1)
drop if qtr>20201

* Number events
gegen dummy_time = group(qtr)
bys fips: gegen start_treatment = min(dummy_time) if treatment==1
bys fips (start_treatment): replace start_treatment = start_treatment[_n-1] if inlist(start_treatment,.)
gegen event=group(start_treatment)
sum event,meanonly
local last=r(max)

* Loop through cohorts and stack
tempvar tframe
frame create stack
quietly{
forvalues i=1/`last'{

	* Start of treatment
	sum start_treatment if inlist(event,`i'), meanonly
	local start=r(mean)
		
	* temp frame of cohort
	cap frame drop `tframe'
	frame put if inlist(event,`i') | floor((start_treatment-`start')/4)>=5 , into(`tframe')
	frame `tframe'{
		
		* Event time
		sum start_treatment if inlist(event,`i'), meanonly
		gen time=dummy_time-r(min)
		
		* Donors
		replace donor=!inlist(event,`i') 
		replace treated=inlist(event,`i')
		
		* Drop outside of event window
		keep if time >= -5*4 & time < 5*4
		
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

* Drop events without full posttreatment data (or compositional changes can drive results)
cap drop test
bys event: gegen test = nunique(qtr)
sum test, meanonly
drop if test<r(max)

* Pretreatment dummies
forvalues i=2/5 {
	gen t_pre`i'=inlist(treated,1) & (time >= -`i'*4 & time < -(`i'-1)*4)
}

* Posttreatment dummies
forvalues i=1/5 {
	local j=`i'-1
	gen t_post`j'=inlist(treated,1) & (time >= `j'*4 & time < (`j'+1)*4)
}

* Convert fips to numeric
destring fips, replace
gsort event fips time

* Coarsen controls
cap drop pop_c
fasterxtile  pop_c=popest, n(10) 

* SDID weights
do "Do Files/sdid" homicides fips qtr pop
reghdfe  homicides t_* [aw=_wt_unit], vce(cluster fips) a(event#fips event#qtr event#pop_c##c.popest)
sum homicides if inlist(treated,1) & inlist(floor(time/4),-1)
local b=r(mean)
lincom ((t_post0+t_post1+t_post2+t_post3+t_post4)/5-(0+t_pre2+t_pre3+t_pre4+t_pre5)/5)/`b'

* Clean and save	
keep event fips time qtr homicides* t_* treatment treated pop_c _wt_unit participants total_protests popest    protests
compress
gsort event fips time
save DTA/Solidarity, replace