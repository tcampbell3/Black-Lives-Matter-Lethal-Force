clear all
tempvar tframe
tempfile temp
foreach v in protests video{
foreach s in full sub{

	* Save Summary Data
	use DTA/Summary, clear
	drop if year<2009
	keep fips video protests homicides qtr popest ag_* crime_* acs_* geo_* pol_* h_* consent_* year

	* Subsample 
	bys fip: gegen total_protests=total(protests)
	bys fip: gegen total_video=total(video)
	if "`s'"=="full"{
		keep if (total_video>0&total_protests>0) | (inlist(total_protests,0)&inlist(total_video,0))
	}
	if "`v'"=="video"&"`s'"=="sub"{
		keep if (total_video>0&inlist(total_protests,0)) | (inlist(total_protests,0)&inlist(total_video,0))
	}
	if "`v'"=="protests"&"`s'"=="sub"{
		keep if (total_protests>0&inlist(total_video,0)) | (inlist(total_protests,0)&inlist(total_video,0))
	}
	drop total*
	
	* treatment
	bys fips: egen total= sum(`v')
	gen treated_eventually=(total>0)
	gen treatment = (`v'>0)
	bys fips (qtr): replace treatment = 1 if treatment[_n-1] == 1

	* Number events
	bys fips: egen dummy_time = min(qtr) if treatment==1
	bys fips (dummy_time): replace dummy_time = dummy_time[_n-1] if dummy_time == .
	egen event=group(dummy_time)
	drop dummy*
	sum event
	local last=r(max)

	* Event Time
	egen dummy_time = group(qtr)
	bys fips: egen dummy_min=min(dummy_time) if treatment==1

	* set post window length in years
	local window=5

	* Loop through events and stack
	cap frame drop stack
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

	* Save dataset
	frame stack{
		order event fips time
		sort event fips time

		* Periods (4 pre, 5 post)
		local last = `window'*2-1
		forvalues i=1/`last'{
			gen t_`i'=(time >= -(`window'*4)+`i'*4 & time < -(`window'*4)+`i'*4 +4 & treated == 1)
		}

		*  IPW weights
		fasterxtile pop_c=popest, nq(10)
		global controls = "popest ag_* crime_* acs_* geo_* pol_* h_* consent_*"
		global outcome="homicides"
		do "Do Files/3 - ipw"
		do "Do Files/3 - unit" 
		do "Do Files/3 - time"

		* Extra Variables
		destring fips,replace
		compress
		keep event fips time qtr video protests homicides* popest pop_c t_* ipw* treated treatment
		gsort event fips time
		save DTA/Stacked_`v'_`s', replace
	}

}
}