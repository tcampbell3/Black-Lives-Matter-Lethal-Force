
* ORI9 FIPS crosswalk -> Protest count
use DTA/backbone, clear
keep ORI7 fips
drop if inlist(ORI7,"-1","")
tempfile ORI7_FIPS
save `ORI7_FIPS', replace

* Annual protest
use "DTA/protests", clear
g year = int(round(qtr/10))
gcollapse (sum) protests popnum, by(fips year)
tempfile blm
save `blm', replace

* Open Crime backbone
use DTA/Crimes, clear

* Merge FIPS
merge m:1 ORI7 using `ORI7_FIPS', nogen keep(1 3) keepus(fips)

* Merge BLM protests
merge m:1 fips year using `blm', nogen keep(1 3) keepus(protests popnum)
drop if inlist(fips,"")
replace protests = 0 if inlist(protest,.)
replace popnum = 0 if inlist(popnum,.)

* Define treated, donor, treatment
bys ORI7 (year): gen cum_protests = sum(protests)
bys ORI7 (year): egen total_protests = sum(protests)	
gen treated=(total_protests>=1)
gen donor=(total_protests==0)
gen treatment = (cum_protests>0)

* Coarsen population
fastxtile  pop_c=ucr_population, n(10) 

* Stack by cohort

	* 1) Number events
	bys ORI7: egen protest_start = min(year) if inlist(treatment,1)
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
			g time = year - protest_start
			
			* Drop outside of event window
			drop if time >=`window'
			
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
forvalues i=1/9{
	local e = -5+`i'
	g t_`i' = inlist(time,`e') & inlist(treated, 1)
}	

* Replace strings with coded numeric to save storage space
gegen unit = group(ORI7)
destring fips, replace
encode ORI7, gen(ori7)
drop ORI7

* Keep what is needed to save space
keep event ori7 fips time year protests popnum ucr_population pop_c t_* unit treated treatment donor	///
	crime_officer_assaulted crime_murder_rpt crime_violent_rpt crime_violent_clr crime_property_rpt crime_property_clr
	
* Convert crime counts to long
foreach v of varlist crime*{
	cap drop _dummy
	g long _dummy = `v'
	drop `v'
	rename _dummy `v'
}

* Save Body Cam Data
order event unit time ori7 year
gsort event unit year year
compress
save DTA/Agency_panel_crime, replace
