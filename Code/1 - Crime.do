
				**************************
				  // Import Crime Data
				**************************

* Unzip Folder
clear
cd "${user}\Data\Crime"
unzipfile "ucr_offenses_known_yearly_1960_2019_dta", replace
use offenses_known_yearly_1960_2019.dta, clear
cd ../..
erase "Data/Crime/offenses_known_yearly_1960_2019.dta"


				*************************
				  // Clean Crime Data
				*************************

* fips
gen fips=fips_state_code+fips_place_code

* Drop Missing
drop if number_of_months_missing==12

* fix honolulu (not given place until 2010: 1571550)
replace fips = "1571550" if fips=="1517000" 

* Clean crime measures
rename tot_clr_index_property crime_property_clr
rename tot_clr_index_violent crime_violent_clr
rename actual_index_violent crime_violent_rpt
rename actual_index_property crime_property_rpt
rename actual_murder crime_murder_rpt
rename officers_killed_by_felony crime_officer_felony
rename officers_killed_by_accident crime_officer_accident
rename officers_assaulted crime_officer_assaulted
foreach var of varlist crime_* {

	* Bottom code crime indexs at zero
	replace `var' = 0 if `var' < 0
	
	* adjust for missing months
	replace `var'  = `var'*12/(12-number_of_months_missing)
	
}
g crime_share = (crime_property_clr)/(crime_property_rpt)

* save
rename ori ORI7
rename population_1 ucr_population
keep ORI7 year crime* ucr_population
drop if year < 2000
compress
save DTA/Crimes, replace
