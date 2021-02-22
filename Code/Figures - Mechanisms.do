* Create frame
cap frame change default
cap frame drop figure
frame create figure est ub lb x

* Loop over number of columns
forvalues c = 1/12{
	
	* col number
	local firstrow = "`firstrow' & (`c')"
	
	* specification
	if `c' == 1 {
		
		use "DTA/Agency_panel_bodycam", clear
		g time = qtr
		local Time = "`Time' & Quarter"
		local Years = "`Years' & 2010-2016"
		local outcome = "ag_bodycam"
		local Outcome = "`Outcome' & Body cameras"
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "i.time i.unit"
		local Bench = "`Bench' & 1 "	
		local a=1
	
	}
	if `c' == 2 {
	
		use "DTA/Agency_panel_characteristics", clear
		g time = year
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2013, 2016"
		local outcome = "ag_cp_npatrol_total"
		local Outcome = "`Outcome' & Patrol officers"
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "i.time i.unit"
		local Bench = "`Bench' & 1 "	
		local a=1
		
	}
	if `c' == 3 {
	
		use "DTA/Agency_panel_characteristics", clear
		g time = year
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2013, 2016"
		local outcome = "ag_cp_nsara_total"
		local Outcome = "`Outcome' & Sara officers"
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "i.time i.unit"
		local Bench = "`Bench' & 1 "	
		local a=1		

	}
	if `c' == 4 {
	
		use "DTA/Agency_panel_characteristics", clear
		g time = year
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2013, 2016"
		local outcome = "ag_officers_black_total"
		local Outcome = "`Outcome' & Black officers"
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "i.time i.unit"
		local Bench = "`Bench' & 1 "	
		local a=1

	}
	if `c' == 5 {
		
		use "DTA/Agency_panel_characteristics", clear
		g time = year
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2013, 2016"
		local outcome = "ag_officers_white_total"
		local Outcome = "`Outcome' & White officers"
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "i.time i.unit"
		local Bench = "`Bench' & 1 "	
		local a=1
		
	}
	if `c' == 6 {
		
		use "DTA/Agency_panel_characteristics", clear
		g time = year
		g experienced =  (ag_officers-ag_new_officers_total) * ((ag_officers-ag_new_officers_total)>0)
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2013, 2016"
		local outcome = "experienced"
		local Outcome = "`Outcome' & Exp. officers"
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "i.time i.unit"
		local Bench = "`Bench' & 1 "	
		local a=1		
	
	}	
	if `c' == 7 {
	
		use "DTA/Agency_panel_characteristics", clear
		g time = year
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2013, 2016"
		local outcome = "ag_min_edu"
		local Outcome = "`Outcome' & College required"
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "i.time i.unit"
		local Bench = "`Bench' & 1 "	
		local a=1
		
	}
	if `c' == 8 {
	
		use "DTA/Agency_panel_characteristics", clear
		g time = year
		g _force = ag_doc_chem == 1 |  ag_doc_discharge == 1 | ag_doc_display == 1 | ag_doc_neck == 1
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2013, 2016"
		local outcome = "_force"
		local Outcome = "`Outcome' & Force doc."
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "i.time i.unit"
		local Bench = "`Bench' & 1 "	
		local a=1
		
	}		
	if `c' == 9 {
	
		use "DTA/Agency_panel_characteristics", clear
		g time = year
		replace ag_budget = ag_budget/1000000
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2013, 2016"
		local outcome = "ag_budget"
		local Outcome = "`Outcome' & \small{Budget (millions)}"
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "i.time i.unit"
		local Bench = "`Bench' & 1 "	
		local a=1
		
	}
	if `c' == 10 {
	
		use "DTA/Agency_panel_crime", clear
		g time = year
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2000-2019"
		local outcome = "crime_officer_assaulted"
		local Outcome = "`Outcome' & Officer assault"
		local weight = ""
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "i.time i.unit"
		local Bench = "`Bench' & 1 "	
		local a=1
		
	}
	if `c' == 11 {
	
		use "DTA/Agency_panel_crime", clear
		g time = year
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2010-2019"
		local outcome = "crime_violent"
		local Outcome = "`Outcome' & Violent arrests"
		local weight = ""
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "i.time i.unit"
		local Bench = "`Bench' & 1 "	
		local a=1
		
	}
	if `c' == 12{
	
		use "DTA/Agency_panel_crime", clear
		g time = year
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2010-2019"
		local outcome = "crime_property"
		local Outcome = "`Outcome' & Property arrests"
		local weight = ""
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "i.time i.unit"
		local Bench = "`Bench' & 1 "	
		local a=1
		
	}
	
	
	* Find pretreatment mean
	drop if year<2010
	sum `outcome' `weight' if inlist(treated, 1) & inlist(treatment,0), meanonly
	local b=r(mean)
	
	* Estimates	
	reghdfe `outcome' treatment `weight', cluster(unit) absorb(`absorb' )
	di "TESTING AVERAGE TREATMENT"
	lincom (treatment)/`b'
	local est = r(estimate)
	local ub = r(ub)
	local lb = r(lb)
	local x = `c'
	frame post figure  (`est') (`ub') (`lb') (`x')
	
}





*** Figure ****
frame figure{
twoway (bar est x, barw(.5) color(midblue%60)  yline(0, lp(solid)))	///
	(rcap ub lb x, lc(red%60)  scheme(plotplain)),	///
	xlabel(1 `" "Body" "cameras" "' 2 `" "Local" "patrol" "officers" "' 3 `" "SARA" "officers" "'	///
		4 `" "Black" "officers" "' 5 `" "White" "officers" "' 6 `" "Exp." "officers" "' ///
		7 `" "College" "req." "' 8 `" "Force" "doc." "' 9 `" "Budget" "' 10 `" "Officer" "assaults "'	///
		11 `" "Violent" "arrests "' 12 `" "Property" "arrests "', labsize(medium)) ///
	ytitle("Percentage change", size(medlarge)) legend(off) ylabel(-.5(.5)1.5, labsize(medium)) ///
	xtitle("") xsize(8) 
graph export "${user}/Output/Mechanisms.pdf", replace
}
cap frame drop figure
 
