* Round
cap program drop _round
program _round, rclass
	syntax [, number(real 50)]
	return clear
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


* Loop over number of regression column specifications
forvalues c = 1/10{
	
	* col number
	local firstrow = "`firstrow' & \multicolumn{1}{c}{(`c')}"
	cap drop dummy_outcome
	if `c' == 1 {
		
		use DTA/Stacked, clear
		global absorb = "i.event#i.time i.event#i.FIPS"
		global weight = ""
		local place = "`place' & \checkmark"
		local time = "`time' & \checkmark"
		local time_pop = "`time_pop' & "
		local lin_time = "`lin_time' & "
		local pop = "`pop' & "
		local consent = "`consent' & "
		local acs = "`acs' & "
		local crime = "`crime' & "
		local ipw = "`ipw' & "
		local ipw_unit = "`ipw_unit' & "
		local ipw_unit_time = "`ipw_unit_time' & "

	}
	
	if `c' == 2 {
	
		use DTA/Stacked, clear
		global absorb = "i.event#i.time#i.pop_c i.event#i.FIPS"
		global weight = ""
		local place = "`place' & \checkmark"
		local time = "`time' & \checkmark"
		local time_pop = "`time_pop' & \checkmark"
		local lin_time = "`lin_time' & "
		local pop = "`pop' & "
		local consent = "`consent' & "
		local acs = "`acs' & "
		local crime = "`crime' & "
		local ipw = "`ipw' & "
		local ipw_unit = "`ipw_unit' & "
		local ipw_unit_time = "`ipw_unit_time' & "
		
	}
	
	if `c' == 3 {
	
		use DTA/Stacked, clear
		global absorb = "i.event#i.time i.event#i.FIPS i.event#i.FIPS#c.time"
		global weight = ""
		local place = "`place' & \checkmark"
		local time = "`time' & \checkmark"
		local time_pop = "`time_pop' & "
		local lin_time = "`lin_time' & \checkmark"
		local pop = "`pop' & "
		local consent = "`consent' & "
		local acs = "`acs' & "
		local crime = "`crime' & "
		local ipw = "`ipw' & "
		local ipw_unit = "`ipw_unit' & "
		local ipw_unit_time = "`ipw_unit_time' & "
		
	}
	if `c' == 4 {
	
		use DTA/Stacked, clear
		global absorb = "i.event#i.time i.event#i.FIPS i.event#i.pop_c i.event#i.pop_c#c.popestimate"
		global weight = ""	
		local place = "`place' & \checkmark"
		local time = "`time' & \checkmark"
		local time_pop = "`time_pop' & "
		local lin_time = "`lin_time' & "
		local pop = "`pop' & \checkmark"
		local consent = "`consent' & "
		local acs = "`acs' & "
		local crime = "`crime' & "
		local ipw = "`ipw' & "
		local ipw_unit = "`ipw_unit' & "
		local ipw_unit_time = "`ipw_unit_time' & "

	}
	if `c' == 5 {
	
		use DTA/Stacked, clear
		global absorb = "i.event#i.time i.event#i.FIPS i.event#i.pop_c i.event#i.pop_c#c.popestimate  i.event#c.(consent*)"
		global weight = ""	
		local place = "`place' & \checkmark"
		local time = "`time' & \checkmark"
		local time_pop = "`time_pop' & "
		local lin_time = "`lin_time' & "
		local pop = "`pop' & \checkmark"
		local consent = "`consent' & \checkmark"
		local acs = "`acs' & "
		local crime = "`crime' & "
		local ipw = "`ipw' & "
		local ipw_unit = "`ipw_unit' & "
		local ipw_unit_time = "`ipw_unit_time' & "
		
	}
	if `c' == 6 {
	
		use DTA/Stacked, clear
		global absorb = "i.event#i.time i.event#i.FIPS i.event#i.pop_c i.event#i.pop_c#c.popestimate  i.event#c.(consent*) i.event#c.(acs_*)"
		global weight = ""	
		local place = "`place' & \checkmark"
		local time = "`time' & \checkmark"
		local time_pop = "`time_pop' & "
		local lin_time = "`lin_time' & "
		local pop = "`pop' & \checkmark"
		local consent = "`consent' & \checkmark"
		local acs = "`acs' & \checkmark"
		local crime = "`crime' & "
		local ipw = "`ipw' & "
		local ipw_unit = "`ipw_unit' & "
		local ipw_unit_time = "`ipw_unit_time' & "
		
	}
	if `c' == 7 {
	
		use DTA/Stacked, clear
		global absorb = "i.event#i.time i.event#i.FIPS i.event#i.pop_c i.event#i.pop_c#c.popestimate  i.event#c.(consent*) i.event#c.(acs_*) i.event#c.(crime_*)"
		global weight = ""	
		local place = "`place' & \checkmark"
		local time = "`time' & \checkmark"
		local time_pop = "`time_pop' & "
		local lin_time = "`lin_time' & "
		local pop = "`pop' & \checkmark"
		local consent = "`consent' & \checkmark"
		local acs = "`acs' & \checkmark"
		local crime = "`crime' & \checkmark"
		local ipw = "`ipw' & "
		local ipw_unit = "`ipw_unit' & "
		local ipw_unit_time = "`ipw_unit_time' & "
	
	}
	if `c' == 8 {
	
		use DTA/Stacked, clear
		global absorb = "i.event#i.time i.event#i.FIPS i.event#i.pop_c i.event#i.pop_c#c.popestimate  i.event#c.(consent*) i.event#c.(acs_*) i.event#c.(crime_*)"
		global weight = "[aw=ipw]"	
		local place = "`place' & \checkmark"
		local time = "`time' & \checkmark"
		local time_pop = "`time_pop' & "
		local lin_time = "`lin_time' & "
		local pop = "`pop' & \checkmark"
		local consent = "`consent' & \checkmark"
		local acs = "`acs' & \checkmark"
		local crime = "`crime' & \checkmark"
		local ipw = "`ipw' & \checkmark"
		local ipw_unit = "`ipw_unit' & "
		local ipw_unit_time = "`ipw_unit_time' & "		

	}
	if `c' == 9 {
	
		use DTA/Stacked, clear
		global absorb = "i.event#i.time i.event#i.FIPS i.event#i.pop_c i.event#i.pop_c#c.popestimate  i.event#c.(consent*) i.event#c.(acs_*) i.event#c.(crime_*)"
		global weight = "[aw=ipw_unit]"	
		local place = "`place' & \checkmark"
		local time = "`time' & \checkmark"
		local time_pop = "`time_pop' & "
		local lin_time = "`lin_time' & "
		local pop = "`pop' & \checkmark"
		local consent = "`consent' & \checkmark"
		local ag = "`ag' & \checkmark"
		local crime = "`crime' & \checkmark"
		local ipw = "`ipw' & "
		local ipw_unit = "`ipw_unit' & \checkmark"
		local ipw_unit_time = "`ipw_unit_time' & "
		
	}
	if `c' == 10 {
	
		use DTA/Stacked, clear
		global absorb = "i.event#i.time i.event#i.FIPS i.event#i.pop_c i.event#i.pop_c#c.popestimate  i.event#c.(consent*) i.event#c.(acs_*) i.event#c.(crime_*)"
		global weight = "[aw=ipw_unit_time]"	
		local place = "`place' & \checkmark"
		local time = "`time' & \checkmark"
		local time_pop = "`time_pop' & "
		local lin_time = "`lin_time' & "
		local pop = "`pop' & \checkmark"
		local acs = "`acs' & \checkmark"
		local crime = "`crime' & \checkmark"
		local ipw = "`ipw' & "
		local ipw_unit = "`ipw_unit' & "
		local ipw_unit_time = "`ipw_unit_time' & \checkmark"
		
	}
	
	* Find pretreatment mean
	sum homicides ${weight} if time<0 & time>=-4 & treated==1
	local b=r(mean)
	local mean = trim("`: display %10.3f r(mean)'")
	local Mean = "`Mean' & `mean' "

	* Estimates	
	reghdfe homicides t_*  ${weight} , cluster(FIPS) abs(${absorb})
	
		forvalues i = 1/9{
			di "TESTSING TREATMENT `i'"
			lincom (t_`i'-(t_1+t_2+t_3+t_4)/4)/`b'
			local est_overall = trim("`: display %10.3f r(estimate)'")
			local est_se =trim("`: display %10.3f r(se)'")
			local b`i' = " `b`i''& `est_overall'"
			local se`i' =" `se`i'' & (`est_se')"
		}
		
		di "TESTING AVERAGE TREATMENT"
		lincom ((t_5+t_6+t_7+t_8+t_9)/5 - (t_1+t_2+t_3+t_4)/4)/`b'
		local est_overall = trim("`: display %10.3f r(estimate)'")
		local post_ave = r(estimate)
		local est_se =trim("`: display %10.3f r(se)'")
		local b_ave = " `b_ave'& `est_overall'"
		local se_ave =" `se_ave' & (`est_se')"
	
	* Sample Size
	local n = trim("`: display %10.0fc e(N_full)'")
	local N = "`N' & \small{`n'} "

	* Exposed time-units
	cap drop _dummy
	gegen _dummy = group(time fips) if inlist(treatment,1)
	sum _dummy, meanonly
	local e = r(max)
	local total_exposed = trim("`: display %10.0fc `e'")
	local Total_exposed = "`Total_exposed' & `e'"
	
	* Average pretreatment 
	local a = 1
	local normalization = "`normalization' & `a'"
	
	* Total Prevented
	local p = trim("`: display %10.0fc -`post_ave'*`b'*`e'*`a''")
	local prevented = "`prevented' & `p'"

	* Total Prevented SE
	local dummy = `est_se'*`b'*`e'*`a'
	_round , number(`dummy')
	local rounded = r(rounded)
	local prevented_se =" `prevented_se' & (`rounded')"

	* Treated
	unique fips if treated==1	
	local t = trim("`: display %10.0fc r(unique)'")
	local treated = "`treated' & `t'"
	
	* Donor
	unique fips if donor==1	
	local d = trim("`: display %10.0fc r(unique)'")
	local donor = "`donor' & `d'"
	
	* Cohort
	unique event if donor==1	
	local c = trim("`: display %10.0fc r(unique)'")
	local cohort = "`cohort' & `c'"
	
	* Total Homicides
	egen total_post_treated = total(homicides) if treated == 1 & time>=0
	sum total_post_treated
	local t = trim("`: display %10.0fc r(mean)'")
	local total_post_treated = "`total_post_treated' & `t'"

	* Total Protests
	egen _total_protests = total(protests) 
	sum _total_protests
	local t2 = trim("`: display %10.0fc r(mean)'")
	local _total_protests = "`_total_protests' & `t2'"

	* Total Participants
	egen _total_partic = total(popnum)
	sum _total_partic
	local t3 = trim("`: display %10.0fc r(mean)'")
	local _total_partic = "`_total_partic' & \small{`t3'}"

}





