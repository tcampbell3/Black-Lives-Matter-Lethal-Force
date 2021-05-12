* Note: Limit one event per city, using first event.

* Population screen
use "DTA/Population", clear
drop if year<2013
gcollapse (min) popest, by(fips)
drop if popest<20000
tempfile temp
save `temp', replace

* Merge daily data
cap frame change default
use "DTA/Mapping_Police_Daily", clear
rename homicides_mpv homicides
merge m:1 fips date using "DTA/Protest_Daily", nogen
merge m:1 fips date using "DTA/case_studies", nogen
merge m:1 fips using "`temp'", nogen keep(3 2)

* Cities without protest, case study, or homicide have only one observation without date, fill with median
sum date, d
replace date=int(r(p50)) if inlist(date,.)

* Keep what is need to speed up
drop if year(date)>=2020| year(date)<2009
keep fips date homicides protests subject first_protest video_date total_protests
compress

* Fill unobserved days and missing values with zeros
destring fips, replace
tsset fips date
tsfill, full
	* Fill daily numeric (change daily)
	foreach v of varlist homicides* protests{
		replace `v'=0 if inlist(`v',.)
	}
	* Fill event numeric (constant for entire event)
	foreach v of varlist total_protests first_protest video_date{
		bys fips (`v'): replace `v' = `v'[_n-1] if inlist(`v',.)
	}
	* Fill event string (constant for entire event)
	foreach v of varlist subject{
		gsort fips - subject
		bys fips: replace `v' = `v'[_n-1] if inlist(`v',"")
	}
	
* Merge population
rename fips FIPS
gen str7 fips = string(FIPS,"%07.0f")
g qtr=year(date)*10+quarter(date)
merge m:1 fips qtr using "DTA/Population", nogen keep(1 3) keepus(popest)
drop FIPS qtr
destring fips,replace 

* Index events
cap drop event
gegen event=group(subject)

* Indicate if protests precede video
g vid=(first_protest<video_date&video_date!=.) if !inlist(event,.)
replace vid =2 if video_date==. & !inlist(event,.)

* Define event time
g ptime=date-first_protest
g vtime=date-video_date
local f = 30
cap drop time
g time=floor(ptime/`f')

* Must observe entire month
bys event time: g test=_N if !inlist(event,.)&!inlist(time,.)
replace time=. if test<int(`f')

* Protest treatment period
g treated = !inlist(event,0,.)
g treatment= date>=first_protest & inlist(treated,1)

* Stack events
cap frame drop stack
frame create stack
gsort fips date
sum event,meanonly
local last=r(max)
tempvar tframe
tempfile temp
forvalues i = 1/`last'{
	di in red "Event: `i'/`last'"
	qui{
	* Put potential donors and event into tempframe
	cap frame drop `tframe'
	frame put if inlist(event,`i',.), into(`tframe')
	frame `tframe'{
		* Drop time outside of window
		sum date if !inlist(time,.)
		drop if date<r(min)|date>r(max)
		
		* Event time
		bys date (time): replace time = time[_n-1] if inlist(time,.)
		
		* Drop donors with protests
		cap drop test
		bys fips: gegen test=max(protests)
		drop if test>0&inlist(treated,0)&test!=.
		g donor=inlist(event,.)
		replace event=`i'
		
		* Drop cities without variation in homicides
		cap drop test
		bys event fips: gegen test=nunique(homicides)
		drop if inlist(test,1)
		
		* Clean and save event
		bys event (total_protests): replace total_protests=total_protests[_n-1] if inlist(total_protests,.)
		bys event (first_protest): replace first_protest=first_protest[_n-1] if inlist(first_protest,.)
		bys event (video_date): replace video_date=video_date[_n-1] if inlist(video_date,.)
		bys event (vid): replace vid=vid[_n-1] if inlist(vid,.)
		gsort event - subject
		replace subject=subject[_n-1] if inlist(subject,"")
		gcollapse (mean) homicides*  total_protests first_protest video_date treated treatment popest ///
		date vid, by(event fips time subject)
		save `temp', replace
	}
	
	* Stack events
	frame stack{
		if `i'==1{
			use `temp'
		}
		else{
			append using `temp'
		}
	}
	}
}

* Clean and save
frame stack{
	gsort event - treated + fips time
	order event fips time
	save DTA/case_study, replace
}
clear all