

use DTA/Agency_panel_crime, clear
g crime_share = crime_property_clr/crime_property_rpt
local j=0
foreach v in crime_share {

	local j=`j'+1

	* Variables to store output
	g est`j'=.
	g upper`j'=.
	g lower`j'=.

	* Pretreatment mean
	sum `v' `weight' if time<0 & time>=-4 & treated==1, meanonly
	local b=r(mean)

	* Estimates
	reghdfe `v' t_*  `weight' , cluster(unit) a(event#unit event#year event#pop_c##c.ucr_population) 
	forvalues i = 1/9{
		di "TESTSING PRETREATMENT `i'"
		lincom (t_`i'-(t_1+t_2+t_3+t_4)/4)/`b'
		replace est`j' = r(estimate) in `i'
		replace upper`j' = r(ub) in `i'
		replace lower`j' = r(lb) in `i'
	}
	reghdfe `v' treatment t_1-t_4  `weight' , cluster(unit) a(event#unit event#year event#pop_c##c.ucr_population) 
		di "TESTING AVERAGE TREATMENT"
		lincom (treatment - (t_1+t_2+t_3+t_4)/4)/`b'
		local est_overall`j' = trim("`: display %10.3f r(estimate)'")
		local est_se`j' =trim("`: display %10.3f r(se)'")
		
		if "`v'"=="crime_share"{
			local overall`j' = "%{&Delta} Cleared share of property crimes = `est_overall`j'' (`est_se`j'')"
		}
		di "`overall`j''"
}
	
	
cap drop etime
gen etime = _n-5 in 1/9
keep est* upper* lower* etime
drop if inlist(est1,.)

twoway 	(rbar upper1 lower1 etime , color(${color3}%60) lcolor(white) barw(.5) ) ///
(line est1 etime , sort lwidth(thick) lcol(${color3}%90) lpattern(solid)) ///
(scatter est1 etime , sort col(${color3}*.95) ms(O) ) ///
, xline(-1, lpatter(dash) lcol(red)) scheme(plotplain) xtitle(Years relative to first protest) ///
ytitle("${title1}" "${title2}")  ${yaxis}  xlabel(-4(1)4)  ///
legend(pos(${pos}) ring(0) size(medsmall) order(-5)) ///
yline(0, lcolor(gs10) lpattern(solid)) ///
legend(subtitle("`overall1'" "`overall2'",size(medsmall) position(11)))

graph export "${user}/Output/ferguson_effect_2.pdf", replace
