/*******************************************************************************
*************************** Controls variable codes ****************************
********************************************************************************

ag_			Police agency characteristics
crime_ 		City crime statistics
acs_		City demographics and labor market indicators from ACS 
geo_		Geograpic controls
pol_		Political party vote shares in 2008 election
h_			Historical protests and hate crimes
consent_	Consent decree indicators
tweet_ 		Police related twitter data

*******************************************************************************/

* Set up
clear all
clear matrix
clear mata
macro drop _all 
set maxvar 20000
global user = "C:/Users/travi/Dropbox/BLM Lethal Force"
cd "${user}"

*******************************************************
 // 1) Create Individual Datasets (Last run: 8/12/2022)
*******************************************************

/***** Agnecy level datasets ****

* AGENCY BACKBONE - Law Enforcement Agency Identifiers Crosswalk
do "Do Files/1 - Law Enforcement Agency Identifiers Crosswalk" 					// Updated

* Crime	
do "Do Files/1 - Crime"															// Updated

* Twitter
do "Do Files/1 - Twitter"														// Updated

* Police agency characteristics
do "Do Files/1 - LEMAS"															// Updated
do "Do Files/1 - LEMAS Body Worn Camera"										// Updated

***** City level datasets ****

* CITY BACKBONE - City population
do "Do Files/1 - Population" 													// Updated

* Black Lives Matter Protests
do "Do Files/1 - Black Lives Matter Protests"									// Updated

* City demogrpahics and labor market
do "Do Files/1 - American Community Survey"										// Updated 

* Number of police officers (Requires MapQuest API key)
global key="" 		
do "Do Files/1 - Annuel Survey of Public Employment"							// Updated

* Police homicides
do "Do Files/1 - Fatal Encounters" 												// Updated

* Police homicides (higher quality data, but smaller timeframe)
do "Do Files/1 - Mapping Police Violence" 										// Updated

* Census region and division by state
do "Do Files/1 - Census Region" 												// Updated

* City size and density	
do "Do Files/1 - Geo Size"														// Updated

* Number of historical protests and hate crimes in city (1025 geocode)
global key="" 	// exires in one month. See https://opencagedata.com/dashboard
do "Do Files/1 - Protest History"

* Democratic vote share
global key1="" 	// exires in one month. See https://opencagedata.com/dashboard
global key2="" 	// exires in one month. See https://opencagedata.com/dashboard
global key3="" 	// exires in one month. See https://opencagedata.com/dashboard
do "Do Files/1 - Democratic Vote Share" 		// requires crosswalk and opencage API

*******************************************************
	    // 2) Create final data set for analysis
*******************************************************

* 1) Create main datasets
do "Do Files/2 - Full Dataset" 											
do "Do Files/2 - Consent Decrees" 										
do "Do Files/2 - Agency panel body camera"  							
do "Do Files/2 - Agency reasons body camera"  							
do "Do Files/2 - Agency panel characteristics"  						
do "Do Files/2 - Agency panel crime"  									

* 2) Create appendix datasets
do "Do Files/Appendix - County dataset.do"									
do "Do Files/Appendix - Case studies.do"									
do "Do Files/Appendix - Twitter panel"  									
do "Do Files/Appendix - Solidarity protest panel"  						

* 3) Create stacked datasets
global pre=5																	// Pretreatment years in e-window
global post=5																	// Posttreatment years in e-window
do "Do Files/3 - Stacked Dataset"												
do "Do Files/3 - Contiguous counties"											
do "Do Files/3 - Stacked counties"												
forvalues c=100000(25000)200000{
	winexec "C:\Program Files\Stata17\StataMP-64.exe" do "Do Files/3 - Low population stack" `c'
}

*/

********************************
		// 3) Tables
********************************

/*   <<<<(START REPLICATION EXERCISES HERE)>>>>		*/

* Covariate Balance
winexec "C:\Program Files\Stata17\StataMP-64.exe" do "Do Files/Tables - Covariate Balance.do"

