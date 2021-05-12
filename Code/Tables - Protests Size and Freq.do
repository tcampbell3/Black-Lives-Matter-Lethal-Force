global outcome = "homicides"

* generate open variables
use DTA/Stacked, clear

*Define Quartile Cutoffs of interest
bys event fips: egen p_size_max = max(popnum)

* Define slive
local slice = "p_size_max total_protests"

* Create Quartile Cutoffs (40 100 300)
foreach var in `slice' { // total_protests
	fastxtile `var'_q = `var' if treated == 1, n(4)
	local `var'1=r(r1)
	local `var'2=r(r2)
	local `var'3=r(r3)
}

* Save tempfile
tempfile temp
save `temp', replace


* Loop over number of regression column specifications
forvalues c = 1/5{
	
	* col number
	local firstrow = "`firstrow' & (`c')"
	
	* specification
	if `c' == 1 {
		global absorb = "i.event#i.time i.event#i.FIPS"
		local place_fe = "`place_fe' & \checkmark"
		local time_fe = "`time_fe'& \checkmark"
		local pop = "`pop'&"
		local consent = "`consent'& "
		local lin = "`lin'& "
		local pop_time = "`pop_time'& "
	}
	if `c' == 2 {
		global absorb = "i.event#i.time i.event#i.FIPS i.event#i.pop_c i.event#i.pop_c#c.popestimate"
		local place_fe = "`place_fe' & \checkmark"
		local time_fe = "`time_fe'& \checkmark"
		local pop = "`pop'& \checkmark"
		local consent = "`consent'& "
		local lin = "`lin'& "
		local pop_time = "`pop_time'& "
	}
	if `c' == 3 {
		global absorb = "i.event#i.time i.event#i.FIPS i.event#i.pop_c i.event#i.pop_c#c.popestimate i.FIPS#c.consent_decree1 i.FIPS#c.consent_decree2 i.FIPS#c.consent_decree3"
		local place_fe = "`place_fe' & \checkmark"
		local time_fe = "`time_fe'& \checkmark"
		local pop = "`pop'& \checkmark"
		local consent = "`consent'& \checkmark"
		local lin = "`lin'& "
		local pop_time = "`pop_time'& "
	}
	if `c' == 4 {
		global absorb = "i.event#i.time i.event#i.FIPS i.event#i.pop_c i.event#i.pop_c#c.popestimate i.FIPS#c.consent_decree1 i.FIPS#c.consent_decree2 i.FIPS#c.consent_decree3 i.event#i.FIPS#c.time"
		local place_fe = "`place_fe' & \checkmark"
		local time_fe = "`time_fe'& \checkmark"
		local pop = "`pop'& \checkmark"
		local consent = "`consent'& \checkmark"
		local lin = "`lin'& \checkmark"
		local pop_time = "`pop_time'& "
	}
	if `c' == 5 {
		global absorb = "i.event#i.time#i.pop_c i.event#i.FIPS i.event#i.FIPS#c.time i.event#i.pop_c#c.popestimate i.FIPS#c.consent_decree1 i.FIPS#c.consent_decree2 i.FIPS#c.consent_decree3 "
		local place_fe = "`place_fe' & \checkmark"
		local time_fe = "`time_fe'& \checkmark"
		local pop = "`pop'& \checkmark"
		local consent = "`consent'& \checkmark"
		local lin = "`lin'& \checkmark"
		local pop_time = "`pop_time'& \checkmark"
	}

	* Estimates
	foreach var in `slice' { // total_protests
		forvalues q = 1/4{
			
			* Slice treated data
			use `temp',clear
			keep if `var'_q == `q' | treated == 0
			
			* drop events without treatment
			bys event: egen test = max(treated)
			drop if test==0
			drop test	

			* Find pretreatment mean
				quietly sum $outcome `weight' if time<0 & time>=-4 & treated==1, meanonly
				local b=r(mean)

			* Estimates	
			reghdfe $outcome t_*  `weight' , cluster(FIPS) abs(${absorb})
				di "TESTING AVERAGE TREATMENT"
				lincom ((t_5+t_6+t_7+t_8+t_9)/5 - (t_1+t_2+t_3+t_4)/4)/`b'
				local est_overall = trim("`: display %10.3f r(estimate)'")
				local est_se =trim("`: display %10.3f r(se)'")
				local b_`var'_`q' = " `b_`var'_`q''& `est_overall'"
				local se_`var'_`q' =" `se_`var'_`q'' & (`est_se')"

		} 
	}
		
}





*** Table ****

* set up
texdoc i "Output/protest_size_freq", replace
tex \begin{tabular}{l c c c c c c c c c c c c c c c}
tex \toprule[.05cm]
tex `firstrow' \\
tex \midrule

* Protest Max Size
tex Maximum protest size&  \vspace{.1cm}\\
tex \quad Quartile 1 ($\leq$ `p_size_max1') `b_p_size_max_1' \\
tex  `se_p_size_max_1'\\
tex \quad Quartile 2 ($\leq$ `p_size_max2', $>$ `p_size_max1') `b_p_size_max_2' \\
tex  `se_p_size_max_2' \\
tex \quad Quartile 3 ($\leq$ `p_size_max3', $>$ `p_size_max2') `b_p_size_max_3' \\
tex  `se_p_size_max_3' \\
tex \quad Quartile 4 ($>$ `p_size_max3') `b_p_size_max_4'  \\
tex  `se_p_size_max_4' \\\\

* Protest Max Size
tex Total number of protests&  \vspace{.1cm}\\
tex \quad Quartile 1 ($\leq$ `total_protests1') `b_total_protests_1' \\
tex  `se_total_protests_1'\\
tex \quad Quartile 2 ($\leq$ `total_protests2', $>$ `total_protests1') `b_total_protests_2' \\
tex  `se_total_protests_2' \\
tex \quad Quartile 3 ($\leq$ `total_protests3', $>$ `total_protests2') `b_total_protests_3' \\
tex  `se_total_protests_3' \\
tex \quad Quartile 4 ($>$ `total_protests3') `b_total_protests_4' \\
tex  `se_total_protests_4' \\\\

tex Cohort-place fixed effects `place_fe' \\
tex Cohort-time fixed effects `time_fe' \\
tex Population controls `pop' \\
tex Consent decree controls `consent' \\
tex Cohort-place linear time trend `lin' \\
tex Cohort-time-population fixed effects `pop_time' \\

/*tex
\bottomrule[.03cm]
\end{tabular}
tex*/
texdoc close

* Exit stata
exit, clear STATA