clear all
clear matrix
clear mata
set seed 19361927
mata: rseed(19361927)

*	Inverse probability weights --- pretreatment controls
use DTA/Summary, clear
keep if year==2013
gcollapse treated ${controls}, by(fips)
dropmiss, force

* Drop coarsened and total version of variables
cap drop *_c 
cap drop *_total 

* Remove perfect collinear valriables or variables of missing threshold
foreach v of varlist $controls {
		qui sum `v'
		if r(sd)==0{
			drop `v'
		}
		else{	// max thresh w/o: "variance-covariance matrix (Sigma) is not positive definite EM did not converge"
			mdesc `v'
			if r(percent)>51{
				drop `v'
			}
		}
}
_rmcoll ${controls}, forcedrop
local keep = r(varlist)
keep fips treated `keep'

 * Drop variables that break imputation_weight
 foreach v of varlist acs_high_school acs_lt_high_school acs_some_college {
	cap drop `v'
 }

* see what needs imputed
ds treated fips,not
local vars=r(varlist)
mdesc `vars'
local full = r(notmiss_vars)
local missing = r(miss_vars)

* set data as being impited, flong ensures full dataset is used. Wan (2015) requires each stack to have all N obs.
mi set flong

* register variables that are being imputed
mi register imputed `missing'

* choose imputation distribution (multivariate normal - mvn) and number of datasets (10)
local M=10
mi impute mvn `missing' = treated `full', add(`M') rseed (19361927)
mi unset
drop if mi_m==0

*gen imputation weight from Wan (2015) Variable selection models based on multiple imputation with an application for predicting median effective dose and maximum effect

	* count number of variables with nonmissing data for each observation
	g test=0
	foreach var in treated `full' `missing' {
		cap drop dummy
		g dummy =(`var'!=.)
		replace test=test+dummy
	}
	
	* count number of total control variables
	local count: word count `full' `missing'
	di `count'
	
	* gen imputation weight = (# variables non missing / # of of variables ) / number of imputation datasets
	g imputation_weight = (test/`count')/`M'
	
* Propsensity Score Estimate
elasticnet logit treated `full' `missing' [iw=imputation_weight], rseed(1936139)  alpha(0)
lassocoef, display(coef, standardized) sort(coef, standardized)
predict probability, pr penalized
gcollapse probability treated [aw=imputation_weight], by(fips) // Stata mannuelly collapsed without weight.
	
* Inverse Probability Weights
replace probability=0 if probability<0
replace probability=1 if probability>1
qui sum treated if probability!=.
local p = r(mean)
di `p'/(1-`p')
gen ipw = cond(treated, `p'/(1-`p'), probability/(1-probability)) if probability != .
	
* save temp file to merge	
keep fips ipw
tempfile temp
save `temp', replace

use DTA/Stacked, clear	
merge m:1 fips using `temp', nogen replace update
drop if time==.
save DTA/Stacked, replace