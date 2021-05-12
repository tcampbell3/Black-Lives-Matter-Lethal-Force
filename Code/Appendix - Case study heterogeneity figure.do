clear all
global outcome="homicides"
use DTA/case_study, clear
g etime=floor(time/12)
drop if etime<-4
fasterxtile pop_c=popest, nq(10)

**** synthetic control weights ****

tempvar tframe
tempvar wideframe
tempfile temp
sum etime, meanonly
local base=r(min)
sum event, meanonly
local alpha=r(N) // Ridge pentalty is set to sample size
local glast=r(max)
forvalues g=1/`glast'{
	di in red "GROUP: `g' / `glast'"
	qui{
	cap frame drop `tframe'
	frame put if inlist(event,`g'), into(`tframe')
	frame `tframe'{
		
		* Keep what is needed
		keep event fips etime ${outcome} treated pop_c

		* De-mean outcome by fixed effects (do not weight)
		local demean=""
		foreach v of varlist fips etime pop_c{
			bys event `v': gegen _d_`v' = mean(${outcome})
			local demean = "`demean'-_d_`v'"
		}
		replace ${outcome} = ${outcome} `demean'
		drop _d*
		
		* Keep pretreatment data for matching
		keep if etime<0&etime>`base'
		gcollapse ${outcome} treated, by(event fips etime)
		
		* Reshape wide by group
		gegen group=group(event fips) if inlist(treated,0)
		replace group = group+1
		replace group = 1 if inlist(treated,1)
		gsort group etime ${outcome}
		cap frame drop `wideframe'
		frame put $outcome etime group, into(`wideframe')
		frame `wideframe'{
			greshape wide ${outcome}, i(etime) j(group)
			
			* Count groups
			ds ${outcome}*, alpha
			local vars : di wordcount("`r(varlist)'")
			local outcomes=""
			forvalues v=2/`vars'{
				local outcomes="`outcomes' ${outcome}`v'"
			}

			* Mata - linear program to find synth weights with ridge regularization
			clear mata
			mata {
				X = st_data(.,("`outcomes'"))
				y = st_data(.,"${outcome}1")
				tau = .5
				n = rows(X)
				k = cols(X)
				alpha=`alpha'
				X = (X\I(k)*alpha)
				y = (y\J(k, 1, 0))
				n = rows(X)
				k = cols(X)
				c = (J(1, k, 0), tau * J(1, n, 1), (1 - tau) * J(1, n, 1))
				Aec = (X, I(n), -I(n) \ J(1, k, 1), J(1, 2*n, 0))
				y = (y\1)
				lowerbd = (J(1, k, .0001), J(1, 2*n, 0))
				upperbd =  (J(1, k, 1), J(1, 2*n, .))
				q = LinearProgram()
			}
			mata{
				q.setCoefficients(c)
				q.setEquality(Aec, y)
				q.setBounds(lowerbd, upperbd)
				q.setMaxOrMin("min")
				q.optimize()
				x = q.parameters()
				st_matrix("weights", x[1..k])
			}
			
		}
		
		* Save weights
		g synth_unit = 1 if inlist(group,1)
		sum group, meanonly
		local last = r(max)-1
		forvalues i = 1/`last'{
			local j=`i'+1
			qui replace synth_unit = weights[1,`i'] if inlist(group,`j')
		}
		
		* save temp file to merge
		keep synth_unit fips event
		gduplicates drop
		tempfile temp
		save `temp', replace
		
	}
	merge m:1 event fips using `temp', nogen update
	}
}

* Define covariates (omitted category is first and last year of event time)
sum etime, meanonly
local m=r(max) -1
local l=abs(r(min))-1
forvalues i=0/`m'{
	g post`i'=inlist(etime,`i')&inlist(treated,1)
}
forvalues i=1/`l'{
	g pre`i'=inlist(etime,-`i')&inlist(treated,1)
}
order pre* post*, last seq

* Results
cap drop _i*
g _i=_n-2 in 1/4
cap drop _ub*
g _ub=.
cap drop _lb*
g _lb=.
cap drop _b*
g _beta=.
cap drop _e
g _e=_n-4 in 1/8
forvalues i=-1/2{
	
	* Store event time
	local j=`i'+2
	g _ub`j'=.
	g _lb`j'=.
	g _beta`j'=.
	
	* local video group or overall
	if `i'==-1{
		local v1=""
		local v2=""
	}
	else{
		local v1="if inlist(vid,`i')"
		local v2="&inlist(vid,`i')"
	}
	
	* Regression
	reghdfe homicides pre* post* [aw=synth] `v1', a(event#fips event#etime event#pop_c) vce(cluster fips)
	sum homicides if inlist(etime,-1) & inlist(treated,1) `v2',meanonly
	local b= r(mean)
	forvalues z=-3/4{
		if `z'<0{
			local x=abs(`z')
			lincom (pre`x'-(pre1+pre2+pre3)/3)/`b'
		}
		else{
			lincom (post`z'-(pre1+pre2+pre3)/3)/`b'
		}
		replace _ub`j' = r(ub) if inlist(_e,`z')
		replace _lb`j' = r(lb) if inlist(_e,`z')
		replace _beta`j' = r(estimate) if inlist(_e,`z')
	}
	lincom ((post0+post1+post2+post3+post4)/5-(pre1+pre2+pre3)/3)/`b'
	replace _ub = r(ub) if inlist(_i,`i')
	replace _lb = r(lb) if inlist(_i,`i')
	replace _beta = r(estimate) if inlist(_i,`i')
}

* Figures
twoway (rcap _ub _lb _i, col(maroon) msize(huge) lw(medthick)) (scatter _beta _i, m(O) color(navy)), yline(0,lp(solid)) ylab(-.5(.25).25) xlab(-1.5 " " -1 "Pooled" 0 "Video before protest" 1 "Protest before video" 2 "No video" 2.5 " ") xtitle("") legend(off)
graph export "${user}/Output/case_study.pdf", replace


forvalues g=1/4{
twoway (line _beta`g' _e, sort) (rcap _ub`g' _lb`g' _e, col(maroon) msize(large) lw(medthick)) (scatter _beta`g' _e, m(O) color(navy)), yline(0,lp(solid)) xline(-.5, lc(red)) legend(off) xlabel(-3(1)4) xtitle("Years relative to first protest") ytitle("% {&Delta} Lethal Force")  ylab(-1(.25).25)
graph export "${user}/Output/case_study_`g'.pdf", replace
}