*** Table ****

* set up
texdoc i "Output/specification", replace
tex \begin{tabular}{l*{20}{P{1.6cm}}}
tex \toprule[.05cm]
tex `firstrow' \\
tex \midrule

* Average Effect
tex \$\%\Delta\text{Lethal Force}\$ `b_ave' \\
tex  `se_ave'\\\\

* Total lethal force prevented
tex \$\Delta\text{Total Lethal Force}\$  `prevented' \\
tex  `prevented_se'\\\\

* Homicide Statistics
tex Average outcome pre-protest (\footnotesize{$\widebar{\sfrac{Y}{N}}_{-1}$}) `Mean' \\
tex Average normalization pre-protest (\footnotesize{$\widebar{N}_{-1}$}) `normalization' \\
tex Total place-quarters after protest (\footnotesize\$e$) `Total_exposed' \\
tex Total lethal force post-protest `total_post_treated' \\\\

* Protest Statistics
tex Places with protests `treated' \\
tex Places without protests `donor' \\
tex Total number of protests `_total_protests' \\
tex Total number of protesters `_total_partic' \\\\

* Sample size and specification
tex Number of cohorts `cohort' \\
tex Sample size `N' \\
tex Cohort-place fixed effects `place' \\
tex Cohort-time fixed effects `time' \\
tex Cohort-time-population quintile fixed effects `time_pop' \\
tex Cohort-place linear time trend `lin_time' \\
tex Population controls `pop' \\
tex Consent decree controls `consent' \\
tex Demographic and labor market controls `acs' \\
tex Crime controls `crime' \\
tex Pre-treatment control inverse probability weights `ipw' \\
tex Event-place inverse probability weights `ipw_unit' \\
tex Event-place and event-quarter inverse probability weights  `ipw_unit_time' \\

/*tex
\bottomrule[.03cm]
\end{tabular}
tex*/
texdoc close

* Exit stata
exit, clear STATA