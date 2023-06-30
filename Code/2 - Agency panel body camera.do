
* ORI9 FIPS crosswalk -> Protest count
use DTA/backbone, clear
drop if inlist(ORI9,"-1","")
expand 22
bys id: g year=_n+1999
expand 4
bys id year: g qtr=year*10+_n

* Merge BLM protests & UCR Popualation accounting for overlapping juridictions
merge m:1 ORI7 year using DTA/Crimes, nogen keep(1 3) keepus(population)
merge m:1 fips qtr using DTA/protests, nogen keep(1 3) keepus(protests participants)
replace protests = 0 if inlist(protest,.)
replace participants = 0 if inlist(participants,.)
gcollapse (sum) protests participants (mean) population, by(ORI9 year qtr) 

* Drop agencies without protests ever
bys ORI9 (qtr): gegen total_protests_2021 = sum(protests)
drop if inlist(total_protests_2021,0) 

* Merge bodycam (keep only agencies in sample)
merge 1:1 ORI9 qtr using DTA/LEMAS_body_cam, keep(3) nogen

* Define treated, donor, treatment
bys ORI9 (qtr): gen cum_protests = sum(protests)
bys ORI9 (qtr): gegen total_protests = sum(protests)	
gen treated=(total_protests>=1)
gen donor=(total_protests==0)
gen treatment = (cum_protests>0)
egen _time=group(qtr)
encode ORI9, g(id)


**** Stack by cohort ****

* 1) Number events
bys id: gegen start_treatment = min(_time) if inlist(treatment,1)
bys id (start_treatment): replace start_treatment = start_treatment[_n-1] if inlist(start_treatment, .)
gegen event=group(start_treatment)

* 2) Loop through cohorts and stack
sum event
local last=r(max)
tempvar tframe
tempvar stack
frame create `stack'
quietly{
forvalues i=1/`last'{
		
	* temp frame of cohort
	cap frame drop `tframe'
	frame put if inlist(event,`i')|inlist(treated,0), into(`tframe')
	frame `tframe'{
		
		* Event time
		sum start_treatment if inlist(event,`i'), meanonly
		gen time=_time-r(min)
		
		* Drop outside of event window
		drop if time < -5*4
		
		* label event and save stack
		replace event=`i'
		tempfile temp
		save `temp'
	}
	
	* Stack
	frame `stack'{
		if `i'==1{
			use `temp', clear
		}
		else{
			append using `temp'
		}
	}
}	
}
frame `stack': save `temp', replace
use `temp',clear
frame drop `tframe'

* Pretreatment dummies
forvalues i=2/5 {
	gen t_pre`i'=inlist(treated,1) & inlist(floor(time/4),-`i')
}

* Posttreatment dummies
forvalues i=0/2{
	gen t_post`i'=inlist(treated,1) & inlist(floor(time/4),`i')
}

* Adjust stata (random sampling in stata for less than 100 officers. All agencies asked above 100 officers.)
gsort event ORI9 time
gegen unit = group(ORI9)
replace strata = strata + unit*1000 if inlist(strata,101,201,301)

* Replace strings with coded numeric to save storage space
encode ORI9, gen(ori9)
drop ORI9 

* Coursen controls
fasterxtile  pop_c=population, n(10)

* Keep what is needed to save space
keep event unit ori9 time ag_bodycam FINALWEIGHT strata qtr protests participants population pop_c t_* treated treatment donor Q16M*

* SDID weights
do "Do Files/sdid" ag_bodycam ori9 qtr
replace _wt_unit = _wt_unit * FINALWEIGHT

* Save Body Cam Data
rename FINALWEIGHT weight
order event unit ori9 time
gsort event unit ori9 time
compress
save DTA/Agency_panel_bodycam, replace
