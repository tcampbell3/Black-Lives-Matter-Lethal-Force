
* foreach census (2000 and 2010)
foreach n in 00 10{
	*import
	import delimited "Data\Geography\Size\DEC_`n'_SF1_GCTPH1.ST10_with_ann.csv", varnames(2) clear
	split geographic*area, parse(" - " ", ")
	rename geographic*area3 city
	rename geography stname
		
	*Keep place summary level
	gen placetest=substr(targetgeoid,1,3)
	keep if placetest == "160" 
	
	* fips
	gen dummy=targetgeoid
	split dummy ,parse("US")
	gen stfips=substr(dummy2, 1,2)
	gen fips=dummy2
	
	* clean up
	rename housing housing
	rename areainsquaremileslandarea land
	keep stname fips housing land
	
	* year
	gen year="20`n'"
	destring year, replace

	*convert housing to string
	if "`n'"=="10"{
		split housing, parse("(")
		replace housing=housing1
		drop housing1 housing2
		destring housing, replace
	}

	* clean up
	order fips year
	sort fips year
	collapse (sum) geo_housing_`n'=housing geo_land_`n'=land, by(fips year)
	save DTA/size_`n', replace
}


//Note: housing is number of homes and land is square miles
