
use DTA/Agency_panel_crime, clear
local j=0
foreach v in crime_murder_rpt crime_share {

	local j=`j'+1

	* Variables to store output
	g est`j'=.
	g upper`j'=.
	g lower`j'=.

	* Pretreatment mean
	sum `v' if time<0 & time>=-1 & treated==1, meanonly
	local b=r(mean)

	* Estimates
	reghdfe `v' t_*  [aw=_unit_`v'] , cluster(unit) a(event#unit event#year event#pop_c##c.popu) 
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
	di "TESTING AVERAGE TREATMENT"
	reghdfe `v' treatment  [aw=_unit_`v'] , cluster(unit) a(event#unit event#year event#pop_c##c.popu) 
	lincom treatment/`b'*100
	local est_overall`j' = trim("`: display %10.2f r(estimate)'")
	local est_se`j' =trim("`: display %10.2f r(se)'")
	if "`v'"=="crime_share"{
		local overall`j' = "%{&Delta} Property crime clearance rate = `est_overall`j'' (`est_se`j'')"
	}
	if "`v'"=="crime_murder_rpt"{
		local overall`j' = "%{&Delta} Reported homicides = `est_overall`j'' (`est_se`j'')"
	}
	di "`overall`j''"
}
	
	
cap drop etime
gen etime = _n-6 in 1/10
keep est* upper* lower* etime
drop if inlist(est1,.)

twoway 	(rbar upper1 lower1 etime , color(${color1}%60) lcolor(white) barw(.5) ) ///
(line est1 etime , sort lwidth(thick) lcol(${color1}%90) lpattern(solid)) ///
(scatter est1 etime , sort col(${color1}*.95) ms(O) ) ///
(rbar upper2 lower2 etime , color(${color2}%60) lcolor(white) barw(.5) ) ///
(line est2 etime , sort lwidth(thick) lcol(${color2}%90) lpattern(solid)) ///
(scatter est2 etime , sort col(${color2}*.95) ms(O) ) ///
, xline(-1, lpatter(dash) lcol(red)) scheme(plotplain) xtitle(Years relative to first protest, size(large)) ///
ytitle("${title1}" "${title2}")  ${yaxis}  xlabel(-5(1)4, labsize(large))  ///
legend(pos(${pos}) ring(0) size(medsmall) order(-5)) ///
yline(0, lcolor(gs10) lpattern(solid)) ///
legend(subtitle("`overall1'" "`overall2'",size(medlarge) position(11))) xsize(7)

graph export "${user}/Output/ferguson_effect_1.pdf", replace

