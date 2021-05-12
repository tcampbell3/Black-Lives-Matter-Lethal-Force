clear all
tempfile temp
tempvar tframe

* Backbone
use "Data\Geography\county_adjacency2010.dta", clear
destring fipscounty, g(fips)
split countyname, parse(", ")
drop if inlist(countyname2,"PR","VI","MP","AS","GU")
keep fips
gduplicates drop

* Import county populatino
cap frame drop `tframe'
frame create `tframe'
frame `tframe'{
	import delimited "Data\Population\2000-2010-population.csv", clear
	keep if sumlev == 050 
	keep state county popest*
	save `temp', replace
	import delimited "Data\Population\2010-2019-population.csv", clear
	keep if sumlev == 050 
	merge 1:1 state county using `temp', keep(1 3)
	g fips = state*1000 + county 
	keep fips popest*
	save `temp', replace
}
merge 1:1 fips using `temp', keep(1 3)

* Expand data
keep fips popest*
greshape long popestimate, i(fips) j(year)
expand 4
bys fips year: g quarter=_n
g qtr=year*10+quarter
drop quarter year

* Aggregate place level data to county level data
cap frame drop `tframe'
frame create `tframe'
frame `tframe'{
	import delimited "Data\Geography\census_place_county.csv", varnames(2) clear
	drop if inlist(placecode,.,99999)
	g fips=statecode*100000+placecode
	rename countycode countyfips
	gsort fips - placefptocountyallocationfactor								// map to county with most population if 2+
	bys fips: g test=_n
	keep if inlist(test,1)
	keep fips countyfips
	save `temp', replace
	use "DTA/Fatel_Encounters_Quarterly", clear
	merge 1:1 fips qtr using  "DTA\Protests", nogen
	destring fips,replace
	merge m:1 fips using `temp', nogen keep(3)
	gcollapse (sum) homicides protests, by(countyfips qtr)
	rename countyfips fips
	save `temp', replace
}
merge 1:1 fips qtr using `temp', nogen keep(1 3)
foreach v of varlist homicides protests popest{
	replace `v'=0 if inlist(`v',.)
}

* Define Treated
bys fips: egen total_protests = sum(protests)
gen treated=(total_protests>=1)
gen donor=(total_protests==0)

* Define Treatment
gen treatment = (protest>0)
bys fips (qtr): replace treatment=treatment[_n-1] if treatment[_n-1] == 1

* Events
egen event=group(fips) if inlist(treated,1)
egen dummy_time = group(qtr)
bys event: egen dummy_min=min(dummy_time) if inlist(treatment,1)
sum event,meanonly
local last=r(max)

* set post window length in years
local window=5

* Loop through events and stack
cap frame drop stack
frame create stack
forvalues i=1/`last'{
	di in red "Stacking `i'/`last'"
	quietly{
	cap frame drop `tframe'
	frame put if inlist(event,`i',.), into(`tframe')
	frame `tframe'{

		* Event time
		sum dummy_min, meanonly
		g time=floor((dummy_time-r(min))/4)
		drop if time>`window'-1 | time < -`window'

		* label event and save stack
		replace event=`i'
		gcollapse (sum) protests homicides (mean) popest treated treatment		///
			(min) first_qtr = qtr (max) last_qtr = qtr, by(event fips time)
		save `temp', replace
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

* Contingous counties indicator
cap frame drop `tframe'
frame create `tframe'
frame `tframe'{
	use "Data\Geography\county_adjacency2010.dta", clear
	destring fipsn,g(fips)
	destring fipsc,g(treated_fips)
	keep fips treated_fips
	g contiguous=1
	save `temp', replace
}

* Clean save
frame stack{
	
	* Contiguous county indicator
	g treated_fips= fips if inlist(treated,1)
	bys event (treated_fips): replace treated_fips = treated_fips[_n-1] if inlist(treated_fips,.)
	merge m:1 fips treated_fips using `temp',keep(1 3) nogen
	replace contiguous = 0 if inlist(contiguous,.)
	bys event: gegen test = nunique(fips) if inlist(contiguous,1)
	replace contiguous = 0 if inlist(test,1)							// must have at least one control county
	drop test

	* Periods (4 pre, 5 post)
	local last = `window'*2-1
	forvalues i=1/`last'{
		gen t_`i'=(time >= -(`window')+`i' & time < -(`window')+`i' +1 & treated == 1)
	}

	* Clean and save
	fasterxtile pop_c=popest,nq(10)
	g homicides_p = homicides/popest
	compress
	order event fips time treated treatment
	gsort + event - treated + fips time
	save DTA/Stacked_county, replace
	
}
clear all

* Erase and create tempfiles with synthetic control weights
forvalues i = 1/8{
	cap erase "DTA/temp`i'.dta"
	winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/Appendix - County dataset synth weights.do" `i'
}

* Loop until file exists then merge weights
sleep 10000
local i = 1
while `i' < 8+1 {
	cap confirm file "DTA/temp`i'.dta"
	if _rc==0{
		local i=`i'+1
	}
	else{
		sleep 60000
	}
}

* Save weights
use DTA/Stacked_county, clear
forvalues i = 1/8{
	merge m:1 event fips time using "DTA/temp`i'.dta", nogen update
}
save DTA/Stacked_county, replace