
* Open summary data
use DTA/Summary, clear

* Count new events by qtr
bys fips: egen start = min(qtr) if treatment==1
g new_event = start == qtr
replace protests=1 if protests>1
collapse (sum) new_event protests, by(qtr)
g time = round(qtr/10) + (qtr-round(qtr/10)*10-1)/4
drop if time<2010

*** Figure ****
twoway (line new_event time, color(midblue%50)  lp(solid) sort)	///
	(scatter new_event time, mc(midblue%60) ms(O) msize(small))	///
	(line protests time, color(dkgreen%50) lp(solid) sort)	///
	(scatter protests time, mc(dkgreen%60) ms(O) msize(small) scheme(plotplain)),	///
	ytitle("Number of census places", size(vlarge)) legend(order(1 "Places with first protest" 3 "Places with protest") size(large) pos(6)) ///
	ylabel(0(100)1200, labsize(large)) xtitle("") xsize(8) xline(2014.5, lc(red%75)) xlabel(2010(1)2022, labsize(large))
graph export "${user}/Output/Timing.pdf", replace


twoway (line new_event time, color(midblue%50)  lp(solid) sort)	///
	(scatter new_event time, mc(midblue%60) ms(O) msize(small) scheme(plotplain)),	///
	ytitle("Number of census places", size(vlarge)) legend(order(1 "Places with first protest") size(large) pos(6)) ///
	ylabel(0(100)1200, labsize(large)) xtitle("") xsize(8) xline(2014.5, lc(red%75)) xlabel(2010(1)2022, labsize(large))
graph export "${user}/Output/Timing_oneline.pdf", replace
