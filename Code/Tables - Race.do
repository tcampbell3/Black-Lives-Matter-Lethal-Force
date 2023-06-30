clear all
use DTA/stacked, clear

* keep only when MPV has data
drop if qtr<20131

* Drop pretreatment data to balance stacks
drop if time<-6

* Pretreament year 1
g pre1 = inlist(time,-1,-2,-3,-4)&inlist(treated,1)
	
* Loop over number of columns
forvalues c = 1/4{
	
	* col number
	local firstrow = "`firstrow' & (`c')"
	
	* specification
	if `c' == 1 {
		local outcome = "homicides_mpv"
		local absorb = "event#time event#fips  event#pop_c##c.popestimate"
	}
	if `c' == 2 {
		local outcome = "homicides_white_mpv"
		local absorb = "event#time event#fips  event#acs_white_total_c##c.acs_white_total"
	}
	if `c' == 3 {
		local outcome = "homicides_black_mpv"
		local absorb = "event#time event#fips  event#acs_black_total_c##c.acs_black_total"
	}
	if `c' == 4 {		
		g unarmed = homicides_mpv - homicides_armed_mpv
		local outcome="unarmed"
		local absorb = "event#time event#fips  event#pop_c##c.popestimate"
	}
	
	* Estimates	
	reghdfe `outcome' treatment , cluster(fips) absorb(`absorb' )
	eststo
	
	* Pretreatment mean
	sum `outcome' if time<0 & time>=-4 & treated==1, meanonly
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
	cap drop total_post_treated
	gegen total_post_treated = sum(homicides) if inlist(treated,1) & time>=0
	sum total_post_treated, meanonly
	local deaths: di %10.0fc round(r(mean))	
	estadd local deaths = "`deaths'"	

	* Total Protests
	cap drop _total_protests
	gegen _total_protests = sum(protests) 
	sum _total_protests, meanonly
	local protests: di %10.0fc round(r(mean))	
	estadd local protests = "`protests'"	

	* Total Participants
	cap drop _total_partic
	gegen _total_partic = total(participants)
	sum _total_partic, meanonly
	local participants: di %10.0fc round(r(mean))	
	estadd local participants = "`participants'"	
	
	* Column title
	if `c'==1{
		estadd local coltitle = "Total"
	}
	if `c'==2{
		estadd local coltitle = "White"
	}
	if `c'==3{
		estadd local coltitle = "Black"
	}
	if `c'==4{
		estadd local coltitle = "Unarmed"
	}
	
}

* Save Table
esttab est* using Output/mpv_race.tex, 											///
	stats(coltitle overall_beta overall_se prevented_beta prevented_se pre 		///
		total_exposed deaths protests participants tr co coh obs,				///
		fmt( %010.0gc )															///
		label(																	///
		"\midrule \textbf{Subset of victims:} "									///
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
		"\addlinespace[0.1cm]Cohort-census place fixed effecs"					///
		"\addlinespace[0.1cm]Cohort-event time fixed effects"					///
		"\addlinespace[0.1cm]Flexible population control"						///
		)																		///
	)																			///
	keep( ) replace nomtitles nonotes booktabs nogap nolines			 		///	
	prehead(\begin{tabular}{l*{20}{x{1.5cm}}} \toprule) 						///
	posthead()  																///
	postfoot(\bottomrule \end{tabular}) 

* Exit stata
exit, clear STATA