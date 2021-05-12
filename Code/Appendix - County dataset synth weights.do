* Create dummy dataset for core i
use DTA/Stacked_county, clear
global outcome="homicides"
keep event fips time ${outcome} treated pop_c
sum event, meanonly
local alpha=r(N) 											// Ridge pentalty is set to sample size
keep if event>r(max)/8*(`1'-1) &  event<=r(max)/8*(`1')

**** synthetic control weights ****
tempvar tframe
tempvar wideframe
tempfile temp`1'
sum time, meanonly
local base=r(min)
sum event, meanonly
local glast=r(max)
local gfirst=r(min)
forvalues g=`gfirst'/`glast'{
	timer on 1
	di in red "GROUP: `g' / `glast'"
	qui{
	cap frame drop `tframe'
	frame put if inlist(event,`g'), into(`tframe')
	frame `tframe'{
		
		* Keep what is needed
		keep event fips time ${outcome} treated pop_c

		* De-mean outcome by fixed effects (do not weight)
		local demean=""
		foreach v of varlist fips time pop_c{
			bys event `v': gegen _d_`v' = mean(${outcome})
			local demean = "`demean'-_d_`v'"
		}
		replace ${outcome} = ${outcome} `demean'
		drop _d*
		
		* Keep pretreatment data for matching
		keep if time<0&time>`base'
		gcollapse ${outcome} treated, by(event fips time)
		
		* Reshape wide by group
		gegen group=group(event fips) if inlist(treated,0)
		replace group = group+1
		replace group = 1 if inlist(treated,1)
		gsort group time ${outcome}
		cap frame drop `wideframe'
		frame put $outcome time group, into(`wideframe')
		frame `wideframe'{
			greshape wide ${outcome}, i(time) j(group)
			
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
		save `temp`1'', replace
		
	}
	merge m:1 event fips using `temp`1'', nogen update
	}
	timer off 1
}
timer list 1
save DTA/temp`1', replace

* Exit stata
exit, clear STATA