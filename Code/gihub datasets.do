cd "${user}/DTA"

* Summary file
use Summary, clear
zipfile Summary.dta, saving(Summary, replace)

* Agency body cam panel
use Agency_panel_bodycam, clear
zipfile Agency_panel_bodycam.dta, saving(Agency_panel_bodycam, replace)

* Agency characteristics panel
use Agency_panel_characteristics, replace
zipfile Agency_panel_characteristics.dta, saving(Agency_panel_characteristics, replace)

* Agency crime panel
use Agency_panel_crime, clear
zipfile Agency_panel_crime.dta, saving(Agency_panel_crime, replace)

* Stacked dataset (<25 mb per stack)
local p = 5
forvalues i=1/`p'{
	use stacked, clear
	drop stabb stnum season region division strata stname city
	destring fips, replace
	g index =_n
	order index fips
	local start = (`i'-1)/`p'*_N
	local end =`i'/`p'*_N
	di in red "`start' < Index <= `end'	; N="_N
	keep if index > `start' & index<=`end'
	save staked_`i',replace
	zipfile staked_`i'.dta, saving(Stacked_`i', replace)
}
