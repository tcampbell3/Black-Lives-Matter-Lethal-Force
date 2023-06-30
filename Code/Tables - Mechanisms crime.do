clear all
* Loop over number of columns
forvalues c = 1/7{
	
	* Specification
	use "DTA/Agency_panel_crime", clear
	if `c' == 1{
		local outcome = "crime_murder_rpt"
		local Outcome = "Total murders"		
	}
	if `c' == 2 {
		local outcome = "crime_violent_rpt"
		local Outcome = "Total violent crimes"	
	}
	if `c' == 3 {
		local outcome = "crime_violent_clr"
		local Outcome = "Cleared violent crimes"
	}
	if `c' == 4 {
		local outcome = "crime_property_rpt"
		local Outcome = "Total property crimes"
	}
	if `c' == 5{
		local outcome = "crime_property_clr"
		local Outcome = "Cleared property crimes"
	}
	if `c' == 6{
		local outcome = "crime_share"
		local Outcome = "Share of property crimes cleared"
	}
	if `c' == 7 {
		local outcome = "crime_officer_assaulted"
		local Outcome = "Officer assaults"
	}	

	* Pretreatment mean
	sum `outcome' if inlist(time,-1) & treated==1, meanonly
	local b=r(mean)	
	
	* Estimate without population controls
	reghdfe `outcome' treatment [aw=_unit_`outcome'], cluster(unit) a(event#unit event#time)
	eststo est`c'
	
	* Store regression results
	lincom treatment/`b'*100
	local beta: di %10.2fc round(r(estimate),.01)	
	local beta = trim("`beta'")
	local se: di %10.2fc round(r(se),.01)	
	local se = trim("`se'")
	
	* Exposed time-units
	cap drop _dummy
	gegen _dummy = group(time unit) if inlist(treatment,1)
	sum _dummy, meanonly
	local e: di %10.3gc round(r(max),.001)	
	local e = r(max)
	
	* Total Prevented
	if "`outcome'"!="crime_share"{
		lincom treatment*`e'
		local beta2: di %10.0fc round(r(estimate))	
		local beta2 = trim("`beta2'")
		local se2: di %10.1gc round(r(se),.1)	
		local se2 = trim("`se2'")
	}
	
	* Add estimates to ereturn
	estadd local total_exposed = "`e'"	
	estadd local overall_beta1 = "`beta'"
	estadd local overall_se1 = "(`se')"	
	if "`outcome'"!="crime_share"{
		estadd local prevented_beta1 = "`beta2'"
		estadd local prevented_se1 = "(`se2')"
	}
	
	* Estimate with population controls
	reghdfe `outcome' treatment [aw=_unit_`outcome'], cluster(unit) a(event#unit event#time event#pop_c##c.popu)
	
	* Store regression results
	lincom treatment/`b'*100
	local beta: di %10.2fc round(r(estimate),.01)	
	local beta = trim("`beta'")
	local se: di %10.2fc round(r(se),.01)	
	local se = trim("`se'")
	
	* Exposed time-units
	cap drop _dummy
	gegen _dummy = group(time unit) if inlist(treatment,1)
	sum _dummy, meanonly
	local e: di %10.3gc round(r(max),.001)	
	local e = r(max)
	
	* Total Prevented
	if "`outcome'"!="crime_share"{
		lincom treatment*`e'
		local beta2: di %10.0fc round(r(estimate))	
		local beta2 = trim("`beta2'")
		local se2: di %10.1gc round(r(se),.1)	
		local se2 = trim("`se2'")
	}
	
	* Add estimates to ereturn
	est restore est`c'
	estadd local overall_beta2 = "`beta'"
	estadd local overall_se2 = "(`se')"	
	if "`outcome'"!="crime_share"{
		estadd local prevented_beta2 = "`beta2'"
		estadd local prevented_se2 = "(`se2')"
	}	
	
	* Pretreatment mean
	local pre: di %10.2gc round(`b',.01)	
	estadd local pre = "`pre'"
	
	* Treated, control, cohorts
	cap drop _samp
	bys treated: gegen _samp=nunique(unit)
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
	
	* Total crimes
	gegen total_post_treated = sum(`outcome') if inlist(treatment,1)
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
	
	* Other info
	estadd local coltitle = "`Outcome'"
	estadd local Time = "Annual"
	estadd local Years = "2000-2019"
	estadd local blank = ""
}

* Save Table
esttab est* using Output/mechanisms_crime.tex, 									///
	stats(coltitle blank overall_beta1 overall_se1 prevented_beta1 prevented_se1	///
		blank overall_beta2 overall_se2 prevented_beta2 prevented_se2 pre 		///
		total_exposed deaths protests participants tr co coh obs Years Time,	///
		fmt( %010.0gc )															///
		label(																	///
		"\midrule \textbf{Outcome:} "											///
		"\midrule\addlinespace[0.3cm]\textit{No population control:}"			///
		"\addlinespace[0.1cm]\$\%\Delta\text{Crimes}\$" 						///
			" " 																///
		"\addlinespace[0.1cm]\$\Delta\text{Total Crimes}\$" 					///
			" " 																///
		"\addlinespace[0.3cm]\textit{Flexible population control:}"				///
		"\addlinespace[0.1cm]\$\%\Delta\text{Crimes}\$" 						///
			" " 																///
		"\addlinespace[0.1cm]\$\Delta\text{Total Crimes}\$" 					///
			" " 																///
		"\addlinespace[0.1cm] \midrule Average outcome pre-protest"				/// 
		"\addlinespace[0.1cm]Total place-years after protest"					/// 		
		"\addlinespace[0.1cm]Total crimes post-protest"							/// 
		"\addlinespace[0.1cm]Total number of protests"							///
		"\addlinespace[0.1cm]Total number of protesters"						///
		"\addlinespace[0.1cm]Treated agencies with early protests"				/// 		
		"\addlinespace[0.1cm]Control agencies with later protests"				/// 
		"\addlinespace[0.1cm]Number of cohorts"									///
		"\addlinespace[0.1cm]Sample size"										///
		"\addlinespace[0.1cm]Years"												///
		"\addlinespace[0.1cm]Time unit"											///
		)																		///
	)																			///
	keep( ) replace nomtitles nonotes booktabs nogap nolines			 		///	
	prehead(\begin{tabular}{l*{20}{x{1.9cm}}} \toprule) 						///
	posthead()  																///
	postfoot(\bottomrule \end{tabular}) 

* Exit stata
exit, clear STATA