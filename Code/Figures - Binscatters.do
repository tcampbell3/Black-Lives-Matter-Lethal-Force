use DTA/summary, clear
g _time=year+((qtr-year*10)-1)*25/100

binscatter homicides_p _time [aw=popest], by(treated) rd(2014.75) scheme(lean2 )  xtitle("Year",size(medlarge)) ytitle("Binned-averaged police homicides",size(medlarge)) legend(size(medsmall) order(2 "One or more protests" 1 "No protests"))
graph export Output/homicides_p/Raw_levels.pdf, replace

binscatter homicides _time, by(treated) rd(2014.75)  scheme(lean2 ) xtitle("Year",size(medlarge)) ytitle("Binned-averaged police homicides",size(medlarge)) legend(size(medsmall) order(2 "One or more protests" 1 "No protests")) 
graph export Output/homicides/Raw_levels.pdf, replace