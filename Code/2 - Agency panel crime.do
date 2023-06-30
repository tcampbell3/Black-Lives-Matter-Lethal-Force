* Set up
tempvar tframe
frame create `tframe'
tempfile temp

* ORI7 Backbone
use DTA/backbone, clear
drop if inlist(ORI7,"-1","")
expand 22
bys id: g year=_n+1999
expand 4
bys id year: g qtr=year*10+_n

* Merge BLM protests & UCR Popualation accounting for overlapping juridictions
merge m:1 fips qtr using DTA/protests, nogen keep(1 3) keepus(protests participants)
replace protests = 0 if inlist(protest,.)
replace participants = 0 if inlist(participants,.)
gcollapse (sum) protests participants, by(ORI7 year) 

* Drop agencies without protests ever
bys ORI7 (year): gegen total_protests_2014_2021 = sum(protests)
drop if inlist(total_protests_2014_2021,0) 

* Protest start
bys ORI7 (year): gegen protest_start = min(year) if protests>0
bys ORI7 (protest_start): replace protest_start = protest_start[_n-1] if inlist(protest_start,.)

* Merge crime
merge 1:1 ORI7 year using DTA/Crimes, keep(3) nogen

* Drop 2020 data due to covid-19
drop if inlist(year,2020)

* Drop no population agency or misisng
bys ORI7: gegen test=min(popu)
drop if inlist(test, 0, .)
drop test

**** Stack by cohort ****

* 1) Number events
gen treatment = (year>=protest_start)
gegen event=group(protest_start)

* 2) Loop through cohorts and stack
sum event
local last=r(max)
tempvar stack
frame create `stack'
quietly{
forvalues i=1/`last'{
		
	* temp frame of cohort
	sum protest_start if inlist(event,`i'), meanonly
	local start=r(mean)
	cap frame drop `tframe'
	frame put if inlist(event,`i') | protest_start>`start'+4 | inlist(protest_start,2020), into(`tframe')
	frame `tframe'{
		
		* Event time
		gen time=year-`start'
		g treated = inlist(event,`i')
		
		* Drop outside of event window
		drop if time > 4 | time < -5
		
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
order event ORI7 time
gsort event ORI7 time

* Pretreatment dummies
forvalues i=2/5 {
	gen t_pre`i'=inlist(treated,1) & inlist(time,-`i')
}

* Posttreatment dummies
forvalues i=0/4{
	gen t_post`i'=inlist(treated,1) & inlist(time,`i')
}

* Drop events without post treatment event window
bys event: gegen test = nunique(time)
drop if test<6
drop test

* Replace strings with coded numeric to save storage space
gegen unit = group(ORI7)
encode ORI7, gen(ori7)
drop ORI7

* Balance panal
cap drop test
bys event ori7: g test1=_N
bys event: gegen test2=max(test1)
drop if test1<test2
drop test*

* Impute crime share if missing temporarily for SDID weights to be defined (.35% missing....)
g _impute_flag = inlist(crime_share,.)
reg crime_share year protests participants total_protests_2014_2021 protest_start population crime_officer_felony crime_officer_accident crime_officer_assaulted crime_murder_rpt crime_violent_rpt crime_property_rpt crime_violent_clr crime_property_clr
predict dummy
replace crime_share = dummy if inlist(crime_share,.)
drop dummy

* Coursen controls
fasterxtile  pop_c=population, n(10)

* SDID weights
foreach v of varlist crime_officer_assaulted crime_murder_rpt crime_violent_rpt crime_violent_clr crime_property_rpt crime_property_clr crime_share{
	do "Do Files/sdid" `v' ori7 year
	rename _wt_unit _unit_`v'
	rename _wt_sdid _sdid_`v'
}
replace crime_share=. if inlist(_impute_flag,1)

* Keep what is needed to save space
keep event ori7 time year protests partic population pop_c t_* treated treatment unit	*crime_officer_assaulted *crime_murder_rpt *crime_violent_rpt *crime_violent_clr *crime_property_rpt *crime_property_clr *crime_share

* Save
order event unit ori7 time year
gsort event unit year
compress
save DTA/Agency_panel_crime, replace