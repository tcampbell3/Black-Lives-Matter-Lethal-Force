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

global absorb = "i.event#i.time i.event#i.FIPS event#pop_c##c.popestimate"

* generate open variables
use DTA/Stacked, clear

* Loop over number of regression column specifications
forvalues c = 1/5{
	
	* col number
	local firstrow = "`firstrow' & \multicolumn{1}{c}{(`c')}"
	cap drop dummy_outcome
	if `c' == 1 {
		
		* Outcome
		g dummy_outcome = homicides
		local benchmark = "`benchmark'& \footnotesize{None}"
		local Bench = "`Bench' & 1 "	
		local a=1
		
	}
	
	if `c' == 2 {
	
		* Outcome
		g dummy_outcome = homicides/popestimate
		local benchmark = "`benchmark'& \footnotesize{Population}"
		sum popestimate if time<0 & time>=-4 & treated==1
		local a=r(mean)
		_round , number(`a')
		local bench = r(rounded)
		local Bench = "`Bench' & `bench'"
		
	}
	
	if `c' == 3 {
	
		* Outcome
		g dummy_outcome = homicides/ag_officers
		local benchmark = "`benchmark'& \footnotesize{Officers}"
		sum ag_officers if time<0 & time>=-4 & treated==1
		local a=r(mean)
		_round , number(`a')
		local bench = r(rounded)
		local Bench = "`Bench' & `bench'"
		
	}
	if `c' == 4 {
	
		* Outcome
		g dummy_outcome = homicides/crime_violent_clr 
		local benchmark = "`benchmark'& \footnotesize{Violent Arrests}"
		sum crime_violent_clr if time<0 & time>=-4 & treated==1
		local a=r(mean)
		_round , number(`a')
		local bench = r(rounded)
		local Bench = "`Bench' & `bench'"
		
	}
	if `c' == 5 {
	
		* Outcome
		g _arrests = crime_violent_clr + crime_property_clr
		g dummy_outcome = homicides/(_arrests)
		local benchmark = "`benchmark'& \footnotesize{Total Arrests}"
		sum _arrests if time<0 & time>=-4 & treated==1
		local a=r(mean)
		_round , number(`a')
		local bench = r(rounded)
		local Bench = "`Bench' & `bench'"
		
	}

	* Find pretreatment mean
	sum dummy_outcome `weight' if time<0 & time>=-4 & treated==1
	local b=r(mean)
	_round , number(`b')
	local rounded = r(rounded)
	local Mean = "`Mean' & `rounded' "

	* Estimates	
	reghdfe dummy_outcome t_*  `weight' , cluster(FIPS) abs(${absorb})
	
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
		local post_ave = r(estimate)
		local est_overall = trim("`: display %10.3f r(estimate)'")
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
	
	* Treated / Total Prevented
	unique fips if treated==1	
	local t = trim("`: display %10.0fc r(unique)'")
	local treated = "`treated' & `t'"
	
	* Total Prevented
	local p = trim("`: display %10.0fc -`post_ave'*`b'*`e'*`a''")
	local prevented = "`prevented' & `p'"

	* Total Prevented SE
	local dummy = `est_se'*`b'*`e'*`a'
	_round , number(`dummy')
	local rounded = r(rounded)
	local prevented_se =" `prevented_se' & (`rounded')"

	* Donor
	unique fips if donor==1	
	local d = trim("`: display %10.0fc r(unique)'")
	local donor = "`donor' & `d'"
	
	* Cohort
	unique event if donor==1	
	local c = trim("`: display %10.0fc r(unique)'")
	local cohort = "`cohort' & `c'"
	
	* Total Homicides
	cap drop total_post_treated
	egen total_post_treated = total(homicides) if treated == 1 & time>=0
	sum total_post_treated
	local t = trim("`: display %10.0fc r(mean)'")
	local total_post_treated = "`total_post_treated' & `t'"
	
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
texdoc i "Output/normalization", replace
tex \begin{tabular}{l*{11}{P{1.6cm}}}
tex \toprule[.05cm]
tex `firstrow' \\
tex \midrule

* Average Effect
tex \$\%\Delta\text{Lethal Force}\$  `b_ave' \\
tex  `se_ave'\\\\

* Total lethal force prevented
tex \$\Delta\text{Total Lethal Force}\$  `prevented' \\
tex  `prevented_se'\\\\

* Homicide Statistics
tex Average outcome pre-protest (\footnotesize{$\widebar{\sfrac{Y}{N}}_{-1}$}) `Mean' \\
tex Average normalization pre-protest (\footnotesize{$\widebar{N}_{-1}$}) `Bench' \\
tex Total place-quarters after protest (\footnotesize\$e$) `Total_exposed' \\
tex Total lethal force post-protest `total_post_treated' \\\\

* Protest staistics
tex Places with protests `treated' \\
tex Places without protests `donor' \\
tex Total number of protests `_total_protests' \\
tex Total number of protesters `_total_partic' \\\\

* Sample size and specification
tex Benchmark `benchmark' \\
tex Sample size `N' \\

/*tex
\bottomrule[.03cm]
\end{tabular}
tex*/
texdoc close


* Exit stata
exit, clear STATA