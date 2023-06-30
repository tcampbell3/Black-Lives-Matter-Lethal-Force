clear all
* Loop over number of regression column specifications
forvalues c = 1/6{
	
	* col number
	use DTA/Stacked, clear
	bys event fips (time): g cumulative = sum(protests)
	gegen sum_cumulative = sum(cumulative)
	local firstrow = "`firstrow' & \multicolumn{1}{c}{(`c')}"
	cap drop dummy_outcome
	if `c' == 1 {
		global absorb = "event#time event#fips event#pop_c##c.popest"
		global weight = "[aw=_wt_unit]"
		local place = "\checkmark"
		local time = "\checkmark"
		local pop = "\checkmark"
		local sdid = "\checkmark"
		local ipw = ""
		local consent = ""
		local acs = ""
		local crime = ""
		local time_pop = ""
		local lin_time = ""
	}
	if `c' == 2 {
		global absorb = "event#time event#fips event#pop_c##c.popest"
		global weight = "[aw=ipw]"
		local place = "\checkmark"
		local time = "\checkmark"
		local pop = "\checkmark"
		local sdid = ""
		local ipw = "\checkmark"
		local consent = ""
		local acs = ""
		local crime = ""
		local time_pop = ""
		local lin_time = ""
	}
	if `c' == 3 {
		global absorb = "event#time event#fips"
		global weight = ""
		local place = "\checkmark"
		local time = "\checkmark"
		local pop = ""
		local sdid = ""
		local ipw = ""
		local time_pop = ""
		local lin_time = ""
		local consent = ""
		local acs = ""
		local crime = ""
	}
	if `c' == 4 {
		global absorb = "event#time event#fips##c.time event#pop_c##c.popest"
		global weight = ""
		local place = "\checkmark"
		local time = "\checkmark"
		local pop = "\checkmark"
		local sdid = ""
		local ipw = ""
		local consent = ""
		local acs = ""
		local crime = ""
		local time_pop = ""
		local lin_time = "\checkmark"
	}
	if `c' == 5 {
		global absorb = "event#time#pop_c event#fips##c.time event#pop_c##c.popest"
		global weight = ""
		local place = "\checkmark"
		local time = "\checkmark"
		local pop = "\checkmark"
		local sdid = ""
		local ipw = ""
		local consent = ""
		local acs = ""
		local crime = ""
		local time_pop = "\checkmark"
		local lin_time = "\checkmark"
	}
	if `c' == 6 {
		global absorb = "event#time#pop_c event#fips##c.time event#pop_c##c.popest event#c.(consent* acs_* crime_*)"
		global weight = ""
		local place = "\checkmark"
		local time = "\checkmark"
		local pop = "\checkmark"
		local sdid = ""
		local ipw = ""
		local consent = "\checkmark"
		local acs = "\checkmark"
		local crime = "\checkmark"
		local time_pop = "\checkmark"
		local lin_time = "\checkmark"
	}
		
	* Estimate
	reghdfe homicides cumulative ${weight}, cluster(fips) a(${absorb})
	eststo
	
	* Pretreatment mean
	sum homicides if time<0 & time>=-4 & treated==1, meanonly
	local b=r(mean)
	local pre: di %10.2gc round(r(mean),.01)	
	estadd local pre = "`pre'"
		
	* Store regression results
	lincom cumulative/`b'*100
	local beta: di %10.2fc round(r(estimate),.01)	
	local beta = trim("`beta'")
	local se: di %10.2fc round(r(se),.01)	
	local se = trim("`se'")
	estadd local overall_beta = "`beta'"
	estadd local overall_se = "(`se')"
	
	* Exposed time-units
	sum sum_cumulative, meanonly
	local e = r(mean)
	estadd local total_exposed = "`e'"
	
	* Total Prevented
	lincom cumulative*`e'
	local beta: di %10.0fc abs(round(r(estimate)))	
	local beta = trim("`beta'")
	local se: di %10.1fc round(r(se),.1)	
	local se = trim("`se'")
	estadd local prevented_beta = "`beta'"
	estadd local prevented_se = "(`se')"
	
	* Treated, control, cohorts
	cap drop _samp
	bys treated: gegen _samp=nunique(fips)
	sum _samp if inlist(treated,1),meanonly
	local treated: di %10.3gc round(r(mean),.001)	
	estadd local tr = "`treated'"
	sum _samp if inlist(treated,0),meanonly
	local control: di %10.3gc round(r(mean),.001)	
	estadd local co = "`control'"
	sum event, meanonly
	local cohorts: di %10.3gc round(r(max),.001)	
	estadd local coh = "`cohorts'"
	
	* Sample Size
	local N: di %10.3gc round(e(N),.001)	
	estadd local obs = "`N'"	
	
	* Total Homicides
	gegen total_post_treated = sum(homicides) if inlist(treated,1) & time>=0
	sum total_post_treated, meanonly
	local deaths: di %10.0fc round(r(mean))	
	estadd local deaths = "`deaths'"	

	* Total Protests
	gegen _total_protests = sum(protests) 
	sum _total_protests, meanonly
	local protests: di %10.0fc round(r(mean))	
	estadd local protests = "`protests'"	

	* Total Participants
	gegen _total_partic = total(participants)
	sum _total_partic, meanonly
	local participants: di %10.0fc round(r(mean))	
	estadd local participants = "`participants'"	
	
	* Specification
	estadd local place = "`place'"
	estadd local time = "`time'"
	estadd local pop = "`pop'"		
	estadd local sdid = "`sdid'"
	estadd local ipw = "`ipw'"
	estadd local consent = "`consent'"
	estadd local acs = "`acs'"
	estadd local crime = "`crime'"
	estadd local time_pop = "`time_pop'"
	estadd local lin_time = "`lin_time'"
}

