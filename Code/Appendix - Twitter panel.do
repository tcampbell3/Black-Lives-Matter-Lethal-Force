* Set up
tempvar tframe
frame create `tframe'
tempfile temp

* Twitter backbone
use "DTA/Twitter.dta", clear
drop if year>=2016

* Drop never treated
frame `tframe'{
	use "DTA/protests", clear
	g year = int(round(qtr/10))
	gcollapse (sum) total_protests_2014_2021=protests, by(fips)
	save `temp', replace
}
merge m:1 fips using `temp', keep(1 3) nogen
drop if inlist(total_protests_2014_2021,.,0)

* Merge annual protest
frame `tframe'{
	use "DTA/protests", clear
	g year = int(round(qtr/10))
	gcollapse (sum) protests parti, by(fips year)
	save `temp', replace
}
merge m:1 fips year using `temp', keep(1 3) nogen
replace protests = 0 if inlist(protest,.)
replace parti = 0 if inlist(parti,.)
bys fips (year): gegen protest_start = min(year) if protests>0
bys fips (protest_start): replace protest_start = protest_start[_n-1] if inlist(protest_start,.)

**** Stack by cohort ****

* 1) Number events
g treatment = (year>=protest_start)
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
	frame put if inlist(event,`i') | protest_start>`start'+4, into(`tframe')
	frame `tframe'{
		
		* Event time
		gen time=year-`start'
		g treated = inlist(event,`i')
		
		* Drop outside of event window
		drop if time > 4 | time < -4
		
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
order event fips time
gsort event fips time

* Pretreatment dummies
forvalues i=2/4 {
	gen t_pre`i'=inlist(treated,1) & inlist(time,-`i')
}

* Posttreatment dummies
forvalues i=0/1{
	gen t_post`i'=inlist(treated,1) & inlist(time,`i')
}

* Drop events without controls
bys event: gegen test = nunique(event) if inlist(treated,0)
bys event (test): replace test=test[_n-1] if inlist(test,.)
drop if inlist(test,.,0)
drop test

* New measure (Drop if no tweets during 5 years before protests)
bys event GOVID: gegen ave=mean(sub_tweet_counts) if time<0
bys event GOVID (ave): replace ave = ave[_n-1] if inlist(ave,.)
g tweets = sub_tweet_counts/ave
drop if inlist(tweets,.) 

* Balance panel
bys event: gegen test1=nunique(time)
bys event GOVID: gegen test2=nunique(time)
drop if test2<test1
bys event: gegen test3 = max(time)
sum test3
drop test*

* SDID weights
gegen id=group(GOVID)
foreach v of varlist tweets sub_polarity {
	do "Do Files/sdid" `v' id year
	rename _wt_unit _unit_`v'
	rename _wt_sdid _sdid_`v'
}

* Save
order event id GOVID time year
gsort event id GOVID time
compress
save DTA/Twitter_stack, replace