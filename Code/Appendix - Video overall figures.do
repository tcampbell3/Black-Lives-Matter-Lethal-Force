* Figure options unchanged for all figures
global absorb = "event#time event#fips event#pop_c##c.popest"
global y = "% {&Delta} Lethal Force"
global yaxis = "ylabel(-1(.25)1) ymtick(-.75(.05).5) ysc(titlegap(-5))"
global pos = 11
global title1 = "" 
global title2 = ""
tempvar tframe
frame create `tframe'
frame `tframe'{
	g est=.
	g upper=.
	g lower=.
	g index=.
}

local i=1
foreach v in protests video{
foreach s in full sub{

	* generate open variables
	use DTA/Stacked_`v'_`s', clear
	
	* Remove homicide with video conditioning on (if in FE sample)
	if "`v'"=="video"{
		replace homicides = homicides - 1 if time==0 & treated==1 & homicides>0 	
	}
	g homicides_pc = homicides / popest

	* Pretreatment mean
	sum homicides `weight' if time<0 & time>=-4 & treated==1, meanonly
	local b=r(mean)

	* Estimates
	reghdfe homicides t_* [aw=ipw_unit_time], cluster(fips) a(${absorb}) 
		di "TESTING AVERAGE TREATMENT"
		lincom ((t_5+t_6+t_7+t_8+t_9)/5 - (t_1+t_2+t_3+t_4)/4)/`b'
		frame post `tframe' (r(estimate)) (r(ub)) (r(lb)) (`i')
		local i=`i'+1
}
}


* Figure
frame `tframe'{

twoway (rcap upper lower index, col(maroon) msize(huge) lw(medthick)) (scatter est index, m(O) color(navy)), yline(0,lp(solid)) ylab(-.5(.25)1) xlab(.5 " " 1 "Protest with video" 2 "Protest without video" 3 "Video with protest" 4 "Video without protest" 4.5 " ") xtitle("") legend(off)
graph export "Output/video_overall.pdf", replace

}