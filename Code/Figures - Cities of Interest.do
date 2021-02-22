
use DTA/Stacked, clear

* keep only whats needed to speed up
keep event fips time total_protests treated t_* ${outcome} *_c FIPS popest ipw* city donor

* generate variables for figures
gen beta = .
gen upper = .
gen lower = .
gen loc = ""
gen total =.

* Weights
if "$weight"!=""{
	local w = "_$weight"
	local weight="[aw=$weight]"
}
else{
	local w = ""
	local weight=""
}

* remove case studies without incidents of force in year prior to protests (%change is undefined)
bys event fips: gegen _prior=mean($outcome) if time<0&time>=-16
drop if _prior==0 &treated==1

* Find city's with top number of protests
gegen _top=group(total_protests fips) if total_protests>0
sum _top, meanonly
drop if _top <= r(max) - ${cutoff} + 1 & !inlist(_top,.)

* List cities in decending in number of protests
sum _top, meanonly
replace _top = abs(_top-r(max)-1)

* Labels
replace city="Washington D.C." if city=="Washington city"

* loop over groups for figure
sum _top
local max = r(max)
tempname tempframe
forvalues j = 1 / `max'{
	
	sum event if inlist(_top,`j'), meanonly
	local e = r(mean)
	
	cap frame drop `tempframe'
	frame put if inlist(_top,`j') | (inlist(event,`e') & inlist(treated,0)) , into(`tempframe')
	frame `tempframe'{
		
		* Pretreatment mean
		sum ${outcome} `weight' if time<0 & time>=-16 & treated==1, meanonly
		local b = r(mean)
		
		* Regression
		reghdfe ${outcome} t_* `weight', a(${absorb}) vce(cluster FIPS)
		lincom ((t_5+t_6+t_7+t_8+t_9)/5-(t_1+t_2+t_3+t_4)/4)/`b'
		local beta = r(estimate)
		local upper = r(ub)
		local lower = r(lb)	
		
		* city name
		levelsof city if treated==1, local(city) clean
		
		* number of protests
		sum total_protests if treated==1
		local total = r(mean)
	}
	

	replace beta = `beta' in `j'
	replace upper = `upper' in `j'
	replace lower = `lower' in `j'
	replace loc = "`city'" in `j'
	replace total = `total' in `j'

}

**** Plot Set Up ****
keep beta upper lower loc total _top
replace loc = subinstr(loc, " city", "",.)
gen upper2=upper+.005
gen lower2=lower-.005
drop if beta == .
gen x = -_n
labmask x, values(loc)

twoway (rbar upper lower x ,  color(dknavy) lcolor(dknavy) barw(.07) ) ///
(rbar upper2 upper x ,  color(dknavy) lcolor(dknavy) barw(.3) ) ///
(rbar lower lower2 x ,  color(dknavy) lcolor(dknavy) barw(.3) ) ///
(scatter beta x, m(s)  mc(dknavy) mlc(dknavy) xlabel( -`max'(1)-1, value angle(-90) notick) ytitle("") ylabel(-1(.25)1, angle(-90)) xsc(alt titlegap($gap)) aspect($aspect) xtitle(""))  ///
, ysc(reverse) yline(0) scheme(plotplain) ytitle("") legend(off)  plotregion(margin(none))  ///
ymla(0 "Estimated effect of BLM on lethal use of force", labsize(small) ang(-90)  labgap(6)) 

graph export "Output/cities_${outcome}`last'`w'.pdf", replace


