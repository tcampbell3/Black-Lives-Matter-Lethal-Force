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

* Open Data
use DTA/stacked, clear

* keep only when MPV has data
drop if qtr<20131

* Drop pretreatment data to balance stacks
drop if time<-6

* Pretreament year 1
g pre1 = inlist(time,-1,-2,-3,-4)&inlist(treated,1)
	
* Loop over number of columns
forvalues c = 1/8{
	
	* col number
	local firstrow = "`firstrow' & (`c')"
	
	* specification
	if `c' == 1 {
	
		cap drop outcome
		g outcome = homicides_mpv
		local weight = ""
		local weight_row = "`weight_row' & None"
		local group_row = "`group_row'& Total"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#FIPS  event#pop_c##c.popestimate"
		local k = "homicides_mpv"
	
		* Save pretreatment benchmark
		local Bench = "`Bench' & 1 "	
		local a=1
	
	}
	if `c' == 2 {
		
		cap drop outcome
		g outcome = homicides_mpv/popestimate
		local weight = "[aw=popestimate]"
		local weight_row = "`weight_row' & \footnotesize{Population}"
		local group_row = "`group_row'& Total"
		local benchmark_row = "`benchmark_row'& \footnotesize{Population}"
		local absorb = "event#time event#FIPS  event#pop_c##c.popestimate"
		local k = "homicides_mpv"
		
		* Save pretreatment benchmark
		sum popestimate if pre1 == 1
		local bench = trim("`: display %10.0f r(mean)'")
		local Bench = "`Bench' & `bench' "	
		local a=r(mean)
		
	}
	if `c' == 3 {
		
		cap drop outcome
		g outcome = homicides_white_mpv
		local weight = ""
		local weight_row = "`weight_row' & None"
		local group_row = "`group_row'& White"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#FIPS  event#acs_white_total_c##c.acs_white_total"
		local k = "homicides_white_mpv"

		* Save pretreatment benchmark
		local Bench = "`Bench' & 1 "	
		local a=1
	
	}
	if `c' == 4 {
		
		cap drop outcome
		g outcome = homicides_black_mpv/acs_white_total
		local weight = "[aw=acs_white_total]"
		local weight_row = "`weight_row' & White"
		local group_row = "`group_row'& White"
		local benchmark_row = "`benchmark_row'& White"
		local absorb = "event#time event#FIPS  event#acs_white_total_c##c.acs_white_total"
		local k = "homicides_white_mpv"
	
		* Save pretreatment benchmark
		sum acs_white_total if pre1 == 1
		local bench = trim("`: display %10.0f r(mean)'")
		local Bench = "`Bench' & `bench' "	
		local a=r(mean)
		
	}
	if `c' == 5 {
		
		cap drop outcome
		g outcome = homicides_black_mpv
		local weight = ""
		local weight_row = "`weight_row' & None"
		local group_row = "`group_row'& Black"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#FIPS  event#acs_black_total_c##c.acs_black_total"
		local k = "homicides_black_mpv"
	
		* Save pretreatment benchmark
		local Bench = "`Bench' & 1 "	
		local a=1
	
	}
	if `c' == 6 {
		
		cap drop outcome
		g outcome = homicides_black_mpv/acs_black_total
		local weight = "[aw=acs_black_total]"
		local weight_row = "`weight_row' & Black"
		local group_row = "`group_row'& Black"
		local benchmark_row = "`benchmark_row'& Black"
		local absorb = "event#time event#FIPS  event#acs_black_total_c##c.acs_black_total"
		local k = "homicides_black_mpv"
		
		* Save pretreatment benchmark
		sum acs_black_total if pre1 == 1
		local bench = trim("`: display %10.0f r(mean)'")
		local Bench = "`Bench' & `bench' "	
		local a=r(mean)
		
	}	
	if `c' == 7 {
		
		cap drop outcome
		g outcome = homicides_mpv - homicides_armed_mpv
		local weight = ""
		local weight_row = "`weight_row' & None"
		local group_row = "`group_row'& \small{Unarmed}"
		local benchmark_row = "`benchmark_row'& None"
		local absorb = "event#time event#FIPS  event#pop_c##c.popestimate"
		local k = "outcome"
		
		* Save pretreatment benchmark
		local Bench = "`Bench' & 1 "	
		local a=1
		
	}
	if `c' == 8 {
		
		cap drop outcome
		g outcome = (homicides_mpv - homicides_armed_mpv)/popestimate
		local weight = "[aw=popestimate]"
		local weight_row = "`weight_row' & \footnotesize{Population}"
		local group_row = "`group_row'& \small{Unarmed}"
		local benchmark_row = "`benchmark_row'& \footnotesize{Population}"
		local absorb = "event#time event#FIPS  event#pop_c##c.popestimate"
		g _dummy_outcome = homicides_mpv - homicides_armed_mpv
		local k = "_dummy_outcome"
		
		* Save pretreatment benchmark
		sum popestimate if pre1 == 1
		local bench = trim("`: display %10.0f r(mean)'")
		local Bench = "`Bench' & `bench' "	
		local a=r(mean)
		
	}		

	* Find pretreatment mean
	quietly sum outcome `weight' if pre1 == 1
	local b=r(mean)
	local mean = trim("`: display %10.3f r(mean)'")
	local Mean = "`Mean' & `mean' "
	
	* Estimates	
	reghdfe outcome treatment `weight' , cluster(FIPS) absorb(`absorb' )
		
		di "TESTING AVERAGE TREATMENT"
		lincom (treatment)/`b'
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

	* Total Homicides
	cap drop total_post_treated
	egen total_post_treated = total(`k') if treated == 1 & time>=0
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
texdoc i "Output/race", replace
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

* Protest Statistics
tex Places with protests `treated' \\
tex Places without protests `donor' \\
tex Total number of protests `_total_protests' \\
tex Total number of protesters `_total_partic' \\\\

* Sample size and specification
tex Sample size `N' \\
tex Police homicide subset `group_row' \\
tex Benchmark `benchmark_row' \\
tex Weight `weight_row' \\
/*tex
\bottomrule[.03cm]
\end{tabular}
tex*/
texdoc close

* Exit stata
exit, clear STATA