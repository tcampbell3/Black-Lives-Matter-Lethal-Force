clear all
tempfile temp
tempvar tframe
cd "${user}"

* Contiguous county list
use "DTA/Counties", clear
keep fips_c popest qtr protests homicides county stabb
gduplicates drop
save `temp',replace

* Contiguous county pairs
use "DTA/Counties", clear
keep fips* qtr
gsort fipscounty fips_c qtr
drop if inlist(fipscounty,fips_c)
gegen pair = group(fipscounty fips_c)
rename fipscounty fips_c1
rename fips_c fips_c2
g i=_n
greshape long fips_c, i(i) j(pairid)
keep pair fips_c qtr
merge m:1 fips_c qtr using `temp', nogen
destring fips_c, replace
rename fips_c fips

* Drop duplicate pairs
bys pair: gegen test1=max(fips)
bys pair: gegen test2=min(fips)
gegen test3 = group(test1 test2)
bys test3: gegen test4 = max(pair)
bys test3: gegen test5 = min(pair)
drop if inlist(pair, test4)  & !inlist(test4,test5)
drop  test*

* Drop post covid data
drop if qtr>20201

* Drop pairs without treated group or control group
bys pair fips: egen total_protests = sum(protests)
gen treated=(total_protests>=1)
bys pair: gegen test1=max(treated)
bys pair: gegen test2=min(treated)
keep if inlist(test1,1) & inlist(test2,0)
drop test* total_protests

* Event time
gegen dummy_time = group(qtr)
bys fips: gegen dummy = min(dummy_time) if protests>0 & !inlist(protest,.)
bys pair (dummy): replace dummy = dummy[_n-1] if inlist(dummy,.)
g time=dummy_time - dummy
drop dummy*
drop if floor(time/4)>=${post} | floor(time/4)<-${pre}
g treatment = time>=0 & inlist(treated,1)

* Pretreatment dummies
forvalues i=2/$pre {
	gen t_pre`i'=inlist(treated,1) & (time >= -`i'*4 & time < -(`i'-1)*4)
}

* Posttreatment dummies
forvalues i=1/$post {
	local j=`i'-1
	gen t_post`j'=inlist(treated,1) & (time >= `j'*4 & time < (`j'+1)*4)
}

* Drop pairs without full data
bys pair: g test=_N
sum test,meanonly
drop if test<r(max)
drop test

* Reindex pairs
gegen _pair=group(pair)
drop pair
rename _pair pair
order pair fips time qtr treated treatment
gsort pair - treated + qtr 

* Save
fasterxtile pop_c=popest,n(10)
compress
save DTA/contiguous_counties, replace