* Figure options unchanged for all figures
global absorb = "event#time event#fips event#pop_c##c.popest"
global y = "% {&Delta} Lethal Force"
global yaxis = "ylabel(-1(.25)1) ymtick(-.75(.05).5) ysc(titlegap(-5))"
global pos = 11
global title1 = "" 
global title2 = ""

foreach v in protests video{
foreach s in full sub{

	* generate open variables
	use DTA/Stacked_`v'_`s', clear
	
	* Remove homicide with video conditioning on (if in FE sample)
	if "`v'"=="video"{
		replace homicides = homicides - 1 if time==0 & treated==1 & homicides>0 	
	}
	g homicides_pc = homicides / popest

	* Create variables to store output
	g est=.
	g upper=.
	g lower=.
	gen etime = _n-5 in 1/9

	* Pretreatment mean
	sum homicides `weight' if time<0 & time>=-4 & treated==1, meanonly
	local b=r(mean)

	* Estimates
	reghdfe homicides t_* , cluster(fips) a(${absorb}) 
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
		
	* Figure
	global color = "green"
	twoway 	(rbar upper lower etime , color(${color}%60) lcolor(white) barw(.5) ) ///
	(line est etime , sort lwidth(thick) lcol(${color}%90) lpattern(solid)) ///
	(scatter est etime , sort col(${color}*.95) ms(O) ) ///
	, xline(-1, lpatter(dash) lcol(red)) scheme(plotplain) xtitle(Years relative to first protest) ///
	ytitle("${title1}" "${title2}")  ${yaxis}  xlabel(-4(1)4)  ///
	legend(pos(${pos}) ring(0) size(medsmall) order(2 "${y}" 1 "95% Confidence")) ///
	yline(0, lcolor(gs10) lpattern(solid)) legend(subtitle("`overall'",size(medsmall) position(11)))
	graph export "Output/evolution_`v'_`s'.pdf", replace

	* Pretreatment mean
	sum homicides_pc [aw=popest] if time<0 & time>=-4 & treated==1, meanonly
	local b=r(mean)

	* Estimates
	reghdfe homicides_pc t_* [aw=popest], cluster(fips) a(${absorb}) 
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
		
	* Figure
	global color = "midblue"
	twoway 	(rbar upper lower etime , color(${color}%60) lcolor(white) barw(.5) ) ///
	(line est etime , sort lwidth(thick) lcol(${color}%90) lpattern(solid)) ///
	(scatter est etime , sort col(${color}*.95) ms(O) ) ///
	, xline(-1, lpatter(dash) lcol(red)) scheme(plotplain) xtitle(Years relative to first protest) ///
	ytitle("${title1}" "${title2}")  ${yaxis}  xlabel(-4(1)4)  ///
	legend(pos(${pos}) ring(0) size(medsmall) order(2 "${y}" 1 "95% Confidence")) yline(0, lcolor(gs10) lpattern(solid)) ///
	legend(subtitle("`overall'",size(medsmall) position(11)))
	graph export "Output/evolution_`v'_`s'_pop.pdf", replace

	* Pretreatment mean
	sum homicides [aw=ipw] if time<0 & time>=-4 & treated==1, meanonly
	local b=r(mean)

	* Estimates
	reghdfe homicides t_* [aw=ipw], cluster(fips) a(${absorb}) 
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
		
	* Figure
	global color = "pink"
	twoway 	(rbar upper lower etime , color(${color}%60) lcolor(white) barw(.5) ) ///
	(line est etime , sort lwidth(thick) lcol(${color}%90) lpattern(solid)) ///
	(scatter est etime , sort col(${color}*.95) ms(O) ) ///
	, xline(-1, lpatter(dash) lcol(red)) scheme(plotplain) xtitle(Years relative to first protest) ///
	ytitle("${title1}" "${title2}")  ${yaxis}  xlabel(-4(1)4)  ///
	legend(pos(${pos}) ring(0) size(medsmall) order(2 "${y}" 1 "95% Confidence")) yline(0, lcolor(gs10) lpattern(solid)) ///
	legend(subtitle("`overall'",size(medsmall) position(11)))
	graph export "Output/evolution_`v'_`s'_ipw.pdf", replace

	* Pretreatment mean
	sum homicides [aw=ipw_unit_time] if time<0 & time>=-4 & treated==1, meanonly
	local b=r(mean)

	* Estimates
	reghdfe homicides t_* [aw=ipw_unit_time], cluster(fips) a(${absorb}) 
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
		
	* Figure
	global color = "orange_red"
	twoway 	(rbar upper lower etime , color(${color}%60) lcolor(white) barw(.5) ) ///
	(line est etime , sort lwidth(thick) lcol(${color}%90) lpattern(solid)) ///
	(scatter est etime , sort col(${color}*.95) ms(O) ) ///
	, xline(-1, lpatter(dash) lcol(red)) scheme(plotplain) xtitle(Years relative to first protest) ///
	ytitle("${title1}" "${title2}")  ${yaxis}  xlabel(-4(1)4)  ///
	legend(pos(${pos}) ring(0) size(medsmall) order(2 "${y}" 1 "95% Confidence")) yline(0, lcolor(gs10) lpattern(solid)) ///
	legend(subtitle("`overall'",size(medsmall) position(11)))
	graph export "Output/evolution_`v'_`s'_synth.pdf", replace

}
}