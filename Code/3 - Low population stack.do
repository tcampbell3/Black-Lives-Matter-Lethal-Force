* Set up
tempfile temp
tempvar tframe
frame create `tframe'

* Controls
global controls = "popest ag_* crime_* acs_* geo_* pol_* h_* consent_* tweet_*"

* Save 2013 controls (carry officer data forward one year if missing from 2012 lemeas)
use DTA/Summary,clear
keep if inlist(year, 2013)
gcollapse ${controls}, by(fips)
destring fips, replace
save `temp', replace

* Merge controls to stacked data
use DTA/Stacked, clear
bys fips: egen dummy = mean(popest) if time<0
bys fips (dummy): replace dummy=dummy[_n-1] if inlist(dummy,.)
keep if dummy<=`1' | inlist(treated,0)
cap drop pop_c
fasterxtile pop_c=popest,n(10)

* Merge
g year = int(qtr/10)
merge m:1 fips using `temp', nogen keep(3)

* IPW Weights
global outcome="homicides"
do "Do Files/ipw"
do "Do Files/sdid" homicides fips qtr pop
replace ipw=_wt_unit*ipw

* Save
save DTA/stacked_pop_`1', replace

* Exit stata
exit, clear STATA