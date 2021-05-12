
* ORI9 FIPS crosswalk -> Protest count
use DTA/backbone, clear
keep ORI9 ORI7 fips
drop if inlist(ORI9,"-1","")
tempfile temp
save `temp', replace

* Open bodycam backbone
use DTA/LEMAS_body_cam, clear

* Merge FIPS and ORI7
merge m:1 ORI9 using `temp', nogen keep(1 3) keepus(fips ORI7)
replace ORI7 = "" if inlist(ORI7,"-1")

* Merge BLM protests
merge m:1 fips qtr using DTA/protests, nogen keep(1 3) keepus(protests popnum)
drop if inlist(fips,"")
replace protests = 0 if inlist(protest,.)
replace popnum = 0 if inlist(popnum,.)

* UCR Popualation
merge m:1 ORI7 year using DTA/Crimes, nogen keep(1 3)
fasterxtile  pop_c=ucr_population, n(10) 

* Define treated, donor, treatment
bys ORI9 (qtr): gen cum_protests = sum(protests)
bys ORI9 (qtr): egen total_protests = sum(protests)	
gen treated=(total_protests>=1)
gen donor=(total_protests==0)
gen treatment = (cum_protests>0)
egen _time=group(qtr)

* Stack by cohort

	* 1) Number events
	bys ORI7: egen protest_start = min(_time) if inlist(treatment,1)
	bys ORI7 (protest_start): replace protest_start = protest_start[_n-1] if inlist(protest_start, .)
	egen event=group(protest_start)
	sum event
	local last=r(max)

	* 2) Save tempfile of full data
	tempfile full
	save `full', replace
	
	* 3) Loop through events and stack
	local window=5
	tempfile temp
	quietly{
	forvalues i=1/`last'{

		preserve
				
			* Open full data
			use `full', clear
			
			* Keep event's treated and donors
			keep if inlist(event,`i')|inlist(donor,1)
			
			* Label cohort
			replace event = `i'
	
			* Event time
			gsort protest_start
			replace protest_start = protest_start[_n-1] if inlist(protest_start, .)
			g time = _time - protest_start
			
			* Drop outside of event window
			drop if time >=`window'*4
			
			* Save tempfile to stack
			save `temp', replace
		
		restore
		
		if `i'==1{
			use `temp', clear
		}
		else{
			append using `temp'
		}
	}	
	}

* Treatment time dummies
g event_year=floor(time/4)
forvalues i=1/7{
	local e = -5+`i'
	g t_`i' = inlist(event_year,`e') & inlist(treated, 1)
}	

* Adjust stata (random sampling in stata for less than 100 officers. All agencies asked above 100 officers.)
gegen unit = group(ORI9)
replace strata = strata + unit*1000 if inlist(strata,101,201,301)

* Replace strings with coded numeric to save storage space
encode ORI9, gen(ori9)
destring fips, replace
encode ORI7, gen(ori7)
drop ORI9 ORI7

* Keep what is needed to save space
keep event ori9 fips time ag_bodycam FINALWEIGHT strata qtr protests popnum ucr_population pop_c t_* unit treated treatment donor Q16M*

* Save Body Cam Data
rename FINALWEIGHT weight
order event ori9 time
gsort event ori9 time
compress
save DTA/Agency_panel_bodycam, replace

* Save zipfile
cd DTA
zipfile Agency_panel_bodycam.dta, saving(Agency_panel_bodycam, replace)
cd ..
