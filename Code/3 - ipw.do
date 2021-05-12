clear matrix
clear mata
set seed 19361927
mata: rseed(19361927)
local M=10

* Inverse probability weights --- pretreatment controls
tempvar tframe
cap frame drop `tframe'
frame put if inlist(year,2013), into(`tframe')
frame `tframe'{ 

* Pretreatment means
gcollapse treated ${controls}, by(fips)
dropmiss, force

* Drop coarsened and total version of variables
cap drop *_c 
cap drop *_total 

* Remove perfect collinear valriables 
_rmcoll ${controls}, forcedrop
local keep = r(varlist)
keep fips treated `keep'

* see what needs imputed
ds treated fips,not
local vars=r(varlist)
mdesc `vars'
local full = r(notmiss_vars)
local missing = r(miss_vars)

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
	drop dummy test


* set data as being impited, flong ensures full dataset is used. Wan (2015) requires each stack to have all N obs.
mi set flong

* register variables that are being imputed
mi register imputed `missing'

* choose imputation distribution 
mi impute chained  (pmm, knn(10)) `missing' = treated `full', add(`M') rseed (19361927)
mi unset
drop if mi_m==0
	
* Propsensity Score Estimate
lasso logit treated `full' `missing' [iw=imputation_weight], selection(plugin) rseed(19262917)	
lassocoef, display(coef, standardized) sort(coef, standardized)
predict probability, pr postselection 
gcollapse probability treated [aw=imputation_weight], by(fips) // Stata mannuelly collapsed without weight.
	
* Inverse Probability Weights
qui sum treated if probability!=.
local p = r(mean)
di `p'/(1-`p')
gen ipw = cond(treated, `p'/(1-`p'), probability/(1-probability)) if probability != .
	
* save temp file to merge	
keep fips ipw
tempfile temp
save `temp', replace

}
merge m:1 fips using `temp', nogen keep(1 3)