clear all
clear matrix
clear mata
set seed 19361927
mata: rseed(19361927)

*	Verticle Regression --- Elastic Net Synthetic control
use DTA/Stacked, clear
drop if time<-16 | time>=0				// match four years pre-treatment

* Pretreament annual means (demeaned by fixed effect)
bys event fips: gegen _unit = mean(${outcome})
bys event time: gegen _time = mean(${outcome})
bys event pop_c: gegen _pop = mean(${outcome})
replace ${outcome} = ${outcome} - _unit -_time - _pop
replace time=floor(time/4)
gcollapse ${outcome} treated, by(event fips time)

* wide long transformation
gegen _time=group(time)
keep ${outcome} _time treated event fips
greshape wide ${outcome}, i(treated event fips) j(_time)

* Propsensity Score Estimate
elasticnet logit treated ${outcome}*, rseed(1936139) alpha(0)
lassocoef, display(coef, standardized) sort(coef, standardized)
predict probability, pr penalized

* Inverse Probability Weights
replace probability=0 if probability<0
replace probability=1 if probability>1
qui sum treated if probability!=.
local p = r(mean)
di `p'/(1-`p')
gen ipw_unit = cond(treated, `p'/(1-`p'), probability/(1-probability)) if probability != .

* make weights sum to one in treatment group and control group
cap drop dummy
bys treated: egen dummy=sum(ipw_unit)
replace ipw_unit = ipw_unit / dummy

* save temp file to merge
keep ipw_unit event fips
tempfile temp
save `temp', replace
	
*merge
use DTA/Stacked, clear	
merge m:1 event fips using `temp', nogen replace update
save DTA/Stacked, replace
