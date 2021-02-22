
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
forvalues c = 1/7{
	
	* col number
	local firstrow = "`firstrow' & (`c')"
	
	* specification
	if `c' == 1 {
	
		use "DTA/Agency_panel_crime", clear
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2000-2019"
		local outcome = "crime_officer_assaulted"
		local Outcome = "`Outcome' & Officer assaults"
		local weight = ""
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#unit event#pop_c##c.ucr_population"
		local Bench = "`Bench' & 1 "	
		local dataset="crime"
		
	}	
	if `c' == 2{
	
		use "DTA/Agency_panel_crime", clear
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2000-2019"
		local outcome = "crime_murder_rpt"
		local Outcome = "`Outcome' & Total murders"
		local weight = ""
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#unit event#pop_c##c.ucr_population"
		local Bench = "`Bench' & 1 "	
		local dataset="crime"
		
	}
	if `c' == 3 {
	
		use "DTA/Agency_panel_crime", clear
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2000-2019"
		local outcome = "crime_violent_rpt"
		local Outcome = "`Outcome' & Total violent crimes"
		local weight = ""
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#unit event#pop_c##c.ucr_population"
		local Bench = "`Bench' & 1 "	
		local dataset="crime"
		
	}
	if `c' == 4 {
	
		use "DTA/Agency_panel_crime", clear
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2000-2019"
		local outcome = "crime_violent_clr"
		local Outcome = "`Outcome' & Cleared violent crimes"
		local weight = ""
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#unit event#pop_c##c.ucr_population"
		local Bench = "`Bench' & 1 "	
		local dataset="crime"
		
	}
	if `c' == 5{
	
		use "DTA/Agency_panel_crime", clear
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2000-2019"
		local outcome = "crime_property_rpt"
		local Outcome = "`Outcome' & Total property crimes"
		local weight = ""
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#unit event#pop_c##c.ucr_population"
		local Bench = "`Bench' & 1 "	
		local dataset="crime"
		
	}
	if `c' == 6{
	
		use "DTA/Agency_panel_crime", clear
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2000-2019"
		local outcome = "crime_property_clr"
		local Outcome = "`Outcome' & Cleared property crimes"
		local weight = ""
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#unit event#pop_c##c.ucr_population"
		local Bench = "`Bench' & 1 "	
		local dataset="crime"
		
	}
	if `c' == 7{
	
		use "DTA/Agency_panel_crime", clear
		g crime_share = crime_property_clr/crime_property_rpt
		local Time = "`Time' & Annual"
		local Years = "`Years' & 2000-2019"
		local outcome = "crime_share"
		local Outcome = "`Outcome' & Share of property crimes cleared"
		local weight = ""
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#unit event#pop_c##c.ucr_population"
		local Bench = "`Bench' & 1 "	
		local dataset="crime"
		
	}	
	
	* Find pretreatment mean
	sum `outcome' `weight' if time<0 & time>=-4 & treated==1, meanonly
	local b=r(mean)
	_round , number(`b')
	local rounded = r(rounded)
	local Mean = "`Mean' & `rounded' "
	
	* Estimates	
	if "`dataset'"=="2year"{
		reghdfe `outcome' treatment `weight', cluster(unit) absorb(`absorb' )
		di "TESTING AVERAGE TREATMENT"
		lincom treatment/`b'
	}
	else{
		reghdfe `outcome' treatment t_1-t_4 `weight', cluster(unit) absorb(`absorb' )
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
texdoc i "Output/mechanisms_crime", replace
tex \begin{tabular}{l*{7}{P{2cm}}}
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