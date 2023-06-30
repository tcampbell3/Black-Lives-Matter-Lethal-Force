clear all
global absorb = "i.event#i.time i.event#i.FIPS i.event#i.pop_c i.event#i.pop_c#c.popestimate"
* Loop over number of regression column specifications
forvalues c=100000(25000)200000{
	
	* Population screen
	use DTA/stacked_pop_`c', clear
	cap drop dummy
	bys fips: egen dummy = min(popest)
	local screen: di %10.0fc `c'
	reghdfe homicides treatment [aw=ipw], cluster(fips) a(event#fips event#time event#pop_c##c.popest)
	eststo
	
	* Pretreatment mean
	sum homicides if time<0 & time>=-4 & treated==1, meanonly
	local b=r(mean)
	local pre: di %10.2gc round(r(mean),.01)	
	estadd local pre = "`pre'"

	* Store regression results
	lincom treatment/`b'*100
	local beta: di %10.2fc round(r(estimate),.01)	
	local beta = trim("`beta'")
	local se: di %10.2fc round(r(se),.01)	
	local se = trim("`se'")
	estadd local overall_beta = "`beta'"
	estadd local overall_se = "(`se')"
	
	* Exposed time-units
	cap drop _dummy
	gegen _dummy = group(time fips) if inlist(treatment,1)
	sum _dummy, meanonly
	local e: di %10.3gc round(r(max),.001)	
	local e = r(max)
	estadd local total_exposed = "`e'"
	
	* Total Prevented
	lincom treatment*`e'
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
	
	* Column title
	estadd local coltitle = "`screen'"
}

* Save Table
esttab est* using Output/low_pop_thresh.tex, 									///
	stats(coltitle overall_beta overall_se prevented_beta prevented_se pre 		///
		total_exposed deaths protests participants tr co coh obs,				///
		fmt( %010.0gc )															///
		label(																	///
		"\midrule \textbf{Treated population threshold:} "						///
		"\midrule\addlinespace[0.3cm]\$\%\Delta\text{Lethal Force}\$" 			///
			" " 																///
		"\addlinespace[0.3cm]\$\Delta\text{Total Lethal Force}\$" 				///
			" " 																///
		"\addlinespace[0.1cm] \midrule Average lethal force pre-protest"		/// 
		"\addlinespace[0.1cm]Total place-quarters after protest"				/// 		
		"\addlinespace[0.1cm]Total lethal force post-protest"					/// 
		"\addlinespace[0.1cm]Total number of protests"							///
		"\addlinespace[0.1cm]Total number of protesters"						///
		"\addlinespace[0.1cm]Treated cities with early protests"				/// 		
		"\addlinespace[0.1cm]Control cities with later protests"				/// 
		"\addlinespace[0.1cm]Number of cohorts"									///
		"\addlinespace[0.1cm]Sample size"										///
		)																		///
	)																			///
	keep( ) replace nomtitles nonotes booktabs nogap nolines			 		///	
	prehead(\begin{tabular}{l*{20}{x{1.5cm}}} \toprule) 						///
	posthead()  																///
	postfoot(\bottomrule \end{tabular}) 

* Exit stata
exit, clear STATA