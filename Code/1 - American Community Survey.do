
* Setup
cd "${user}"
cap frame change default
cap frame drop newframe
frame create newframe

* Black (https://api.census.gov/data/2015/acs/acs5/variables.html)

	* Unzip Folder
	clear
	cd "Data/American Community Survey/Black"
	unzipfile "productDownload_2020-04-03T124458", replace
	
	* First year
	import delimited "ACSDT5Y2010.B01001B_data_with_overlays_2020-04-03T123907.csv", varnames(1) rowrang(3:) clear
	g year = 2010
	tempfile temp
	erase "ACSDT5Y2010.B01001B_data_with_overlays_2020-04-03T123907.csv"
	
	* Append remaining years
	forvalues year = 11/18{
		frame change newframe
		import delimited "ACSDT5Y20`year'.B01001B_data_with_overlays_2020-04-03T123907.csv", varnames(1) rowrang(3:) clear
		g year = 20`year'
		save `temp', replace
		frame change default
		append using `temp'
		
		erase "ACSDT5Y20`year'.B01001B_data_with_overlays_2020-04-03T123907.csv"

	}
	
	* Define Variables
	destring b01001b_001e, g(black)
	split geo_id, parse("US")
	rename geo_id2 fips
	
	* clean up
	keep fips year black
	order fips year
	cd ../../..
	save DTA/ACS_5yr, replace
	
* White (https://api.census.gov/data/2015/acs/acs5/variables.html)

	* Unzip Folder
	clear
	cd "Data/American Community Survey/White"
	unzipfile "productDownload_2020-04-03T124631", replace
	
	* First year
	import delimited "ACSDT5Y2010.B01001A_data_with_overlays_2020-04-03T124510.csv", varnames(1) rowrang(3:) clear
	g year = 2010
	tempfile temp
	erase "ACSDT5Y2010.B01001A_data_with_overlays_2020-04-03T124510.csv"
	
	* Append remaining years
	forvalues year = 11/18{
	
		frame change newframe
		import delimited "ACSDT5Y20`year'.B01001A_data_with_overlays_2020-04-03T124510.csv", varnames(1) rowrang(3:) clear
		g year = 20`year'
		save `temp', replace
		frame change default
		append using `temp'
		
		erase "ACSDT5Y20`year'.B01001A_data_with_overlays_2020-04-03T124510.csv"

	}
	
	* Define Variables
	destring b01001a_001e, g(white)
	split geo_id, parse("US")
	rename geo_id2 fips
	
	* clean up
	keep fips year white
	order fips year
	cd ../../..
	merge 1:1 fips year using DTA/ACS_5yr, nogen
	save DTA/ACS_5yr, replace

* Hispanic (https://api.census.gov/data/2016/acs/acs5/groups/B01001I.html)

	* Unzip Folder
	clear
	cd "Data/American Community Survey/Hispanic"
	unzipfile "productDownload_2020-04-03T124907", replace
	
	* First year
	import delimited "ACSDT5Y2010.B01001I_data_with_overlays_2020-04-03T124808.csv", varnames(1) rowrang(3:) clear
	g year = 2010
	tempfile temp
	erase "ACSDT5Y2010.B01001I_data_with_overlays_2020-04-03T124808.csv"
	
	* Append remaining years
	forvalues year = 11/18{
	
		frame change newframe
		import delimited "ACSDT5Y20`year'.B01001I_data_with_overlays_2020-04-03T124808.csv", varnames(1) rowrang(3:) clear
		g year = 20`year'
		save `temp', replace
		frame change default
		append using `temp'
		
		erase "ACSDT5Y20`year'.B01001I_data_with_overlays_2020-04-03T124808.csv"

	}
	
	* Define Variables
	destring b01001i_001e, g(hispanic) force
	split geo_id, parse("US")
	rename geo_id2 fips
	
	* clean up
	keep fips year hispanic
	order fips year
	cd ../../..
	merge 1:1 fips year using DTA/ACS_5yr, nogen
	save DTA/ACS_5yr, replace
	
* Education (https://api.census.gov/data/2016/acs/acs5/subject/groups/S1501.html)

	* Unzip Folder
	clear
	cd "Data/American Community Survey/Education"
	unzipfile "productDownload_2020-04-03T171348", replace
	
	* First year
	import delimited "ACSST5Y2010.S1501_data_with_overlays_2020-04-03T165709.csv", varnames(1) rowrang(3:) clear
	g year = 2010
	tempfile temp
	erase "ACSST5Y2010.S1501_data_with_overlays_2020-04-03T165709.csv"
	
	* Append remaining years
	forvalues year = 11/18{
	
		frame change newframe
		import delimited "ACSST5Y20`year'.S1501_data_with_overlays_2020-04-03T165709.csv", varnames(1) rowrang(3:) clear
		g year = 20`year'
		save `temp', replace
		frame change default
		append using `temp'
		
		erase "ACSST5Y20`year'.S1501_data_with_overlays_2020-04-03T165709.csv"

	}
	

	
	* Define Variables - Education (25 years and older)
	destring s1501_c01_006e, g(edu_pop) 	
	destring s1501_c01_007e, g(_9_grade) force
	destring s1501_c01_008e, g(_9_12_grade) force	
	destring s1501_c01_009e, g(high_school_total) force	
	destring s1501_c01_010e, g(some_college_total) force
	destring s1501_c01_011m, g(associates_total) force	
	destring s1501_c01_012e, g(bachelors_total) force	
	destring s1501_c01_013e, g(graduate_total) force	
	gen lt_high_school = (_9_grade+_9_12_grade) / edu_pop * 100 * (year>=2015) + (_9_grade+_9_12_grade) * (year<2015) 
	gen high_school = high_school_total / edu_pop * 100 * (year>=2015)+ (high_school_total) * (year<2015) 
	gen some_college = (some_college_total+associates_total)/edu_pop*100* (year>=2015)+(some_college_total+associates_total) * (year<2015) 
	gen college = (bachelors_total+graduate_total) / edu_pop*100* (year>=2015)+(bachelors_total+graduate_total) * (year<2015)
	split geo_id, parse("US")
	rename geo_id2 fips
	
	* clean up
	keep fips year lt_high_school high_school some_college college
	order fips year
	cd ../../..
	merge 1:1 fips year using DTA/ACS_5yr, nogen
	save DTA/ACS_5yr, replace

* Employment (https://api.census.gov/data/2016/acs/acs5/subject/groups/S2301.html)

	* Unzip Folder
	clear
	cd "Data/American Community Survey/Employment"
	unzipfile "productDownload_2020-04-03T172149", replace
	
	* First year
	import delimited "ACSST5Y2010.S2301_data_with_overlays_2020-04-03T171534.csv", varnames(1) rowrang(3:) clear
	g year = 2010
	tempfile temp
	erase "ACSST5Y2010.S2301_data_with_overlays_2020-04-03T171534.csv"
	
	* Append remaining years
	forvalues year = 11/18{
	
		frame change newframe
		import delimited "ACSST5Y20`year'.S2301_data_with_overlays_2020-04-03T171534.csv", varnames(1) rowrang(3:) clear
		g year = 20`year'
		save `temp', replace
		frame change default
		append using `temp'
		
		erase "ACSST5Y20`year'.S2301_data_with_overlays_2020-04-03T171534.csv"

	}
	
	* Define Variables - Education (25 years and older)
	destring s2301_c01_001e, g(population) force
	destring s2301_c02_001e, g(labor_force) force
	destring s2301_c03_001e, g(employment) force
	destring s2301_c04_001e, g(unemployment) force
	destring s2301_c01_028e, g(poverty_total) force
	g poverty = poverty_total / population*100
	split geo_id, parse("US")
	rename geo_id2 fips
	
	* clean up
	keep fips year labor_force employment unemployment poverty
	order fips year
	cd ../../..
	merge 1:1 fips year using DTA/ACS_5yr, nogen
	save DTA/ACS_5yr, replace

* Poverty

	* Unzip Folder
	clear
	cd "Data/American Community Survey/Poverty"
	unzipfile "productDownload_2020-04-03T122357", replace
	
	* First year
	import delimited "ACSST5Y2012.S1701_data_with_overlays_2020-04-03T121704.csv", varnames(1) rowrang(3:) clear
	g year = 2010
	tempfile temp
	erase "ACSST5Y2012.S1701_data_with_overlays_2020-04-03T121704.csv"
	
	* Append remaining years
	forvalues year = 13/18{
	
		frame change newframe
		import delimited "ACSST5Y20`year'.S1701_data_with_overlays_2020-04-03T121704.csv", varnames(1) rowrang(3:) clear
		g year = 20`year'
		save `temp', replace
		frame change default
		append using `temp'
		
		erase "ACSST5Y20`year'.S1701_data_with_overlays_2020-04-03T121704.csv"

	}
	
	* Economic Variables
	destring s1701_c01_035e, g(full_time_total) force
	destring s1701_c01_034e, g(pop_16_64) force
	destring s1701_c02_014e, g(black_poverty_total) force
	destring s1701_c01_014e, g(black_total) force
	gen full_time = full_time_total / pop_16_64
	g black_pov = black_poverty_total / black_total
	split geo_id, parse("US")
	rename geo_id2 fips
	
	* clean up
	keep fips year full_time black_pov
	order fips year
	cd ../../..
	merge 1:1 fips year using DTA/ACS_5yr, nogen
	
	* Rename
	ds fips year, not
	local vars = r(varlist)
	foreach v in `vars'{
		rename `v' acs_`v'
	}
	
	* Save
	compress
	save DTA/ACS_5yr, replace









