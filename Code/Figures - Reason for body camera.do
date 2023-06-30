
* Open data
use "DTA/Agency_reason_bodycam", clear

* Regressions
g q = _n in 1/15
g b = . 
g ub = .
g lb = .
g mean=.
forvalues i=1/15{
	qui{
		reg Q16M`i' treated [aw=weight], vce(cluster strata)
		lincom treated
		replace b = r(estimate) in `i'
		replace ub = r(ub) in `i'
		replace lb = r(lb) in `i'
		sum Q16M`i' if inlist(treated,0), meanonly
		replace mean = r(mean) in `i'
	}
}

* Figure
twoway rcap ub lb q, lc(navy) || scatter b q, m(0) mc(maroon) || scatter mean q, yaxis(2)	 ///
	xlab( .5 " " 15.5 " "														///
		1 "Officer safety"														///
		2 "Training"															///
		3 "Professionalism"														///
		4 "Officer accountability"												///
		5 "Evidence quality"													///
		6 "Community perception"												///
		7 "Agency liability"													///
		8 "Reduce use-of-force"													///
		9 "Citizen complains"													///
		10 "Incident review"													///
		11 "Leadership"															///
		12 "Prosecutable"														///
		13 "Funding"															///
		14 "External pressure"		 											///
		15 "Pilot test"															///
		, angle( vertical)														///
	)																			///
	ytitle("Change in the share of agencies reporting" "the purpose for body cameras", size(med)) ytitle("Share of agencies without protests" "reporting purpose", size(med) axis(2)) xtitle("") legend(off) xsize(6) yline(0) ylab(,angle(vertical) ax(2))  ylab(,angle(vertical) ax(1)) ysc(titlegap(2)) xlab(,labsize(Small)) scheme(plotplain)

graph export "Output/bodycam_reason.pdf", replace
