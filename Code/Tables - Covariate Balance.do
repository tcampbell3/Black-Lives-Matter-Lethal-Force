ereturn clear

* generate open variables
use DTA/Stacked, clear

* local controls
local controls = "acs_poverty acs_labor_force acs_unemployment acs_full_time acs_black acs_black_pov acs_lt_high_school acs_high_school acs_some_college acs_college popestimate crime_officer_safety crime_violent_rpt crime_property_rpt ag_wage ag_officers_black geo_density_pop_land pol_dem_share"

* Pretreatment only
keep if inlist(year, 2013)
gcollapse `controls' ipw* treated donor, by(fips)

* label controls
label var acs_poverty "Poverty"
label var acs_labor_force "Labor force participation rate"
label var acs_unemployment "Unemployment rate"
label var acs_full_time "Full time employment rate"
label var acs_black "Black population"
label var acs_black_pov "Black poverty rate"
label var acs_lt_high_school "$<$ High school"
label var acs_high_school "High school"
label var acs_some_college "Some college"
label var acs_college "College"
label var popestimate "Population (100,000s)"
label var crime_officer_safety "Officer safety"
label var crime_violent_rpt "Violent crime rate"
label var crime_property_rpt "Property crime rate"
label var ag_wage "Officer wage"
label var ag_officers_black "Share of black officers"
label var geo_density_pop_land  "Population density (10,000s per mile)"
label var pol_dem_share "2008 pres. democratic vote share"

* Format large variables
replace popestimate = popestimate / 100000
replace geo_density_pop_land= geo_density_pop_land / 10000

* Joint F-test (and individual t-tests) frame
preserve
	g stack=0
	g name=""
	tempfile temp
	tempvar tframe
	local i=1
	foreach v of varlist `controls'{
		cap frame drop `tframe'
		frame put `v' treated stack ipw* popest name, into(`tframe')
		frame `tframe'{
			keep if inlist(stack,0)
			rename `v' control
			replace stack=`i'
			replace name="`v'"
			local i = `i'+1
			save `temp', replace
		}
		append using `temp'
	}
	drop if inlist(stack,0)
	keep control stack name treated ipw* popest
	reghdfe control c.treated#i.stack [aw=ipw], a(stack)  vce(robust)
	cap frame drop `tframe'
	frame put *, into(`tframe')
restore

* table
frame `tframe': reghdfe control c.treated#i.stack, a(stack)  vce(robust)
local ftest=e(F)
local df1=e(df_a)
local df2=e(df_r)
estpost sum `controls' if treated==1
eststo est1
estadd scalar ftest = `ftest'

estpost sum `controls'  if donor==1
eststo est2
estadd scalar ftest = `ftest'

frame `tframe': reghdfe control c.treated#i.stack [aw=popest], a(stack)  vce(robust)
local ftest=e(F)
estpost sum `controls' [aw=popestimate] if treated==1
eststo est3
estadd scalar ftest = `ftest'

estpost sum `controls'  [aw=popestimate] if donor==1
eststo est4
estadd scalar ftest = `ftest'

frame `tframe': reghdfe control c.treated#i.stack [aw=ipw], a(stack)  vce(robust)
local ftest=e(F)
estpost sum `controls' [aw=ipw] if treated==1
eststo est5
estadd scalar ftest = `ftest'

estpost sum `controls' [aw=ipw] if donor==1
eststo est6
estadd scalar ftest = `ftest'

frame `tframe': reghdfe control c.treated#i.stack [aw=ipw_unit], a(stack)  vce(robust)
local ftest=e(F)
estpost sum `controls' [aw=ipw_unit] if treated==1
eststo est7
estadd scalar ftest = `ftest'

estpost sum `controls'  [aw=ipw_unit] if donor==1
eststo est8
estadd scalar ftest = `ftest'

frame `tframe': reghdfe control c.treated#i.stack [aw=ipw_unit_time], a(stack)  vce(robust)
local ftest=e(F)
estpost sum `controls' [aw=ipw_unit_time] if treated==1
eststo est9
estadd scalar ftest = `ftest'

estpost sum `controls'  [aw=ipw_unit_time] if donor==1
eststo est10
estadd scalar ftest = `ftest'

esttab est1 est2 est3 est4 est5 est6 est7 est8 est9 est10 using "Output/cov_balance.tex", scalars("N Observations" "ftest \$ F_{`df1',\; `df2'}\$") main(mean "%4.2f") aux(sd "%4.2f") nostar unstack noobs nonote label  nogaps nonotes mtitles("Treated" "Control" "Treated" "Control"  "Treated" "Control" "Treated" "Control" "Treated" "Control") mgroups("Unweighted" "Population" "IPW Controls" "IPW Unit" "IPW Unit-Time", pattern(1 0 1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) replace substitute( )

* Exit stata
exit, clear STATA