
* Setup
clear all
cd "${user}"
cap frame change default
tempname tframe
frame create `tframe'
tempfile temp
	
***** Black (Table B01001B) ****

* Append all the data
clear
cd "${user}/Data/American Community Survey/Black"
forvalues y = 10/20{
	frame `tframe'{
		unzipfile "ACSDT5Y20`y'.B01001B.zip", replace
		import delimited "ACSDT5Y20`y'.B01001B.csv", varnames(1) rowrang(3:) clear
		keep geo_id b01001b_001e
		g year = 20`y'
		save `temp', replace
	}
	append using `temp'
	cap erase "ACSDT5Y20`y'.B01001B.csv"
}

* Define Variables
destring b01001b_001e, g(black)
split geo_id, parse("US")
rename geo_id2 fips
	
* clean up
keep fips year black
order fips year
gsort fips year
save ../../../DTA/ACS_5yr, replace
	
***** White (Table B01001A) ****

* Append all the data
clear
cd "${user}/Data/American Community Survey/White"
forvalues y = 10/20{
	frame `tframe'{
		unzipfile "ACSDT5Y20`y'.B01001A.zip", replace
		import delimited "ACSDT5Y20`y'.B01001A.csv", varnames(1) rowrang(3:) clear
		keep geo_id b01001a_001e
		g year = 20`y'
		save `temp', replace
	}
	append using `temp'
	cap erase "ACSDT5Y20`y'.B01001A.csv"
}

* Define Variables
destring b01001a_001e, g(white)
split geo_id, parse("US")
rename geo_id2 fips
	
* clean up
keep fips year white
order fips year
gsort fips year
merge 1:1 fips year using ../../../DTA/ACS_5yr, nogen
save ../../../DTA/ACS_5yr, replace

***** Hispanic (Table B01001I) ****

* Append all the data
clear
cd "${user}/Data/American Community Survey/Hispanic"
forvalues y = 10/20{
	frame `tframe'{
		unzipfile "ACSDT5Y20`y'.B01001I.zip", replace
		import delimited "ACSDT5Y20`y'.B01001I.csv", varnames(1) rowrang(3:) clear
		keep geo_id b01001i_001e
		g year = 20`y'
		save `temp', replace
	}
	append using `temp'
	cap erase "ACSDT5Y20`y'.B01001I.csv"
}

* Define Variables
destring b01001i_001e, g(hispanic) force
split geo_id, parse("US")
rename geo_id2 fips
	
* clean up
keep fips year hispanic
order fips year
gsort fips year
merge 1:1 fips year using ../../../DTA/ACS_5yr, nogen
save ../../../DTA/ACS_5yr, replace

***** Education (Table S1501) ****

* Append all the data
clear
cd "${user}/Data/American Community Survey/Education"
forvalues y = 10/20{
	frame `tframe'{
		unzipfile "ACSST5Y20`y'.S1501.zip", replace
		import delimited "ACSST5Y20`y'.S1501.csv", varnames(1) rowrang(3:) clear
		keep  geo_id s1501_c01_006e s1501_c01_007e s1501_c01_008e s1501_c01_009e s1501_c01_010e ///
		s1501_c01_011m s1501_c01_012e s1501_c01_013e
		g year = 20`y'
		save `temp', replace
	}
	append using `temp'
	cap erase "ACSST5Y20`y'.S1501.csv"
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
gsort fips year
merge 1:1 fips year using ../../../DTA/ACS_5yr, nogen
save ../../../DTA/ACS_5yr, replace

***** Employment (Table S2301) ****

* Append all the data
clear
cd "${user}/Data/American Community Survey/Employment"
forvalues y = 10/20{
	frame `tframe'{
		unzipfile "ACSST5Y20`y'.S2301.zip", replace
		import delimited "ACSST5Y20`y'.S2301.csv", varnames(1) rowrang(3:) clear
		keep  geo_id s2301_c01_001e s2301_c02_001e s2301_c03_001e s2301_c04_001e s2301_c01_028e
		g year = 20`y'
		save `temp', replace
	}
	append using `temp'
	cap erase "ACSST5Y20`y'.S2301.csv"
}

* Define Variables - Employment
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
gsort fips year
merge 1:1 fips year using ../../../DTA/ACS_5yr, nogen
save ../../../DTA/ACS_5yr, replace

***** Poverty (Table S1701) ****
	
* Append all the data
clear
cd "${user}/Data/American Community Survey/Poverty"
forvalues y = 12/20{
	frame `tframe'{
		unzipfile "ACSST5Y20`y'.S1701.zip", replace
		import delimited "ACSST5Y20`y'.S1701.csv", varnames(1) rowrang(3:) clear
		keep  geo_id s1701_c01_035e s1701_c01_034e s1701_c02_014e s1701_c01_014e
		g year = 20`y'
		save `temp', replace
	}
	append using `temp'
	cap erase "ACSST5Y20`y'.S1701.csv"
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
gsort fips year
merge 1:1 fips year using ../../../DTA/ACS_5yr, nogen
save ../../../DTA/ACS_5yr, replace

***** Clean up ****

* Rename
ds fips year, not
local vars = r(varlist)
foreach v in `vars'{
	rename `v' acs_`v'
}

* Save
compress
gsort fips year
cd "${user}"
save DTA/ACS_5yr, replace









