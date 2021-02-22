

* generate open variables
use DTA/Stacked, clear

* g variables to store output
g est=.
g upper=.
g lower=.

* Weights
if "$weight"!=""{
	local w = "_$weight"
	local weight="[aw=$weight]"
}
else{
	local w = ""
	local weight=""
}

* Special outcome
if "${outcome}"== "protests_total"{
	local b=1
	cap drop protest_total
	bys event fips (time): g protests_total = sum(protests)
}
else{ // find pretreatment value
	quietly sum $outcome `weight' if time<0 & time>=-4 & treated==1
	local b=r(mean)
}

* Estimates
reghdfe $outcome t_*  `weight' , cluster(FIPS) a(${absorb}) 
forvalues i = 1/9{
	di "TESTSING PRETREATMENT `i'"
	lincom (t_`i'-(t_1+t_2+t_3+t_4)/4)/`b'
	replace est = r(estimate) in `i'
	replace upper = r(ub) in `i'
	replace lower = r(lb) in `i'
}
	di "TESTING AVERAGE TREATMENT"
	lincom ((t_5+t_6+t_7+t_8+t_9)/5 - (t_1+t_2+t_3+t_4)/4)/`b'
	local est_overall = trim("`: display %10.3f r(estimate)'")
	local est_se =trim("`: display %10.3f r(se)'")
	local overall = "Total Effect = `est_overall' (`est_se')"
	di "`overall'"
	

cap drop etime
gen etime = _n-5 in 1/9

keep est upper lower etime
drop if est==.

twoway 	(rbar upper lower etime , color(${color}%60) lcolor(white) barw(.5) ) ///
(line est etime , sort lwidth(thick) lcol(${color}%90) lpattern(solid)) ///
(scatter est etime , sort col(${color}*.95) ms(O) ) ///
, xline(-1, lpatter(dash) lcol(red)) scheme(plotplain) xtitle(Years relative to first protest) ///
ytitle("${title1}" "${title2}")  ${yaxis}  xlabel(-4(1)4)  ///
legend(pos(${pos}) ring(0) size(medsmall) order(2 "${y}" 1 "95% Confidence")) yline(0, lcolor(gs10) lpattern(solid)) ///
legend(subtitle("`overall'",size(medsmall) position(11)))

graph export "Output/${outcome}/${outcome}`w'${path}.pdf", replace
