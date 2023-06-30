clear all
* Loop over number of columns
forvalues c = 1/9{
	
	* Specification
	if `c' == 1 {
		use "DTA/Agency_panel_bodycam", clear
		local Time = "Quarterly"
		local Years = "2000-2016"
		local outcome = "ag_bodycam"
		local Outcome = "Body cameras"
		local absorb = "event#time event#unit"
		local dataset="bodycam"
	}
	if `c' == 2 {
		use "DTA/Agency_panel_characteristics", clear
		local Time = "Annual"
		local Years = "2013, 2016"
		local outcome = "ag_cp_npatrol_total"
		local Outcome = "Patrol officers"
		local absorb = "year unit"
		local dataset="2year"	
	}
	if `c' == 3 {
		use "DTA/Agency_panel_characteristics", clear
		local Time = "Annual"
		local Years = "2013, 2016"
		local outcome = "ag_cp_nsara_total"
		local Outcome = "Sara officers"
		local absorb = "year unit"
		local dataset="2year"
	}
	if `c' == 4 {
		use "DTA/Agency_panel_characteristics", clear
		local Time = "Annual"
		local Years = "2013, 2016"
		local outcome = "ag_officers_black_total"
		local Outcome = "Black officers"
		local absorb = "year unit"
		local dataset="2year"
	}
	if `c' == 5 {
		use "DTA/Agency_panel_characteristics", clear
		local Time = "Annual"
		local Years = "2013, 2016"
		local outcome = "ag_officers_white_total"
		local Outcome = "White officers"
		local absorb = "year unit"
		local dataset="2year"
	}
	if `c' == 6 {
		use "DTA/Agency_panel_characteristics", clear
		g experienced =  (ag_officers-ag_new_officers_total) * ((ag_officers-ag_new_officers_total)>0)
		local Time = "Annual"
		local Years = "2013, 2016"
		local outcome = "experienced"
		local Outcome = "Exp. officers"
		local absorb = "year unit"
		local dataset="2year"
	}	
	if `c' == 7 {
		use "DTA/Agency_panel_characteristics", clear
		local Time = "Annual"
		local Years = "2013, 2016"
		local outcome = "ag_min_edu"
		local Outcome = "College required"
		local absorb = "year unit"
		local dataset="2year"
	}
	if `c' == 8 {
		use "DTA/Agency_panel_characteristics", clear
		g _force = ag_doc_chem == 1 |  ag_doc_discharge == 1 | ag_doc_display == 1 | ag_doc_neck == 1
		local Time = "Annual"
		local Years = "2013, 2016"
		local outcome = "_force"
		local Outcome = "Force doc."
		local absorb = "year unit"
		local dataset="2year"
	}		
	if `c' == 9 {
		use "DTA/Agency_panel_characteristics", clear
		replace ag_budget = ag_budget/1000000
		local Time = "Annual"
		local Years = "2013, 2016"
		local outcome = "ag_budget"
		local Outcome = "\small{Budget (millions)}"
		local absorb = "year unit"
		local dataset="2year"
	}
	
	* Find pretreatment mean
	if `c'==1{
		sum `outcome' [aw=weight] if time<0 & time>=-4 & treated==1, meanonly
	}
	else{
	    bys unit: gegen test = count(`outcome')
		drop if test==1
		drop test
		sum `outcome'[aw=weight] if year==2013 & treated==1, meanonly
	}
	local b=r(mean)

	* Estimates	without population controls
	if "`dataset'"=="2year"{
		reghdfe `outcome' treatment [aw=weight], cluster(strata) absorb(`absorb' )
	}
	else{
		reghdfe `outcome' treatment [aw=_wt_unit], cluster(strata) absorb(`absorb' )
	}
	di "TESTING AVERAGE TREATMENT"
	lincom treatment/`b'*100
	eststo est`c'
	
	* Store regression results
	local beta: di %10.2fc round(r(estimate),.01)	
	local beta = trim("`beta'")
	local se: di %10.2fc round(r(se),.01)	
	local se = trim("`se'")
	estadd local overall_beta1 = "`beta'"
	estadd local overall_se1 = "(`se')"	
	
	* Estimates	without population controls
	cap g event=1
	if "`dataset'"=="2year"{
		reghdfe `outcome' treatment [aw=weight], cluster(strata) absorb(`absorb' event#pop_c##c.population)
	}
	else{
		reghdfe `outcome' treatment [aw=_wt_unit], cluster(strata) absorb(`absorb'  event#pop_c##c.population)
	}
	di "TESTING AVERAGE TREATMENT"
	lincom treatment/`b'*100	
	
	* Store regression results
	local beta: di %10.2fc round(r(estimate),.01)	
	local beta = trim("`beta'")
	local se: di %10.2fc round(r(se),.01)	
	local se = trim("`se'")
	est restore est`c'	
	estadd local overall_beta2 = "`beta'"
	estadd local overall_se2 = "(`se')"	
	
	* Pretreatment mean
	local pre: di %10.3gc round(`b',.001)	
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
	if `c'==1{
		sum event, meanonly
		local cohorts: di %10.3gc round(r(max),.001)	
		estadd local coh = "`cohorts'"
	}
	else{
		estadd local coh = "1"
	}
	
	* Sample Size
	local N: di %10.3gc round(e(N),.001)	
	estadd local obs = "`N'"	
	
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
	estadd local Time = "`Time'"
	estadd local Years = "`Years'"
	estadd local coltitle = "`Outcome'"
	estadd local blank=""
}

* Save Table
esttab est* using Output/mechanisms_agency.tex, 								///
	stats(coltitle blank overall_beta1 overall_se1 blank overall_beta2 			///
		overall_se2 pre protests participants tr co coh  						///
		obs Years Time,															///
		fmt( %010.0gc )															///
		label(																	///
		"\midrule \textbf{Outcome:} "											///
		"\midrule\addlinespace[0.3cm]\textit{No population control:}"			///
		"\addlinespace[0.1cm]Impact of protest \$(\%\Delta)\$" 					///
			" " 																///
		"\addlinespace[0.3cm]\textit{Flexible population control:}"			 	///
		"\addlinespace[0.1cm]Impact of protest \$(\%\Delta)\$" 					///
			" " 																///
		"\addlinespace[0.1cm] \midrule Average outcome pre-protest"				/// 
		"\addlinespace[0.1cm]Total number of protests"							///
		"\addlinespace[0.1cm]Total number of protesters"						///
		"\addlinespace[0.1cm]Agencies with early protests"						/// 		
		"\addlinespace[0.1cm]Agencies with later protests"						/// 
		"\addlinespace[0.1cm]Number of cohorts"									///
		"\addlinespace[0.1cm]Sample size"										///
		"\addlinespace[0.1cm]Years"												///
		"\addlinespace[0.1cm]Time unit"											///
		)																		///
	)																			///
	keep( ) replace nomtitles nonotes booktabs nogap nolines			 		///	
	prehead(\begin{tabular}{l*{20}{x{1.5cm}}} \toprule) 						///
	posthead()  																///
	postfoot(\bottomrule \end{tabular}) 

* Exit stata
exit, clear STATA