
* Round
cap program drop _round
program _round, rclass
	syntax [, number(real 50)]
	di `number'
	if abs(`number')>=100{
		local rounded = trim("`: display %10.0fc `number''")
	}
	if abs(`number')<100{
		local rounded = trim("`: display %10.1fc `number''")
	}
	if abs(`number')<10{
		local rounded = trim("`: display %10.2fc `number''")
	}	
	if abs(`number')<1{
		local rounded = trim("`: display %10.3fc `number''")
	}
	return local rounded="`rounded'"
end
	
* Loop over number of columns
forvalues c = 1/9{
	
	* col number
	local firstrow = "`firstrow' & (`c')"
	
	* specification
	if `c' == 1 {
		
		use "DTA/Agency_panel_bodycam", clear
		local Time = "`Time' & Quarter"
		local Years = "`Years' & 2000-2016"
		local outcome = "ag_bodycam"
		local Outcome = "`Outcome' & Body cameras"
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#unit event#pop_c##c.ucr_population"
		local Bench = "`Bench' & 1 "	
		local dataset="bodycam"
	
	}
	if `c' == 2 {
	
		use "DTA/Agency_panel_characteristics", clear
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2013, 2016"
		local outcome = "ag_cp_npatrol_total"
		local Outcome = "`Outcome' & Patrol officers"
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#unit event#pop_c##c.ucr_population"
		local Bench = "`Bench' & 1 "	
		local dataset="2year"
			
	}
	if `c' == 3 {
	
		use "DTA/Agency_panel_characteristics", clear
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2013, 2016"
		local outcome = "ag_cp_nsara_total"
		local Outcome = "`Outcome' & Sara officers"
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#unit event#pop_c##c.ucr_population"
		local Bench = "`Bench' & 1 "	
		local dataset="2year"

	}
	if `c' == 4 {
	
		use "DTA/Agency_panel_characteristics", clear
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2013, 2016"
		local outcome = "ag_officers_black_total"
		local Outcome = "`Outcome' & Black officers"
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#unit event#pop_c##c.ucr_population"
		local Bench = "`Bench' & 1 "	
		local dataset="2year"

	}
	if `c' == 5 {
		
		use "DTA/Agency_panel_characteristics", clear
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2013, 2016"
		local outcome = "ag_officers_white_total"
		local Outcome = "`Outcome' & White officers"
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#unit event#pop_c##c.ucr_population"
		local Bench = "`Bench' & 1 "	
		local dataset="2year"
		
	}
	if `c' == 6 {
		
		use "DTA/Agency_panel_characteristics", clear
		g experienced =  (ag_officers-ag_new_officers_total) * ((ag_officers-ag_new_officers_total)>0)
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2013, 2016"
		local outcome = "experienced"
		local Outcome = "`Outcome' & Exp. officers"
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#unit event#pop_c##c.ucr_population"
		local Bench = "`Bench' & 1 "	
		local dataset="2year"
	
	}	
	if `c' == 7 {
	
		use "DTA/Agency_panel_characteristics", clear
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2013, 2016"
		local outcome = "ag_min_edu"
		local Outcome = "`Outcome' & College required"
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#unit event#pop_c##c.ucr_population"
		local Bench = "`Bench' & 1 "	
		local dataset="2year"
		
	}
	if `c' == 8 {
	
		use "DTA/Agency_panel_characteristics", clear
		g _force = ag_doc_chem == 1 |  ag_doc_discharge == 1 | ag_doc_display == 1 | ag_doc_neck == 1
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2013, 2016"
		local outcome = "_force"
		local Outcome = "`Outcome' & Force doc."
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#unit event#pop_c##c.ucr_population"
		local Bench = "`Bench' & 1 "	
		local dataset="2year"
		
	}		
	if `c' == 9 {
	
		use "DTA/Agency_panel_characteristics", clear
		replace ag_budget = ag_budget/1000000
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2013, 2016"
		local outcome = "ag_budget"
		local Outcome = "`Outcome' & \small{Budget (millions)}"
		local weight = "[aw=weight]"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#unit event#pop_c##c.ucr_population"
		local Bench = "`Bench' & 1 "	
		local dataset="2year"
		
	}
	
	* Find pretreatment mean
	sum `outcome' `weight' if time<0 & time>=-4 & treated==1, meanonly
	local b=r(mean)
	_round , number(`b')
	local rounded = r(rounded)
	local Mean = "`Mean' & `rounded' "
	
	* Estimates	
	if "`dataset'"=="2year"{
		reghdfe `outcome' treatment `weight', cluster(strata) absorb(`absorb' )
		di "TESTING AVERAGE TREATMENT"
		lincom treatment/`b'
	}
	else{
		reghdfe `outcome' treatment t_1-t_4 `weight', cluster(strata) absorb(`absorb' )
		di "TESTING AVERAGE TREATMENT"
		lincom (treatment - (t_1+t_2+t_3+t_4)/4)/`b'
	}
	local est_overall = trim("`: display %10.3f r(estimate)'")
	local post_ave = r(estimate)
	local est_se =trim("`: display %10.3f r(se)'")
	local b_ave = " `b_ave'& `est_overall'"
	local se_ave =" `se_ave' & (`est_se')"

	* Sample Size
	local n = trim("`: display %10.0fc e(N_full)'")
	local N = "`N' & \small{`n'} "
	
	* Treated
	unique unit if treated==1	
	local t = trim("`: display %10.0fc r(unique)'")
	local treated = "`treated' & `t'"
	
	* Donor
	unique unit if donor==1	
	local d = trim("`: display %10.0fc r(unique)'")
	local donor = "`donor' & `d'"

	* Total Protests
	cap drop _total_protests
	egen _total_protests = total(protests) 
	sum _total_protests
	local t2 = trim("`: display %10.0fc r(mean)'")
	local _total_protests = "`_total_protests' & `t2'"

	* Total Participants
	cap drop _total_partic
	egen _total_partic = total(popnum)
	sum _total_partic
	local t3 = trim("`: display %10.0fc r(mean)'")
	local _total_partic = "`_total_partic' & \small{`t3'}"

}





*** Table ****

* set up
texdoc i "Output/mechanisms_agency", replace
tex \begin{tabular}{l*{9}{P{1.6cm}}}
tex \toprule[.05cm]
tex `firstrow' \\
tex \midrule

* Average Effect
tex Impact of protest (\%\$\Delta\$) `b_ave' \\
tex  `se_ave'\\\\

* Homicide Statistics
tex Average outcome pre-protest (\footnotesize{$\widebar{\sfrac{Y}{N}}_{-1}$}) `Mean' \\
tex Agencies with protests `treated' \\
tex Agencies without protests `donor' \\
tex Total number of protests `_total_protests' \\
tex Total number of protesters `_total_partic' \\\\

* Sample size and specification
tex Sample size `N' \\
tex Outcome `Outcome' \\
tex Years `Years' \\
tex Time unit `Time' \\
/*tex
\bottomrule[.03cm]
\end{tabular}
tex*/
texdoc close

* Exit stata
exit, clear STATA