* Protest size and frequency
winexec "C:\Program Files\Stata17\StataMP-64.exe" do "Do Files/Tables - Protests Size and Freq"

* MPV Race
winexec "C:\Program Files\Stata17\StataMP-64.exe" do "Do Files/Tables - Race"

* Estimator
winexec "C:\Program Files\Stata17\StataMP-64.exe" do "Do Files/Tables - Estimator"

* Normalization
winexec "C:\Program Files\Stata17\StataMP-64.exe" do "Do Files/Tables - Normalization"

* Population Screening
winexec "C:\Program Files\Stata17\StataMP-64.exe" do "Do Files/Tables - Population Screen"

* Specification
winexec "C:\Program Files\Stata17\StataMP-64.exe" do "Do Files/Tables - Specification"

* Mechanisms
winexec "C:\Program Files\Stata17\StataMP-64.exe" do "Do Files/Tables - Mechanisms agency"
winexec "C:\Program Files\Stata17\StataMP-64.exe" do "Do Files/Tables - Mechanisms crime"

* Scaling protest
winexec "C:\Program Files\Stata17\StataMP-64.exe" do "Do Files/Tables - Cumulative protests"

* Twitter
winexec "C:\Program Files\Stata17\StataMP-64.exe" do "Do Files/Appendix - Twitter table.do"


********************************
		// 4) Figures
********************************

* Maps
do "Do Files/Figures - Maps.do"

* Bin Scatters
do "Do Files/Figures - Binscatters.do"

* Time variation
do "Do Files/Figures - Timing.do"

* Figure - Cumulative number of protests
global absorb = "event#time event#fips"
global color = "blue"
global y = "Protests"
global yaxis = "ylabel(0(2)12, labsize(large))"
global pos = 11
global title = "Cumulative number of protests"
do "Do Files/Figures - Cumulative protests.do"

* Figure - Ferguson effect
global color1 = "red"
global color2 = "blue"
global color3 = "green"
global yaxis = "ylabel(-50(10)40, labsize(large)) ymtick(-50(5)40) ysc(titlegap(-5))"
global title1 = "" 
global title2 = ""
global path=""
global cutoff = "19"
global aspect = ".5"
global gap = "-10"	
global pos = 5
do "Do Files/Figures - Ferguson Effect 1.do"
global pos = 1
do "Do Files/Figures - Ferguson Effect 2.do"

* Figure - Body cameras
global outcome = "ag_bodycam"
global absorb = "event#time event#ori9 event#pop_c##c.popu"
global color = "edkblue"
global y = "% {&Delta} Body cameras"
global yaxis = "ylabel(-50(25)150, labsize(large)) ymtick(-50(5)150) ysc(titlegap())"
global pos = 11
global title1 = "% {&Delta} Agencies with police body cameras" 
global title2 = ""
do "Do Files/Figures - Body cam.do"

* Figure - Reasons for body cam
do "Do Files/Figures - Reason for body camera.do"

* Figure - Impact of BLM on police homicides 
global outcome = "homicides"
global absorb = "event#time event#fips event#pop_c##c.popestimate"
global weight = "[aw=_wt_unit]"
global color = "midblue"
global y = "% {&Delta} Lethal Force"
global yaxis = "ylabel(-45(15)30, labsize(large)) ymtick(-45(5)30) ysc(titlegap())"
global pos = 1
global title = "% {&Delta} Lethal force by police" 
global path="estudy_homicides"
global sample="Stacked"
do "Do Files/Figures - Event Time Effects.do"

	
********************************
	 // 5) Appendix B - D
********************************

