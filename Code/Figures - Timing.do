
* Open summary data
use DTA/Summary, clear

* Count new events by qtr
bys fips: egen start = min(qtr) if treatment==1
g new_event = start == qtr
collapse (sum) new_event, by(qtr)
g time = round(qtr/10) + (qtr-round(qtr/10)*10-1)/4

*** Figure ****
twoway (line new_event time, color(midblue%60)  yline(0, lp(solid)))	///
	(scatter new_event time, mc(midblue%80) ms(O) msize(small) scheme(plotplain)),	///
	ytitle("Number of places with first protest", size(medlarge)) legend(off) ylabel(0(25)100, labsize(medium)) ///
	xtitle("") xsize(8) xline(2014.5, lc(red%60)) xlabel(2000(5)2015 2019, labsize(medium))
graph export "${user}/Output/Timing.pdf", replace

