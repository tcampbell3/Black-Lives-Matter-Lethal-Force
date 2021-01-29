
import excel "Data\Geography\Census Region.xlsx", sheet("CODES14") cellrange(A6:D70) firstrow clear

*destring to numeric
foreach var in Region Division{
	destring `var', replace
}
destring StateFIPS, gen(stfips)

* generate labels
bys Region (Division stfips): replace Name=Name[_n-1] if stfips!=0
rename Name division
gen region = division
bys Region (Division): replace region=region[_n-1] if Division!=0

* drop headers
drop if Division ==0 | stfips ==0 

* label region and division
labmask Division, values(division)
labmask Region, values(region)

* stnum
g stnum = string(stfips,"%02.0f")

* clean up
keep stnum Region Division
rename Region region
rename Division division
merge 1:1 stnum using DTA/statecode, nogen
order stnum
compress
save "DTA\census_region.dta", replace