* Save Table
esttab est* using Output/cumulative.tex, 										///
	stats(overall_beta overall_se prevented_beta prevented_se pre 				///
		total_exposed deaths protests participants tr co coh obs place time pop	///
		sdid ipw lin_time time_pop consent acs crime,							///
		fmt( %010.0gc )															///
		label(																	///
		"\midrule\addlinespace[0.3cm]\$\%\Delta\text{Lethal Force}\$" 			///
			" " 																///
		"\addlinespace[0.3cm]\$\Delta\text{Total Lethal Force}\$" 				///
			" " 																///
		"\addlinespace[0.1cm] \midrule Average lethal force pre-protest"		/// 
		"\addlinespace[0.1cm]Total cumulative protests"							/// 		
		"\addlinespace[0.1cm]Total lethal force post-protest"					/// 
		"\addlinespace[0.1cm]Total number of protests"							///
		"\addlinespace[0.1cm]Total number of protesters"						///
		"\addlinespace[0.1cm]Treated cities with early protests"				/// 		
		"\addlinespace[0.1cm]Control cities with later protests"				/// 
		"\addlinespace[0.1cm]Number of cohorts"									///
		"\addlinespace[0.1cm]Sample size"										///
		"\addlinespace[0.1cm] \midrule Cohort-census place fixed effecs"		///
		"\addlinespace[0.1cm]Cohort-event time fixed effects"					///
		"\addlinespace[0.1cm]Flexible population control"						///
		"\addlinespace[0.1cm]Synthetic unit weights"							///
		"\addlinespace[0.1cm]Inverse probability weights"						///
		"\addlinespace[0.1cm]Cohort-place linear time trend"					///
		"\addlinespace[0.1cm]Cohort-time-population quintile fixed effects"		///
		"\addlinespace[0.1cm]Consent decress controls"							///
		"\addlinespace[0.1cm]Demographic and labor market controls"				///
		"\addlinespace[0.1cm]Crime controls"									///
		)																		///
	)																			///
	keep( ) replace nomtitles nonotes booktabs nogap nolines			 		///	
	prehead(\begin{tabular}{l*{20}{x{1.5cm}}} \toprule) 						///
	posthead()  																///
	postfoot(\bottomrule \end{tabular}) 

* Exit stata
exit, clear STATA