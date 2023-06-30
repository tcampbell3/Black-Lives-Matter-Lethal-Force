clear all
tempfile temp
tempvar tframe
frame create `tframe'

****** 1) Setup data **********

* Import data
cd "${user}\Data\Law Enforcement Management and Administrative Statistics"
unzipfile "LEMAS 2016 Body Camera", replace
use "ICPSR_37302/DS0001/37302-0001-Data", clear
do "ICPSR_37302/DS0001/37302-0001-Supplemental_syntax.do"
cd "${user}"

****** 2) Define Variables **********

* local agencies
keep if inlist(SAMPTYPE,3) 

* Body cameras
g Q_11_D=1
g dummy = mdy(Q_11_M,Q_11_D,Q_11_Y)
g month_bodycam = mofd(dummy)
format month_bodycam %tm

* Recode variables as zero if agency reports not having body worn cameras
replace month_bodycam= 0 if Q_10A == 2
drop if inlist(month_bodycam,.)

****** 3) Reformat to monthly dataset **********

* Keep what is needed
drop if inlist(ORI9,"") | inlist(month_bodycam,.)
keep ORI9 month_bodycam FINAL

* Collapse into ORI means
gcollapse month_bodycam FINAL [aw=FINAL] , by(ORI9)
replace month_bodycam = . if inlist(month_bodycam,0)

* make monthly panel from 2013-2019
expand 84
bys ORI9: gen year = 2013+ floor((_n-1)/12) 
bys ORI9 year: g month = _n
g dummy1 = 1
g dummy = mdy(month,dummy1,year)
g date = mofd(dummy)
format date %tm

* Fix dummy
g ag_bodycam = date >= month_bodycam & month_bodycam!=.

* Drop according to Kim sample
*drop if month_bodycam < monthly("Jan-14","MY",2050)		// must adopt prior to jan 2014
*drop if date > monthly("June-15","MY",2050) 			// adopters post hune 2015 are control sample

****** 4) Merge monthly police killings **********

merge 1:1 ORI9 date using DTA/agency_monthly_homicides, keep(1 3) nogen
replace homicides =0 if inlist(homicides,.)

****** 5) Protest count **********

*  Merge fips crosswalk
frame `tframe'{
	use DTA/backbone, clear
	keep ORI9 fips ORI7
	drop if inlist(ORI9,"-1","")
	save `temp', replace
}
merge m:1 ORI9 using `temp', nogen keep(1 3)
drop if inlist(ORI7,"-1")
merge m:1 ORI7 year using DTA/Crimes, nogen keep(1 3)
drop if ucr_population <20000 | ucr_population==.
fasterxtile  pop_c=ucr_population, n(10) 

* Merge monthly BLM protests
frame `tframe'{
	use DTA/Protest_Daily, clear
	replace date=mofd(date)
	format date %tm
	gcollapse (sum) protests, by(fips date)
	save `temp', replace
}
merge m:1 fips date using `temp', nogen keep(1 3)

* First protest
bys ORI9: gegen first_protest=min(date) if protest>0 & !inlist(protest,.)
bys ORI9 (first_protest): replace first_protest = first_protest[_n-1] if inlist(first_protest,.)
g treatment = date>=first_protest&!inlist(first_protest,.)
format first_protest %tm
gsort ORI9 date

****** 6) Clean and Save **********

* save file
drop dummy*
gsort ORI9 date
encode ORI9, g(ori9)
compress
save DTA/panel_bodycam_monthly, replace

* Stack
sum first_protest
local first=r(min)
local last=r(max)
tempvar stack
local j=1
forvalues i=`first'/`last'{
	cap frame drop `stack'
	frame put if inlist(first_protest,., `i'), into(`stack')
	frame `stack'{
		g cohort=`j'
		g etime=date-`i'
		save `temp', replace
	}
	if `i' == `first'{
		frame `tframe': use `temp', clear
	}
	else{
		frame `tframe': append using `temp'
	}
	local j=`j'+1
}
frame `tframe': save `temp', replace
use `temp', clear
order cohort ORI9 etime

* Drop pretreatment data to balance stacks
drop if etime<-19

* Delete unused directory to save memory
sleep 5000
shell rmdir "Data/Law Enforcement Management and Administrative Statistics/ICPSR_37302" /s /q
cap rmdir "Data/Law Enforcement Management and Administrative Statistics/ICPSR_37302"


bys cohort: gegen test_pre=min(etime)
bys cohort: gegen test_post=max(etime)
drop if test_post< 18 | etime>18

local j=1
bys cohort ORI9: gegen treated=max(treatment)
forvalues i = -4/3{
	g t_`j'= etime>=(`i')*12 & etime<(`i'+1)*12 & inlist(treated,1)
	local j=`j'+1
}