* Figure - Videos of police homicides
global outcome = "video"
global absorb = "event#time event#fips event#pop_c##c.popestimate"
global weight = ""
global color = "red"
global y = "% {&Delta} Videos"
global yaxis = "ylabel(-200(100)600, labsize(large)) ymtick(-200(50)600) ysc(titlegap())"
global pos = 11
global title = `"% {&Delta} Video recordings of lethal force" "by police"'
global path="estudy_video"
global sample="Stacked"
do "Do Files/Figures - Event Time Effects.do"

* Figure - Condition on police killing before protest
global color = "dkgreen"
global y = "% {&Delta} Lethal Force"
global yaxis = "ylabel(-45(15)30, labsize(large)) ymtick(-45(5)30) ysc(titlegap())"
global pos = 1
global title = "% {&Delta} Lethal force by police" 
do "Do Files/Figures - Event study conditional on killing"

* Figure - Binary outcome
global color = "purple"
global y = "Overall effect"
global yaxis = "ylabel(-12(3)6, labsize(large)) ymtick(-12(3)6) ysc(titlegap())"
global pos = 1
global title = "Percentage point change in any lethal force" 
do "Do Files/Figures - Event study binary outcome.do"

* Figure - LEMAS sample
global color = "blue"
global y = "% {&Delta} Lethal Force"
global yaxis = "ylabel(-45(15)30, labsize(large)) ymtick(-45(5)30) ysc(titlegap())"
global pos = 1
global title = "% {&Delta} Lethal force by police" 
do "Do Files/Figures - LEMAS body cam sample.do"

* Low population cities - Covariate balance
winexec "C:\Program Files\Stata17\StataMP-64.exe" do "Do Files/Appendix - Low Pop Covariate Balance.do"

* Low population cities - Robustness to threshold
winexec "C:\Program Files\Stata17\StataMP-64.exe" do "Do Files/Appendix - Low Pop Threshold.do"

* Low population cities - Dynamic treatment effect plot
global outcome = "homicides"
global absorb = "event#time event#fips event#pop_c##c.popestimate"
global weight = "[aw=ipw]"
global color = "midblue"
global y = "% {&Delta} Lethal Force"
global yaxis = "ylabel(-100(25)100, labsize(large)) ymtick(-100(12.5)100) ysc(titlegap())"
global pos = 1
global title = "% {&Delta} Lethal force by police" 
global path="estudy_low_pop"
global sample="stacked_pop_150000"
do "Do Files/Figures - Event Time Effects.do"

* Counties - Contiguous county map
do "Do Files/Appendix - County maps.do"

* Counties - Event study plot (synth)
global outcome = "homicides"
global absorb = "event#time event#fips event#pop_c##c.popestimate"
global weight = "[aw=_wt_unit]"
global color = "midblue"
global y = "% {&Delta} Lethal Force"
global yaxis = "ylabel(-45(15)30, labsize(large)) ymtick(-45(5)30) ysc(titlegap())"
global pos = 1
global title = "% {&Delta} Lethal force by police" 
global path="estudy_counties"
global sample="Stacked_counties"
do "Do Files/Figures - Event Time Effects.do"

* Counties - Event study plot (contiguous)
global outcome = "homicides"
global absorb = "pair#time pair#fips pop_c#c.popestimate"
global weight = ""
global color = "orange_red"
global y = "% {&Delta} Lethal Force"
global yaxis = "ylabel(-45(15)30, labsize(large)) ymtick(-45(5)30) ysc(titlegap())"
global pos = 1
global title = "% {&Delta} Lethal force by police" 
global path="estudy_contiguous"
global sample="contiguous_counties"
do "Do Files/Figures - Event Time Effects.do" "contiguous"

* Solidarity protests
global outcome = "homicides"
global absorb = "event#time event#fips event#pop_c##c.popestimate"
global weight = "[aw=_wt_unit]"
global color = "midblue"
global y = "% {&Delta} Lethal Force"
global yaxis = "ylabel(-45(15)30, labsize(large)) ymtick(-45(5)30) ysc(titlegap())"
global pos = 1
global title = "% {&Delta} Lethal force by police" 
global path="estudy_solidarity"
global sample="Solidarity"
do "Do Files/Figures - Event Time Effects.do"
