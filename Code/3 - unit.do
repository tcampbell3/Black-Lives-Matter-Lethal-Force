clear matrix
clear mata
set seed 19361927
mata: rseed(19361927)
cap drop ipw_unit

*	Verticle Regression --- Elastic Net Synthetic control
tempvar tframe
tempfile temp
sum event, meanonly
local last=r(max)
forvalues e=1/`last'{

	cap frame drop `tframe'
	frame put  if time>=-16 & time<0 & inlist(event,`e'), into(`tframe')
	frame `tframe'{ 

	* Pretreament annual means (demeaned by fixed effect)
	bys event fips: gegen _unit = mean(${outcome})
	bys event time: gegen _time = mean(${outcome})
	bys event pop_c: gegen _pop = mean(${outcome})
	replace ${outcome} = ${outcome} - _unit -_time - _pop
	replace time=floor(time/4)
	gcollapse ${outcome} treated, by(event fips time)
	mata: mata clear  
	mata: rseed(19361927)

	* wide long transformation
	gegen _time=group(time)
	keep ${outcome} _time treated event fips
	greshape wide ${outcome}, i(treated event fips) j(_time)

	* Propsensity Score Estimate
	cap elasticnet logit treated ${outcome}*, rseed(1936139) alpha(0)
	if _rc==430{
		elasticnet linear treated ${outcome}*, rseed(1936139) alpha(0)
		predict probability
		replace probability = .999999 if probability>0
		replace probability = .000001 if probability<0
	}
	else{
		lassocoef, display(coef, standardized) sort(coef, standardized)
		predict probability, pr penalized
	}

	* Inverse Probability Weights
	qui sum treated if probability!=.
	local p = r(mean)
	di `p'/(1-`p')
	gen ipw_unit = cond(treated, `p'/(1-`p'), probability/(1-probability)) if probability != .

	* make weights sum to treated sample size
	bys treated: g N=_N
	bys treated: egen dummy=total(ipw_unit)
	sum N if inlist(treated,1),meanonly
	replace ipw_unit = ipw_unit / dummy * r(mean)

	* save temp file to merge
	keep ipw_unit event fips
	tempfile temp
	save `temp', replace

	}
	merge m:1 event fips using `temp', nogen update
}