clear all
clear matrix
clear mata
set seed 19361927
mata: rseed(19361927)

*	Horizontal Regression --- Elastic Net Synthetic control
use DTA/Stacked, clear
drop if treated==1

* save event-time count --- number of observations for each year, post treatment unbalanced
tempname tempframe
frame put event time, into(`tempframe')
frame `tempframe'{
	gduplicates drop
	replace time=floor(time/4)
	g _count = 1
	gcollapse (sum) _count, by(event time)
}

* Control group annual means (demeaned by fixed effect)
bys event fips: gegen _unit = mean(${outcome})
bys event time: gegen _time = mean(${outcome})
bys event pop_c: gegen _pop = mean(${outcome})
replace ${outcome} = ${outcome} - _unit -_time - _pop
replace time=floor(time/4)
gcollapse (mean) ${outcome} treated, by(event fips time)

* wide long transformation
egen _unit=group(fips)
keep  ${outcome} _unit event time
greshape wide ${outcome}, i(time event) j(_unit)

* Use only control group that is stable for all events
drop if time==.
mdesc
local keep = r(notmiss_vars) 
keep `keep'

* Remove perfect collinear valriables
foreach v of varlist $outcome* {
		sum `v', meanonly
		if r(mean)==0{
			drop `v'
		}
}
_rmcoll ${outcome}*, forcedrop
local keep = r(varlist)
keep time event `keep'

* Propsensity Score Estimate
gen treated=(time>=0)
*elasticnet logit treated ${outcome}*, alpha(0) rseed(19262917)					(logit doesn't converge)
lasso logit treated ${outcome}*, selection(plugin) rseed(19262917)				// requires less predictors
lassocoef, display(coef, standardized) sort(coef, standardized)
predict probability, pr penalized

* Inverse Probability Weights
qui sum treated if probability!=.
replace probability=0 if probability<0
replace probability=1 if probability>1
local p = r(mean)
di `p'/(1-`p')
gen ipw_time= cond(treated, `p'/(1-`p'), probability/(1-probability)) if probability != .

* make weights sum to one in pre treatment group and post treatment group
frlink 1:1 event time, frame(`tempframe')
g _count = frval(`tempframe', _count)
cap drop dummy
bys treated: egen dummy=sum(ipw_time)
replace ipw_time = ipw_time / dummy / _count		// divide by count because matching annual unbalanced

* save temp file to merge
keep ipw_time event time
rename time _time
tempfile temp
save `temp', replace
	
* merge and save
use DTA/Stacked, clear
g _time = floor(time/4)
merge m:1 event _time using `temp', nogen update replace
drop _time
cap drop ipw_unit_time
g ipw_unit_time = ipw_unit *ipw_time
save DTA/Stacked,replace
