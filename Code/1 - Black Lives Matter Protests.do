
* Open protest subject location
import excel "BLM Protest Data/Subjects (clean).xls", sheet("Sheet1") firstrow clear
replace subject=scandal if scandal!=""
collapse (firstnm) city_subject=city stabb_subject=stabb, by(subject)
tempfile temp
save `temp',replace

* Open protest dataset
use "BLM Protest Data/DTA/Protests_subject", clear
g year=year(date)
g month=month(date)
gen qtr=year*10+floor((month-1)/3)+1
g protests=1

* Count solidarity protests (All subject locations are different than the city)
local i = 1
foreach s of varlist subject* {	
	rename `s' subject
	merge m:1 subject using `temp', keep(1 3) nogen
	g protests_same`i' = 1 if (city==city_subject & stabb==stabb_subject)
	rename subject `s'
	drop *_subject
	local i=`i'+1
}
egen protests_same = rowmax(protests_same*)
replace protests_same = 0 if inlist(protests_same,.)
g protests_s = protests-protests_same
drop protests_same*

* Clean and save
keep fips stabb city date protests* partic qtr
save DTA/protest_daily, replace
gcollapse (sum) protests* participants, by(fips qtr)
compress
tostring fips,replace
save DTA/protests, replace

/*
import excel "BLM Protest Data/Subjects (clean).xls", sheet("Sheet1") firstrow clear
drop if city==""|city=="NA"|city=="Local"
keep city stabb
gduplicates drop
tempfile temp
save `temp',replace

use "BLM Protest Data/DTA/Protests_subject", clear
keep fips stabb city
gduplicates drop
merge m:1 city stabb using `temp'
