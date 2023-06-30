clear all
forvalues c = 1/5{

	* Column specific estimate
	if `c'==1{
		* Regression
		use DTA/Stacked, clear
		reghdfe homicides treatment* [aw=_wt_unit], cluster(fips) a(event#fips event#time event#pop_c##c.popest)
		eststo
		
		* Pretreatment mean
		sum homicides if time<0 & time>=-4 & treated==1, meanonly
		local b=r(mean)
		local pre: di %10.2gc round(r(mean),.01)	
		estadd local pre = "`pre'"
		
		* Estimate
		local test "treatment/`b'*100"
		lincom `test'
		estadd local coltitle = "Stacked"
	}
	if `c'==2{		
		* Regression
		use DTA/Stacked, clear
		reghdfe homicides c.(treatment)#event [aw=_wt_unit], cluster(fips) 	///
			a(event#fips event#time event#pop_c##c.popest)
		eststo
		
		* Pretreatment mean
		sum homicides if time<0 & time>=-4 & treated==1, meanonly
		local b=r(mean)
		local pre: di %10.2gc round(r(mean),.01)	
		estadd local pre = "`pre'"

		* Estimate		
		unique fips if inlist(treated,1) & inlist(time,0)
		local tot=r(unique)
		forvalues e=1/4{
		 local test`e' "`e'.event#treatment/`b'*100"
		 lincom `test`e''
		 qui unique fips if inlist(treated,1) & inlist(time,0) & inlist(event,`e')
		 local w`e'=r(unique)/`tot'
		}
		local test "(`w1'*`test1'+`w2'*`test2'+`w3'*`test3'+`w4'*`test4')"
		lincom `test'
		estadd local coltitle = "Manual stacked"
	}
	if `c'==3{
		* Regression
		use DTA/Stacked, clear
		ppmlhdfe homicides treatment, cluster(fips) a(event#fips event#time event#pop_c##c.popest) d
		eststo
		
		* Pretreatment mean
		sum homicides if time<0 & time>=-4 & treated==1, meanonly
		local b=r(mean)
		local pre: di %10.2gc round(r(mean),.01)	
		estadd local pre = "`pre'"
		
		* Estimate
		margins, eydx(treatment)
		estadd local coltitle = "Stacked poisson"
	}
	if `c'==4{		
		* Sample
		use DTA/summary,clear
		destring fips, replace
		keep if inlist(treated,1) & qtr<=20201 & year>=2009
		
		* Treated
		drop treated
		g dummy=protests>0
		bys fips: gegen treated = max(dummy)
		
		* Define relative tme
		gegen time_cat = group(qtr)
		bys fips: gegen start = min(time_cat) if inlist(treatment,1)
		bys fips (start): replace start = start[_n-1] if inlist(start,.)
		g time = time_cat-start
		
		* Drop middle cohorts so same sample as stacked data (ensures cohort has full post-treatment sample)
		drop if start >= 27 & !inlist(start,.)
		
		* Regression
		reghdfe homicides treatment, absorb(fips qtr pop_c#c.popest) vce(cluster fips)
		eststo
		
		* Pretreatment mean
		sum homicides if inlist(floor(time/4),-1)
		local b=r(mean)
		local pre: di %10.2gc round(r(mean),.01)	
		estadd local pre = "`pre'"		
		
		* Final estimate
		local test "treatment/`b'*100"
		lincom `test'
		estadd local coltitle = "Two-way fixed effects"
	}
	if `c'==5{		
		* Sample
		use DTA/summary,clear
		keep if qtr<=20201		// treated units post covid are used as controls
		keep if treated==1

		* Define treated and donor
		drop treated donor
		g dummy=protests>0
		bys fips: gegen treated = max(dummy)
		g donor = inlist(treated,0)

		* Define cohort (missing for never treated)
		gegen time_cat = group(qtr)
		bys fips: gegen start = min(time_cat) if inlist(treatment,1)
		bys fips (start): replace start = start[_n-1] if inlist(start,.)

		* Drop middle cohorts so same sample as stacked data (ensures cohort has full post-treatment sample)
		drop if start >= 63 & !inlist(start,.)

		* Define relative time
		g time = time_cat-start
		destring fips, replace

		* Treatment time dummies should never be missing
		local j=1
		forvalues i=-5/4{
			local j = abs(`i')
			if `i'<-1{
				g _t_`j' = inlist(floor(time/4),`i')
			}
			if `i'>=0{
				g _t`j' = inlist(floor(time/4),`i')
			}
		}
		replace treatment=. if treated==0

		* Regression
		eventstudyinteract homicides _t*, cohort(treatment) absorb(fips time_cat) ///
			control_cohort(donor) vce(cluster fips) covariates(i.pop_c#c.popest)
		eststo
		
		* Pretreatment mean
		sum homicides if inlist(floor(time/4),-1)
		local b=r(mean)
		local pre: di %10.2gc round(r(mean),.01)	
		estadd local pre = "`pre'"

		* Final estimate
		local test "((__00000W+__00000Y+__000010+__000012+__000014)/5-(0+__00000T+__00000R+__00000P+__00000N)/5) /`b'*100"
		lincom `test'
		estadd local coltitle = "Sun and Abraham (2021)"
	}

	* Store regression results
	if `c'==3{
		local beta: di %10.2fc round(r(b)[1,1]*100,.01)	
		local se: di %10.2fc round(sqrt(r(V)[1,1])*100,.01)	

	}
	else{
		local beta: di %10.2fc round(r(estimate),.01)
		local se: di %10.2fc round(r(se),.01)	
	}
	local beta = trim("`beta'")
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
	if `c'==3{
		margins, eydx(treatment)
		local beta: di %10.0fc round(abs(r(b)[1,1])*`b'*`e',.01)	
		local se: di %10.1fc round(sqrt(r(V)[1,1])*`b'*`e',.01)	
	}
	else{
		lincom `test'*`b'*`e'/100
		local beta: di %10.0fc abs(round(r(estimate)))	
		local se: di %10.1fc round(r(se),.1)	
	}
	local beta = trim("`beta'")
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
	cap sum event, meanonly
	if _rc!=0{
		unique start if !inlist(start,.)
		local cohorts: di %10.3gc round(r(unique),.001)
	}
	else{
		local cohorts: di %10.3gc round(r(max),.001)
	}
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
}

* Save Table
esttab est* using Output/estimator.tex, 										///
	stats(coltitle overall_beta overall_se prevented_beta prevented_se pre 		///
		total_exposed deaths protests participants tr co coh obs,				///
		fmt( %010.0gc )															///
		label(																	///
		"\midrule \textbf{Estimator:} "											///
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
	prehead(\begin{tabular}{l*{20}{x{2cm}}} \toprule) 						///
	posthead()  																///
	postfoot(\bottomrule \end{tabular}) 

* Exit stata
exit, clear STATA