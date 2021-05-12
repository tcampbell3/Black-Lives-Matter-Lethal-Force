clear all

* Maps
use DTA/Stacked_county, clear
gcollapse (max) treated contiguous synth_unit, by(fips)
g county=fips
maptile treated, geo(county2010) cutv(.5) twopt(legend(pos(5) order(3 "Treated" 2 "Control"))) fc(BuRd) stateoutline(medium)
graph export "Output/Maps/county_map_all.png", replace
maptile treated if inlist(contiguous,1), geo(county2010) cutv(.5) twopt(legend(pos(5) order(3 "Treated" 2 "Control" 1 "Omitted"))) fc(BuRd) stateoutline(medium) 
graph export "Output/Maps/county_map_contiguous.png", replace
replace synth_unit=. if inlist(synth_unit,1)
maptile synth_unit, geo(county2010) cutv(.01 .05 .1 .25 .5)  twopt(legend(pos(5) order(1 "Treated" 7 ".50-1" 6 ".25-.50" 5 ".10-.25" 4 ".05-.10" 3 ".01-.05" 2 "<.01"))) fc(Blues) stateoutline(medium)  ndf(maroon)
graph export "Output/Maps/county_map_synth.png", replace

* Event time figures
use DTA/Stacked_county, clear
g est=.
g upper=.
g lower=.
gen etime = _n-5 in 1/9

* Event time figures
forvalues r=1/4{
	if `r'==1{
		local outcome="homicides"
		local weight1=""
		local weight2="if inlist(time,-1)&inlist(treated,1) "
		global color = "green"
	}
	if `r'==2{
		local outcome="homicides_p"
		local weight1="[aw=popest]"	
		local weight2="if inlist(time,-1)&inlist(treated,1) "
		global color = "midblue"
	}
	if `r'==3{
		local outcome="homicides"
		local weight1="if inlist(contiguous,1)"
		local weight2="if inlist(time,-1)&inlist(treated,1)&inlist(contiguous,1)"
		global color = "purple"
	}
	if `r'==4{
		local outcome="homicides"
		local weight1="[aw=synth_unit]"
		local weight2="if inlist(time,-1)&inlist(treated,1) "
		global color = "orange_red"
	}
	reghdfe `outcome' t_* `weight1', a(event#fips event#time event#pop_c##c.popest) vce(cluster fips)
	sum `outcome' `weight2'
	local b=r(mean)
	forvalues i = 1/9{
		lincom (t_`i'-(t_1+t_2+t_3+t_4)/4)/`b'
		replace est = r(estimate) in `i'
		replace upper = r(ub) in `i'
		replace lower = r(lb) in `i'
	}
		lincom ((t_5+t_6+t_7+t_8+t_9)/5 - (t_1+t_2+t_3+t_4)/4)/`b'
		local est_overall = trim("`: display %10.3f r(estimate)'")
		local est_se =trim("`: display %10.3f r(se)'")
		local overall = "Total Effect = `est_overall' (`est_se')"
	twoway 	(rbar upper lower etime , color(${color}%60) lcolor(white) barw(.5) ) ///
	(line est etime , sort lwidth(thick) lcol(${color}%90) lpattern(solid)) ///
	(scatter est etime , sort col(${color}*.95) ms(O) ) ///
	in 1/9, xline(-1, lpatter(dash) lcol(red)) scheme(plotplain) xtitle(Years relative to first protest) ///
	ytitle("% {&Delta} Lethal Force")  ylabel(-.75(.25).5) ymtick(-.75(.05).5) ysc(titlegap(0)) ///
	xlabel(-4(1)4) yline(0, lcolor(gs10) lpattern(solid)) legend(pos(1) ring(0) size(medsmall) ///
	order(2 "% {&Delta} Lethal Force" 1 "95% Confidence") subtitle("`overall'",size(medsmall) position(11)))
	graph export "Output/county_etime_`r'.pdf", replace
}