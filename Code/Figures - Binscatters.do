use DTA/stacked, clear

* Averages references in the text
sum homicides [aw=_wt_unit] if treated==1 & time<0
sum homicides [aw=_wt_unit] if treated==1 & time>=0
sum homicides [aw=_wt_unit] if treated==0 & time<0
sum homicides [aw=_wt_unit] if treated==0 & time>=0


* Aggregate in means by treatment status and event time
g count=1
replace time=floor(time/4)
gcollapse (rawsum) count (mean) homicides [aw=_wt_unit],by(event treated time)
replace count=. if inlist(treated,0)
bys event (count): replace count=count[_n-1] if inlist(count,.)
gcollapse (mean) homicides [aw=count],by(treated time)

* Four lines of best fit
reg homicides time if inlist(treated,1) & time<0
local b1_1=_b[time]
local b0_1=_b[_cons]
reg homicides time if inlist(treated,0) & time<0
local b1_2=_b[time]
local b0_2=_b[_cons]
reg homicides time if inlist(treated,1) & time>=0
local b1_3=_b[time]
local b0_3=_b[_cons]
reg homicides time if inlist(treated,0) & time>=0
local b1_4=_b[time]
local b0_4=_b[_cons]

* Figure
twoway 	function y = `b0_1'+`b1_1'*x, range(-5.1 -.5) lp(solid) lc(maroon) || 	///
		function y = `b0_2'+`b1_2'*x, range(-5.1 -.5) lp(solid) lc(navy) ||	///
		function y = `b0_3'+`b1_3'*x, range(-.5 4.1) lp(solid) lc(maroon)  ||	///
		function y = `b0_4'+`b1_4'*x, range(-.5 4.1) lp(solid) lc(navy)  ||	///
		scatter homicides time if inlist(treated,1), m(0) mc(maroon) || 	///
		scatter homicides time if inlist(treated,0), m(0) mc(navy) ||	///
		, xline(-.5) xlab(-5(1)4, labs(large)) ylabel(0(.1).7,labs(large)) scheme(plotplain)	///
		xtitle("Years relative to start of protests",size(large)) 			///
		ytitle("Binned-averaged police homicides",size(large)) 	xsize(7)			///
		legend(size(large) order(1 "Early BLM protests" 2 "Late BLM protests") pos(1) region(color(none)) ring(0))
graph export "Output/Raw_levels_stacked.pdf", replace