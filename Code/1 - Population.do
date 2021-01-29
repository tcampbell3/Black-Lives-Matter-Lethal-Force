
				**************************
				  // Create Population
				**************************

// 1. Find Consolidated city FIPS code for 2000-2010

	import delimited "Data\Population\2000-2010-population.csv", clear
	
	*Keep place summary level
	keep if sumlev == 162
	
	*Generate place fips
	gen state_fips = string(state,"%02.0f")
	gen place_fips = string(place,"%05.0f")
	gen fips = state_fips + place_fips 

	* Collapse into Unique locality fips
	collapse (first) city=name stname (sum) pop*, by(fips)
	
	*Save temporary file to merge
	tempfile temp
	save `temp', replace
	
// 2. Open old population data and label consolidated cities

	import delimited "Data\Population\2010-2019-population.csv", clear
	
	*Keep place summary level
	keep if sumlev == 162 
	
	*Generate place fips
	gen state_fips = string(state,"%02.0f")
	gen place_fips = string(place,"%05.0f")
	gen fips = state_fips + place_fips 

	* Collapse into Unique locality fips
	collapse (first) city=name stname (sum) pop*, by(fips)
		
	*Merge
	merge 1:1 fips using `temp', keep(1 3) nogen
	
// 3. Place Populations

	*reshape data
	reshape long popestimate, i(fips) j(year)  
	
	*make data quarterly
	gen id=_n
	expand 4
	bys id year: gen qtr=year*10+_n
	drop id
	
// 4. Get state abbreviations

	preserve
		import delimited "Data\state_abb.csv", varnames(1) clear 
		tempfile temp
		save `temp', replace
	restore
	merge m:1 stname using `temp', nogen keep(3)

// 5. Clean Up

	order fips stname city qtr
	sort fips qtr
	compress
	save DTA/Population, replace
	
// 6. Fips crosswalk

	use DTA/Population, clear

	* remove last word from city	
	split city, parse(" (")
	gen tail1 = word(city1,-1)
	gen head1 = substr(city1,1,length(city1) - length(tail1) - 1)
	replace head1 = tail1 if inlist(head1,"")
	drop tail1 city*
	rename head1 city

	* deal with matching balances
	replace city = subinstr(city, "unified government", "",.) 
	replace city = subinstr(city, "consolidated government", "",.) 
	replace city = subinstr(city, "city", "",.) 
	replace city = subinstr(city, "metro government", "",.) 
	replace city = subinstr(city, "metropolitan government", "",.) 
	replace city = subinstr(city, "/", "-",.) 
	
	* remove spaces at ends
	replace city = strtrim(city)
	
	* statenum
	g stnum=substr(fips, 1,2)
	
	* Save
	collapse (first) stname stnum stabb city (mean) popestimate, by(fips)
	
	* City state unique by choosing amx population (doesnt affect places with pop over 30000)
	bys city stabb: egen dummy=max(popestimate)
	bys city stabb: gen dummy2=popestimate
	keep if dummy==dummy2
	drop dummy*

	order fips stname city
	compress
	save DTA/fips, replace				
