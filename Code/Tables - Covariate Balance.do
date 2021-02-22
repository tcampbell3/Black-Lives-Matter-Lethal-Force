ereturn clear

* generate open variables
use DTA/Stacked, clear

* local controls
local controls = "acs_poverty acs_labor_force acs_unemployment acs_full_time acs_black acs_black_pov acs_lt_high_school acs_high_school acs_some_college acs_college popestimate crime_officer_safety crime_violent_rpt crime_property_rpt ag_wage ag_officers_black geo_density_pop_land pol_dem_share"

* label controls
label var acs_poverty "Poverty"
label var acs_labor_force "Labor force participation rate"
label var acs_unemployment "Unemployment rate"
label var acs_full_time "Full time employment rate"
label var acs_black "Black populiation"
label var acs_black_pov "Black poverty rate"
label var acs_lt_high_school "$<$ High school"
label var acs_high_school "High school"
label var acs_some_college "Some college"
label var acs_college "College"
label var popestimate "Population (100,000s)"
label var crime_officer_safety "Officer safety"
label var crime_violent_rpt "Total violent crime index (100s)"
label var crime_property_rpt "Total property crime index (100s)"
label var ag_wage "Officer wage"
label var ag_officers_black "Share of black officers"
label var geo_density_pop_land  "Population density (10,000s per mile)"
label var pol_dem_share "2008 pres. democratic vote share"

* Format large variables
replace popestimate = popestimate / 100000
replace geo_density_pop_land= geo_density_pop_land / 10000
replace crime_violent_rpt = crime_violent_rpt / 100
replace crime_property_rpt = crime_property_rpt / 100


* table
estpost sum `controls' if treated==1
eststo est1

estpost sum `controls'  if donor==1
eststo est2

estpost sum `controls' [aw=popestimate] if treated==1
eststo est3

estpost sum `controls'  [aw=popestimate] if donor==1
eststo est4

estpost sum `controls' [aw=ipw] if treated==1
eststo est5

estpost sum `controls' [aw=ipw] if donor==1
eststo est6

estpost sum `controls' [aw=ipw_unit] if treated==1
eststo est7

estpost sum `controls'  [aw=ipw_unit] if donor==1
eststo est8

estpost sum `controls' [aw=ipw_unit_time] if treated==1
eststo est9

estpost sum `controls'  [aw=ipw_unit_time] if donor==1
eststo est10

esttab est1 est2 est3 est4 est5 est6 est7 est8 est9 est10 using "Output/cov_balance.tex", scalars(N) main(mean "%4.2f") aux(sd "%4.2f") nostar unstack noobs nonote label  nogaps nonotes mtitles("Treated" "Control" "Treated" "Control"  "Treated" "Control" "Treated" "Control" "Treated" "Control") mgroups("Unweighted" "Population" "IPW Controls" "IPW Unit" "IPW Unit-Time", pattern(1 0 1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) replace

* Exit stata
exit, clear STATA