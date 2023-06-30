* Set up
tempfile temp
tempvar tframe
frame create `tframe'

* Controls
local controls = "acs_poverty acs_labor_force acs_unemployment acs_full_time acs_black acs_black_pov acs_lt_high_school acs_high_school acs_some_college acs_college popestimate crime_officer_safety crime_violent_rpt crime_property_rpt ag_wage ag_officers_black geo_density_pop_land pol_dem_share"

* Save 2013 controls (carry officer data forward one year if missing from 2012 lemeas)
use DTA/Summary,clear
keep if inlist(year, 2013)
gcollapse `controls', by(fips)
destring fips, replace
save `temp', replace

* Merge controls to stacked data
use DTA/stacked_pop_150000, clear
cap g year = int(qtr/10)
keep if inlist(year,2013)
keep event fips treated ipw
merge m:1 fips using `temp', nogen keep(3)
gcollapse (mean) `controls' treated ipw, by(fips)

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
		frame put `v' treated stack name fips ipw, into(`tframe')
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
	keep control stack name treated fips ipw
	reghdfe control c.treated#i.stack [aw=ipw], a(stack) vce(cluster fips) nocons
	local df1=e(df_a)
	local df2=e(df_r)	
	local ftest: di %10.3gc round(e(F),.01)	
	cap frame drop `tframe'
	frame put *, into(`tframe')
restore

* Dummy regression
quietly reg fips
eststo dummy

* Column 1 - treated mean
est restore dummy
eststo treated
foreach v of varlist `controls' {
	sum `v' [aw=ipw] if inlist(treated,1)
	if abs(r(mean))>=1 {
		local b: di %10.3fc round(r(mean),.001)
	}
	if abs(r(mean))<1 & r(mean)<0{
		local b: di %10.3fc round(r(mean),.001)
		local b = "-" + substr(trim("`b'"), 3, .)
	}
	if abs(r(mean))<1 & r(mean)>0 | r(mean) == 0 {
		local b: di %10.3fc round(r(mean),.001)
		local b = substr(trim("`b'"), 2, .)
	}		
	estadd local `v'="`b'"
}
estadd local blank=""
estadd local ctitle="Treated"
unique fips if inlist(treated,1)
estadd scalar places = `r(unique)'

* Column 2 - control mean
est restore dummy
eststo control
foreach v of varlist `controls' {
	sum `v' [aw=ipw] if inlist(treated,0)
	if abs(r(mean))>=1 {
		local b: di %10.3fc round(r(mean),.001)
	}
	if abs(r(mean))<1 & r(mean)<0{
		local b: di %10.3fc round(r(mean),.001)
		local b = "-" + substr(trim("`b'"), 3, .)
	}
	if abs(r(mean))<1 & r(mean)>=0 | r(mean) == 0 {
		local b: di %10.3fc round(r(mean),.001)
		local b = substr(trim("`b'"), 2, .)
	}
	estadd local `v'="`b'"
}
estadd local blank=""
estadd local ctitle="Control"
unique fips if inlist(treated,0)
estadd scalar places = `r(unique)'

* Column 3 - Difference
est restore dummy
eststo difference`d'
foreach v of varlist `controls' {
	reg `v' treated [aw=ipw], vce(cluster fips)
	lincom treated
	if abs(r(estimate))>=1{
		local b: di %10.3fc round(r(estimate),.001)
	}
	if abs(r(estimate))<1 & r(estimate)<0{
		local b: di %10.3fc round(r(estimate),.001)
		local b = "-" + substr(trim("`b'"), 3, .)
	}
	if abs(r(estimate))<1 & r(estimate)>=0 | r(estimate) == 0 {
		local b: di %10.3fc round(r(estimate),.001)
		local b = substr(trim("`b'"), 2, .)
	}
	local se: di %10.3fc round(r(se),.001)	
	local se = substr(trim("`se'"), 2, .)
	est restore difference`d'
	estadd local `v'="`b' (`se')"
}
estadd local blank=""
estadd local ctitle="Difference"
estadd local ftest="`ftest'"

* Table
esttab treated control difference using Output/low_pop_cov_balance.tex, ///
	stats(ctitle acs_poverty acs_labor_force acs_unemployment acs_full_time 	///
		acs_black acs_black_pov acs_lt_high_school acs_high_school acs_some_college  ///
		acs_college popestimate crime_officer_safety crime_violent_rpt crime_property_rpt ///
		ag_wage ag_officers_black geo_density_pop_land pol_dem_share 			///
		ftest places,															///
		fmt( %010.3gc )															///
		label(																	///
		" "																		///
		"\midrule\addlinespace[0.3cm]  Poverty"									///
		"\addlinespace[0.3cm] Labor force participation rate"					///
		"\addlinespace[0.3cm] Unemployment rate"								///
		"\addlinespace[0.3cm] Full time employment rate"						///
		"\addlinespace[0.3cm] Black population"									///
		"\addlinespace[0.3cm] Black poverty rate"								///
		"\addlinespace[0.3cm] $<$ High school"									///
		"\addlinespace[0.3cm] High school"										///
		"\addlinespace[0.3cm] Some college"										///
		"\addlinespace[0.3cm] College"											///
		"\addlinespace[0.3cm] Population (100,000s)"							///
		"\addlinespace[0.3cm] Officer safety"									///
		"\addlinespace[0.3cm] Violent crime rate"								///
		"\addlinespace[0.3cm] Property crime rate"								///
		"\addlinespace[0.3cm] Officer wage"										///
		"\addlinespace[0.3cm] Share of black officers"							///
		"\addlinespace[0.3cm] Population density (10,000s per mile)"			///
		"\addlinespace[0.3cm] 2008 pres. democratic vote share"					///
		"\addlinespace[0.3cm] \midrule $ F_{`df1',\; `df2'}\$"					///
		"\addlinespace[0.1cm] Census places"									///
		)																		///
	)																			///
	keep( ) replace nomtitles nonotes booktabs nogap nolines nonum			 	///	
	prehead(\begin{tabular}{l x{1.4cm} x{1.4cm} x{2.8cm}} \midrule\midrule) ///
	postfoot(\midrule\midrule \end{tabular}) substitute(_ _)

* Exit stata
exit, clear STATA