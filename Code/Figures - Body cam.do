
use "DTA/Agency_panel_bodycam", clear

* g variables to store output
g est=.
g upper=.
g lower=.

* Special outcome
sum $outcome [aw=weight] if time<0 & time>=-4 & treated==1
local b=r(mean)

* Estimates
reghdfe $outcome t_*  [aw=_wt_unit], cluster(strata) a(${absorb}) 
local i=1
forvalues e=-5/2{
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
reghdfe $outcome treatment  [aw=_wt_unit], cluster(strata) a(${absorb}) 
lincom treatment/`b'*100
local est_overall`j' = trim("`: display %10.2f r(estimate)'")
local est_se`j' =trim("`: display %10.2f r(se)'")
local overall`j' = "%{&Delta} Body cameras = `est_overall`j'' (`est_se`j'')"
di "`overall`j''"

* Figure
cap drop etime
gen etime = _n-6 in 1/10
keep est upper lower etime
drop if est==.
twoway 	(rbar upper lower etime , color(${color}%60) lcolor(white) barw(.5) ) ///
(line est etime , sort lwidth(thick) lcol(${color}%90) lpattern(solid)) ///
(scatter est etime , sort col(${color}*.95) ms(O) ) ///
, xline(-1, lpatter(dash) lcol(red)) scheme(plotplain) xtitle(Years relative to first protest, size(large)) ///
ytitle("${title1}" "${title2}", size(large))  ${yaxis}  xlabel(-5(1)2, labsize(large))  ///
legend(pos(${pos}) ring(0) size(medlarge) order(2 "${y}" 1 "95% Confidence")) yline(0, lcolor(gs10) lpattern(solid)) ///
legend(subtitle("`overall'",size(medlarge) position(11))) xsize(7)
graph export "Output/${outcome}.pdf", replace
