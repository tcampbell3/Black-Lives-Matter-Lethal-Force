
* Variables to store output
use DTA/Stacked, clear
g est=.
g upper=.
g lower=.

* Special outcome
cap drop protest_total
bys event fips (time): g protests_total = sum(protests)

* Estimates
reghdfe protests_total t_post* , cluster(fips) a(${absorb}) 
local i=1
forvalues e=-5/4{
	if `e'<=-1{
		replace est = 0 in `i'
		replace upper = 0 in `i'
		replace lower = 0 in `i'
	}
	if `e'>=0{
		lincom (t_post`e')
		replace est = r(estimate) in `i'
		replace upper = r(ub) in `i'
		replace lower = r(lb) in `i'
	}
	local i=`i'+1
}	
di "TESTING AVERAGE TREATMENT"
reghdfe protests_total treatment , cluster(fips) a(${absorb}) 
lincom treatment
local est_overall`j' = trim("`: display %10.3f r(estimate)'")
local est_se`j' =trim("`: display %10.3f r(se)'")
local overall = "{&Delta} Protests = `est_overall' (`est_se')"
di "`overall'"
	
* Figure
cap drop etime
gen etime = _n-6 in 1/10
keep est upper lower etime
drop if est==.
twoway 	(rbar upper lower etime , color(${color}%60) lcolor(white) barw(.5) ) ///
(line est etime , sort lwidth(thick) lcol(${color}%90) lpattern(solid)) ///
(scatter est etime , sort col(${color}*.95) ms(O) ) ///
, xline(-1, lpatter(dash) lcol(red)) scheme(plotplain) xtitle(Years relative to first protest, size(large)) ///
ytitle("${title}", size(large))  ${yaxis}  xlabel(-5(1)4, labsize(large))  ///
legend(pos(${pos}) ring(0) size(large) order(-5)) yline(0, lcolor(gs10) lpattern(solid)) ///
legend(subtitle("`overall'",size(large) position(11)) region(color(none))) xsize(7)

graph export "Output/cum_protests.pdf", replace
