clear all

* Loop over number of regression column specifications
forvalues c=1/4{

	* Estimate 
	use DTA/Twitter_stack, clear
	if `c'==1{
		reghdfe tweets treatment, cluster(id) a(event#id event#time)
		eststo
		estadd local outcome = "Total tweets"
		estadd local weights = ""
		sum tweets if time<0 & time>=-4 & treated==1, meanonly
	}
	if `c'==2{
		reghdfe tweets treatment [aw=_unit_tweets], cluster(id) a(event#id event#time)
		eststo
		estadd local outcome = "Total tweets"
		estadd local weights = "\checkmark"
		sum tweets if time<0 & time>=-4 & treated==1, meanonly
	}
	if `c'==3{
		reghdfe sub_polarity treatment, cluster(id) a(event#id event#time)
		eststo
		estadd local outcome = "Sentiment"
		estadd local weights = ""
		sum sub_polarity if time<0 & time>=-4 & treated==1, meanonly
	}
	if `c'==4{
		reghdfe sub_polarity treatment [aw=_unit_sub_polarity], cluster(id) a(event#id event#time)
		eststo
		estadd local outcome = "Sentiment"
		estadd local weights = "\checkmark"
		sum sub_polarity if time<0 & time>=-4 & treated==1, meanonly
	}
	
	* Pretreatment mean
	local b=r(mean)
	local pre: di %10.4gc round(r(mean),.0001)	
	estadd local pre = "`pre'"

	* Store regression results
	lincom treatment/`b'*100
	local beta: di %10.2fc round(r(estimate),.01)	
	local beta = trim("`beta'")
	local se: di %10.2fc round(r(se),.01)	
	local se = trim("`se'")
	estadd local overall_beta = "`beta'"
	estadd local overall_se = "(`se')"
		
	* Treated, control, cohorts
	cap drop _samp
	bys treated: gegen _samp=nunique(id)
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

	* Fixed effects
	estadd local unit = "\checkmark"
	estadd local time = "\checkmark"

}

* Save Table
esttab est* using Output/twitter.tex, 											///
	stats(outcome overall_beta overall_se pre protests participants tr co coh 	///
	obs unit time weights,														///
		fmt( %010.0gc )															///
		label(																	///
		"\midrule \textbf{Outcome:} "											///
		"\midrule\addlinespace[0.3cm]\$\%\Delta\text{Outcome}\$" 				///
			" " 																///
		"\addlinespace[0.1cm] \midrule Average outcome pre-protest"				/// 
		"\addlinespace[0.1cm]Total number of protests"							///
		"\addlinespace[0.1cm]Total number of protesters"						///
		"\addlinespace[0.1cm]Treated units with early protests"					/// 		
		"\addlinespace[0.1cm]Control units with later protests"					/// 
		"\addlinespace[0.1cm]Number of cohorts"									///
		"\addlinespace[0.1cm]Sample size"										///
		"\addlinespace[0.1cm] \midrule Cohort-unit fixed effecs"				///
		"\addlinespace[0.1cm]Cohort-event time fixed effects"					///
		"\addlinespace[0.1cm]Synthetic unit weights"							///
		)																		///
	)																			///
	keep( ) replace nomtitles nonotes booktabs nogap nolines			 		///	
	prehead(\begin{tabular}{l*{20}{x{2cm}}} \toprule) 							///
	posthead()  																///
	postfoot(\bottomrule \end{tabular}) 

* Exit stata
exit, clear STATA