use DTA/Stacked, clear
bys event fips: gegen test=sum(homicides) if inlist(floor(time/4),-1,-2,-3)
bys event fips (test): replace test=test[_n-1] if inlist(test,.)
drop if inlist(test,0)
drop test
bys event: gegen test=max(treated)
drop if inlist(test,0)
gegen _event = group(event)
drop event
rename _event event
cap drop pop_c
fasterxtile pop_c=popest, n(10)
do "Do Files/sdid" homicides fips qtr pop

* Variables to store output
g est=.
g upper=.
g lower=.

* Pretreatment mean
sum homicides if time<0 & time>=-4 & treated==1, meanonly
local b=r(mean)

* Estimates
reghdfe homicides t_* [aw=_wt_unit], vce(cluster fips) a(event#fips event#time event#pop_c##c.popest) 
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
reghdfe homicides treatment [aw=_wt_unit], vce(cluster fips) a(event#fips event#time event#pop_c##c.popest) 
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
graph export "Output/estudy_one_killing.pdf", replace
