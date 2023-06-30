
* Variables to store output
use DTA/${sample}, clear
g est=.
g upper=.
g lower=.

* Pretreatment mean
sum $outcome if time<0 & time>=-4 & treated==1, meanonly
local b=r(mean)

* Estimates
if "`1'"=="contiguous"{
	reghdfe $outcome t_*  ${weight} , vce(cluster fips pair) a(${absorb})
}
else{
    reghdfe $outcome t_*  ${weight} , vce(cluster fips) a(${absorb})
}
local i=1
forvalues e=-5/4{
	if `e'<-1{
		local z=abs(`e')
		lincom (t_pre`z')/`b'*100
	}
	if `e'>=0{
		lincom (t_post`e')/`b'*100
	}
	if `e'==-1{
		replace est`j' = 0 in `i'
		replace upper`j' = 0 in `i'
		replace lower`j' = 0 in `i'
	}
	else{
		replace est`j' = r(estimate) in `i'
		replace upper`j' = r(ub) in `i'
		replace lower`j' = r(lb) in `i'
	}
	local i=`i'+1
}	
if "`1'"=="contiguous"{
	reghdfe $outcome treatment ${weight} , vce(cluster fips pair) a(${absorb})
}
else{
    reghdfe $outcome treatment ${weight} , vce(cluster fips) a(${absorb})
}
lincom treatment/`b'*100
local est_overall`j' = trim("`: display %10.2f r(estimate)'")
local est_se`j' =trim("`: display %10.2f r(se)'")
local overall`j' = "${y} = `est_overall`j'' (`est_se`j'')"
di "`overall`j''"

* Figure
cap drop etime
gen etime = _n-6 in 1/10
keep est upper lower etime
drop if est==.
twoway 	(rbar upper lower etime , color(${color}%60) lcolor(white) barw(.5) ) ///
(line est etime , sort lwidth(thick) lcol(${color}%90) lpattern(solid)) ///
(scatter est etime , sort col(${color}*.95) ms(O) ) ///
, xline(-1, lpatter(dash) lcol(red)) scheme(plotplain) xtitle(Years relative to first protest,size(large)) ///
ytitle("${title}",size(large))  ${yaxis}  xlabel(-5(1)4,labsize(large))  ///
legend(pos(${pos}) ring(0) size(large) order(-5))  yline(0, lcolor(gs10) lpattern(solid)) ///
legend(subtitle("`overall'",size(large) position(11))) xsize(7)
graph export "Output/${path}.pdf", replace
