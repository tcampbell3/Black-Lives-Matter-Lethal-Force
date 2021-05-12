/*	NOTES
Treated group:
	- 30 days no police homicide followed by at least one police homicide
	- At least one protest over 30 days after the police homicides
	- Protest cannot occure on same day as homicide or 30 days prior

Control group:
	- 30 days no police homicide followed by at least one police homicide
	- No protests over 30 days after the police homicides
*/


* Protest data
use "DTA/Protest_Daily", clear
destring fips,replace
tempfile temp
save `temp', replace

* Open daily data
cap frame change default
use "DTA/Mapping_Police_Daily", clear

* Fix state city typos
merge m:1 fips using "DTA/fips", update replace keep(1 3 4 5) nogen

* Fill missings with zeros
destring fips, replace
tsset  fips date
tsfill, full
merge m:1 fips date using `temp', nogen keep(1 3) keepus(protests)
foreach v of varlist homicides* protests video{
	replace `v' = 0 if inlist(`v',.)
}
gsort fips date
order fips date

* Keep what is need to speed up
keep fips date homicides_mpv protests video stabb city name
compress

* Define event window
local prewindow=7*4
local postwindow=7*7-1

* Identity police killings that occure in places without killings in pre period
local pre=""
forvalues i=1/`prewindow'{
	local pre="`pre' & inlist(l`i'.homicides,0)"
}
g event = (homicides>0) `pre'

* Index potential events
gsort - event fips date
replace event = _n if inlist(event,1)

* Expand event label over entire event window
gsort fips date
forvalues i=1/`prewindow'{
	replace event=f.event if !inlist(f.event,0,.) & inlist(event,0)
}
forvalues i=1/`postwindow'{
	cap drop dummy
	g double dummy = event
	replace event=l.dummy if inlist(event,0)& !inlist(l.dummy,.)
}
drop dummy

* Keep only donors and treated units
drop if inlist(event,0)

* Police homicide treatment period
bys event: gegen double homicide_date=min(date) if homicides>0
bys event (homicide_date): replace homicide_date=homicide_date[_n-1] if inlist(homicide_date,.)
format homicide_date %d
g post_homicide= date>=homicide_date 

* Protest treatment period
bys event: gegen double protest_date=min(date) if protest>0
bys event (protest_date): replace protest_date=protest_date[_n-1] if inlist(protest_date,.)
format protest_date %d
g treated = !inlist(protest_date,.)
g treatment= date>=protest_date & inlist(treated,1)

* Drop places with protest on same day as homicide or prior or insufficient post treatment data
g double test= protest_date-homicide_date if treated==1
drop if (test<=0 |  test>=`postwindow'+1-7*3 ) & !inlist(test,.)
drop test

* Drop incomplete panels
bys event: g test=_N
sum test, meanonly
drop if test < r(max)
 
* Fill police homicide victims name
replace name="" if  !inlist(homicide_date,date)
foreach v of varlist name city stab{
	gsort event -`v'
	replace `v' = `v'[_n-1] if inlist(`v',"")
}

* Reindex events
replace event=. if inlist(treated,0) 
gegen dummy=group(event)
drop event
rename dummy event
order event fips date
gsort event fips date

* Stack events
cap frame drop stack
frame create stack
gsort fips date
sum event,meanonly
local last=r(max)
tempvar tframe
tempfile temp
forvalues i = 1/`last'{

	* Put potential donors and event into tempframe
	sum homicide_date if inlist(event,`i'), meanonly
	local d=r(mean)
	cap frame drop `tframe'
	frame put if inlist(event,`i',.) & inlist(homicide_date,`d',`d'+1,`d'+2,	///
	`d'+3,`d'+4,`d'+5,`d'+6,`d'+7,`d'-1,`d'-2,`d'-3,`d'-4,`d'-5,`d'-6,`d'-7), into(`tframe')
	frame `tframe'{
	
		* Collapse into event time
		g donor=inlist(event,.)
		sum protest_date,meanonly
		replace protest_date = r(mean)
		replace event=`i'
		g htime=date-homicide_date
		sum htime if inlist(treated,1) & date==protest_date, meanonly
		g ptime = htime-r(mean)
		g etime = floor(htime/7) * (htime<=0) + (ptime>=0)*floor(ptime/7)
		drop if etime<-4|etime>3
		fcollapse (min) min_date=date (max) max_date=date (sum) homicides_mpv video protests ///
			(mean) treated treatment donor (firstnm) stabb city name, by(event fips etime)  
		format min_date %d
		format max_date %d
		
		* Save event in tempfile to stack
		save `temp', replace
		
	}
	
	* Stack
	frame stack{
		if `i'==1{
			use `temp'
		}
		else{
			append using `temp'
		}
	}
	
}

* Clean and save
frame stack{
	gsort event - treated + fips etime
	order event fips etime name city min_date max_date // order is important dont change 
	compress
	save DTA/scandal_events ,replace
	export delimited using "C:\Users\travi\Dropbox\Police Killings\test.csv", replace
}