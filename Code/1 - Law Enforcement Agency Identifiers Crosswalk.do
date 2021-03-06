
* Import dataset
clear all
cd "${user}\Data\Law Enforcement Agency Identifiers Crosswalk"
unzipfile "ICPSR_35158-V2", replace
use "ICPSR_35158/DS0001/35158-0001-Data", clear
cd "${user}"
	
* State name and code
decode FSTATE, gen(stname)
rename FIPS_ST stnum
rename ADDRESS_STATE stabb

* fix typos
replace stabb = "DC" if inlist(stnum, "11")
replace stabb = "IL" if inlist(stnum, "17")
replace stabb = "CT" if inlist(stnum, "09")
replace stabb = "NE" if inlist(stnum, "31")

* City name and code
gen place_fips = string(FPLACE,"%05.0f")
gen fips=stnum+place_fips
rename ADDRESS_CITY city

* Agency
rename NAME agency
decode AGCYTYPE, gen(agency_type)

 * Keep what is needed, collapse into unique city-agency obs
collapse (firstnm) stname stnum stabb city agency_type, by(fips agency ORI*)
order fips agency ORI* agency_type stname city
gsort fips agency ORI*

* Clean up and save										
shell rmdir "Data/Law Enforcement Agency Identifiers Crosswalk/ICPSR_35158" /s /q
cap rmdir "Data/Law Enforcement Agency Identifiers Crosswalk/ICPSR_35158"
compress
save "DTA/Backbone", replace

* State codes
keep stname stnum stabb
duplicates drop
save DTA/statecode, replace