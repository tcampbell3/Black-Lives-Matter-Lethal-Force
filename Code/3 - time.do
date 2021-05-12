clear matrix
clear mata
set seed 19361927
mata: rseed(19361927)
cap drop ipw_time

*	Horizontal Regression --- Elastic Net Synthetic control
tempvar tframe
tempfile temp
sum event, meanonly
local last=r(max)
forvalues e=1/`last'{

	cap frame drop `tframe'
	frame put  if inlist(treated,0) & inlist(event, `e'), into(`tframe')
	frame `tframe'{ 

		* Post treatment size
		

		* Demean by fixed effects
		bys event fips: gegen _unit = mean(${outcome})
		bys event time: gegen _time = mean(${outcome})
		bys event pop_c: gegen _pop = mean(${outcome})
		replace ${outcome} = ${outcome} - _unit -_time - _pop
		mata: mata clear  
		mata: rseed(19361927)

		* wide long transformation
		keep event fips time ${outcome}
		gegen _unit=group(event fips)
		keep  ${outcome} _unit event time
		greshape wide ${outcome}, i(time event) j(_unit)

		* Drop missing
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
		elasticnet logit treated ${outcome}*, alpha(0) rseed(19262917)
		lassocoef, display(coef, standardized) sort(coef, standardized)
		predict probability, pr penalized

		* Inverse Probability Weights
		qui sum treated if probability!=.
		local p = r(mean)
		di `p'/(1-`p')
		gen ipw_time= cond(treated, `p'/(1-`p'), probability/(1-probability)) if probability != .

		* make weights sum to post treatment sample size
		bys treated: g N=_N
		bys treated: gegen dummy=total(ipw_time)
		sum N if inlist(treated,1),meanonly
		replace ipw_time = ipw_time / dummy * r(mean)

		* save temp file to merge
		keep ipw_time event time
		save `temp', replace
		
	}
	merge m:1 event time using `temp', nogen update
}
cap drop ipw_unit_time
g ipw_unit_time = ipw_unit *ipw_time
