* Define weights
cap drop _wt*
cap drop _time
g _wt_unit=.
g _wt_time=.
if "`3'" == "qtr"{
	g _time = floor(time/4)
}
else{
	g _time = time
}

* Create population controls
if "`4'"=="pop"{
	tab pop_c, g(_pi)
	foreach v of varlist _pi*{
		g `v'c = `v'*popest
	}
}

* Estimate Synthetic DID weights
tempfile temp
tempvar tframe
sum event, meanonly
local last=r(max)
forvalues e=1/`last'{
	di in red "Stack: `e'/`last'"
	qui{
	cap frame drop `tframe'
	frame put if inlist(event,`e'), into(`tframe')
	frame `tframe'{
		
		if "`4'"=="pop"{	
			if "`3'" == "qtr"{
				gcollapse `1' _p* treatment, by(`2' _time)
			}
			cap sdid `1' `2' _time treatment, vce(bootstrap) seed(219361938) reps(1) covariates(_p*, projected)
			if _rc!=0{
				sdid `1' `2' _time treatment, vce(placebo) seed(219361938) reps(1) covariates(_p*, projected)
			}
		}
		else{
			if "`3'" == "qtr"{
				gcollapse `1' treatment, by(`2' _time)
			}
			cap sdid `1' `2' _time treatment, vce(bootstrap) seed(219361938) reps(1) 
			if _rc!=0{
				sdid `1' `2' _time treatment, vce(placebo) seed(219361938) reps(1) 
			}
		}
		mat unit=e(omega)
		mat time=e(lambda)
		clear
		svmat unit
		rename unit1 _wt_unit
		rename unit2 `2'
		g event = `e'		
		save `temp', replace
	}
	merge m:1 event `2' using `temp', update keep(1 3 4 5) nogen
	frame `tframe'{
		clear
		svmat time
		rename time1 _wt_time
		rename time2 _time
		g event = `e'
		save `temp', replace
	}
	merge m:1 event _time using `temp', update  keep(1 3 4 5) nogen
	}
}
replace _wt_unit=1 if inlist(treated,1)
replace _wt_time=1 if time>=0

* Scale control weights to sum to size of treated group in cohort
cap drop test
bys event: gegen test=nunique(`2') if inlist(treated,1)
bys event (test): replace test=test[_n-1] if inlist(test,.)
replace _wt_unit = _wt_unit * test if inlist(treated,0)
g _wt_sdid = _wt_unit * _wt_time
drop test _time 
cap drop _p*
gsort + event - treated + `2' time
