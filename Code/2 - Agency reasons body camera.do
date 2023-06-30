* Setup
tempfile temp
tempname tframe
frame create `tframe'

* ORI9 FIPS crosswalk -> Protest count
use DTA/backbone, clear
keep ORI9 fips
gduplicates drop

* Merge bodycam
frame `tframe'{
	use DTA/LEMAS_body_cam, clear
	drop if inlist(Q16M1,.)
	keep ORI9 Q* FINALWEIGHT strata
	gduplicates drop
	save `temp', replace
}
merge m:1 ORI9 using `temp', keep(3) nogen

* Merge BLM protests
frame `tframe'{
	use DTA/protests, clear
	drop if qtr>=20171
	gcollapse (sum) protests, by(fips)
	save `temp', replace
}
merge m:1 fips using `temp', keep(1 3) nogen
replace protests=0 if inlist(protests,.)
g treated=(protests>=1)

* Aggregate
gcollapse (sum) protests (max) treated (mean) Q* weight=FINAL strata, by(ORI9)

* Clean and save
gsort ORI9
compress
save DTA/Agency_reason_bodycam, replace