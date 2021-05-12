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

*******************************************************************************/


* Set up
clear all
clear matrix
clear mata
macro drop _all 
set maxvar 20000
global user = "C:/Users/travi/Dropbox/Police Killings"
cd "${user}"

/* Create github datasets (github datasets must be split into pieces < 25 mb)
do "Do Files/github datasets" 
*/

*******************************************************
	// 1) Create Individual Datasets (run in order)
*******************************************************

***** Agnecy level datasets ****
/*
* AGENCY BACKBONE - Law Enforcement Agency Identifiers Crosswalk
do "Do Files/1 - Law Enforcement Agency Identifiers Crosswalk" 

* Crime	
do "Do Files/1 - Crime" 

* Police agency characteristics
do "Do Files/1 - LEMAS"
do "Do Files/1 - LEMAS Body Worn Camera"

***** City level datasets ****

* CITY BACKBONE - City population
do "Do Files/1 - Population" 

* City demogrpahics and labor market
do "Do Files/1 - American Community Survey" 

* Number of police officers (94 geocodes)
global key="a5459543a82b450d8bd78c45e2107fcc" 	// exires in one month. See https://opencagedata.com/dashboard
do "Do Files/1 - Annuel Survey of Public Employment"

* Black Lives Matter Protests (34 geocodes)
global key="c87eafdd3d884f758ea0933f407fe229" 	// exires in one month. See https://opencagedata.com/dashboard
do "Do Files/1 - Black Lives Matter Protests"

* Police homicides
do "Do Files/1 - Fatal Encounters City Geocode" 

* Police homicides (higher quality data, but smaller timeframe)  (8 geocodes)
global key="c87eafdd3d884f758ea0933f407fe229" 	// exires in one month. See https://opencagedata.com/dashboard
do "Do Files/1 - Mapping Police Violence" 

* Census region and division by state
do "Do Files/1 - Census Region" 

* City size and density	
do "Do Files/1 - Geo Size"

* Number of historical protests and hate crimes in city (1025 geocode)
global key="a5459543a82b450d8bd78c45e2107fcc" 	// exires in one month. See https://opencagedata.com/dashboard
do "Do Files/1 - Protest History"

* Democratic vote share
global key1="04cfc001da6c48d1ad359f5851ac617f" 	// exires in one month. See https://opencagedata.com/dashboard
global key2="6c5215ed09134c98bfbd4a828f171822" 	// exires in one month. See https://opencagedata.com/dashboard
global key3="15e146fc5898447b91279961447215cf" 	// exires in one month. See https://opencagedata.com/dashboard
do "Do Files/1 - Democratic Vote Share" 		// requires crosswalk and opencage API


*******************************************************
	    // 2) Create final data set for analysis
*******************************************************

* 1) Create Summary Dataset
do "Do Files/2 - Full Dataset" 
do "Do Files/2 - Consent Decrees" 
do "Do Files/2 - Agency panel body camera"  
do "Do Files/2 - Agency panel characteristics"  
do "Do Files/2 - Agency panel crime"  // "crime_share" constructed later, float storage > github 25mb

* 2) Create appendix datasets
do "Do Files/Appendix - County dataset.do"
do "Do Files/Appendix - Case studies.do"
do "Do Files/Appendix - Case study daily panel.do"
do "Do Files/Appendix - Stacked Video Dataset.do"
*/

* 3) Create Stacked Dataset <<<<(START REPLICATION EXERCISES HERE)>>>>
do "Do Files/3 - Stacked Dataset"

/* Alternatively, you can append the 4 pieces of the "stacked" dataset on github. 
   However, noncrutial variables like state names etc. will not be included due 
   to github file size restrictions. For all variable, use the above do file. */



********************************
		// 3) Tables
********************************

* Covariate Balance
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/Tables - Covariate Balance.do"

* Benchmark
winexec "C:\Program Files\Stata16\StataMP-64.exe" texdoc do "Do Files/Tables - Benchmark"

* Protest size and frequency
winexec "C:\Program Files\Stata16\StataMP-64.exe" texdoc do "Do Files/Tables - Protests Size and Freq"

* Normalization
winexec "C:\Program Files\Stata16\StataMP-64.exe" texdoc do "Do Files/Tables - Normalization"

* Population Screening
winexec "C:\Program Files\Stata16\StataMP-64.exe" texdoc do "Do Files/Tables - Population Screen"

* Specification
winexec "C:\Program Files\Stata16\StataMP-64.exe" texdoc do "Do Files/Tables - Specification"

* MPV Race
winexec "C:\Program Files\Stata16\StataMP-64.exe" texdoc do "Do Files/Tables - Race"

* Mechanisms
winexec "C:\Program Files\Stata16\StataMP-64.exe" texdoc do "Do Files/Tables - Mechanisms agency"
winexec "C:\Program Files\Stata16\StataMP-64.exe" texdoc do "Do Files/Tables - Mechanisms crime"

********************************
		// 4) Figures
********************************

* Maps
do "Do Files/Figures - Maps.do"

* Raw Bin Scatters
do "Do Files/Figures - Binscatters.do"

* Time variation
do "Do Files/Figures - Timing.do"

* Mechanisms figure
do "Do Files/Figures - Mechanisms.do"

* Figure 1
global outcome = "protests_total"
global absorb = "i.event#i.time i.event#i.FIPS"
global weight = ""
global color = "blue"
global y = "Protests"
global yaxis = "ylabel(0(3)12)"
global pos = 1
global title1 = "Cumulative number of protests"
global title2 = ""
global path=""
do "Do Files/Figures - Event Time Effects.do"

* Figure - ferguson effect
global color1 = "red"
global color2 = "blue"
global color3 = "green"
global yaxis = "ylabel(-.5(.25).5) ymtick(-.5(.05).5) ysc(titlegap(-5))"
global pos = 1
global title1 = "" 
global title2 = ""
global path=""
global cutoff = "19"
global aspect = ".5"
global gap = "-10"			// distance from x axis to top
do "Do Files/Figures - Ferguson Effect 1.do"
do "Do Files/Figures - Ferguson Effect 2.do"

* Figure - Body cameras
global outcome = "ag_bodycam"
global absorb = "event#time event#ori9 event#pop_c##c.ucr_population"
global color = "edkblue"
global y = "% {&Delta} Body cameras"
global yaxis = "ylabel(-.5(.25)1.25) ymtick(-.5(.05)1.25) ysc(titlegap(-5))"
global pos = 5
global title1 = "" 
global title2 = ""
global path=""
do "Do Files/Figures - Body cam.do"
do "Do Files/Figures - Reason for body camera.do"

* Figure - Videos of police homicides
global outcome = "video"
global absorb = "i.event#i.time i.event#i.FIPS event#pop_c##c.popestimate"
global weight = ""
global color = "edkblue"
global y = "% {&Delta} Lethal Force Videos"
global yaxis = "ylabel(-1(1)6) ymtick(-1(.5)6) ysc(titlegap(-5))"
global pos = 11
global title1 = "" 
global title2 = ""
global path=""
do "Do Files/Figures - Event Time Effects.do"

* Figure 1 - Impact of BLM on Police Homicides

	* Figure 1-1 
	global outcome = "homicides"
	global absorb = "i.event#i.time i.event#i.FIPS event#pop_c##c.popestimate"
	global weight = ""
	global color = "green"
	global y = "% {&Delta} Lethal Force"
	global yaxis = "ylabel(-.75(.25).5) ymtick(-.75(.05).5) ysc(titlegap(-5))"
	global pos = 1
	global title1 = "" 
	global title2 = ""
	global path=""
	do "Do Files/Figures - Event Time Effects.do"

	* Figure 1-2
	global outcome = "homicides_p"
	global absorb = "i.event#i.time i.event#i.FIPS event#pop_c##c.popestimate"
	global weight = "popestimate"
	global color = "midblue"
	global y = "% {&Delta} Lethal Force"
	global yaxis = "ylabel(-.75(.25).5) ymtick(-.75(.05).5) ysc(titlegap(-5))"
	global pos = 1
	global title1 = "" 
	global title2 = ""
	global path=""
	do "Do Files/Figures - Event Time Effects.do"
	
	* Figure 1-3
	global outcome = "homicides"
	global absorb = "i.event#i.time i.event#i.FIPS event#pop_c##c.popestimate"
	global weight = "ipw"
	global color = "pink"
	global y = "% {&Delta} Lethal Force"
	global yaxis = "ylabel(-.75(.25).5) ymtick(-.75(.05).5) ysc(titlegap(-5))"
	global pos = 1
	global title1 = "" 
	global title2 = ""
	global path=""
	do "Do Files/Figures - Event Time Effects.do"
	
	* Figure 1-4
	global outcome = "homicides"
	global absorb = "i.event#i.time i.event#i.FIPS event#pop_c##c.popestimate"
	global weight = "ipw_unit_time"
	global color = "orange_red"
	global y = "% {&Delta} Lethal Force"
	global yaxis = "ylabel(-.75(.25).5) ymtick(-.75(.05).5) ysc(titlegap(-5))"
	global pos = 1
	global title1 = "" 
	global title2 = ""
	do "Do Files/Figures - Event Time Effects.do"
	
* Figure 2 - Robustness Check Benchmark - time trends

	* Figure 2-2
	global outcome = "homicides"
	global absorb = "i.event#i.time#i.pop_c i.event#i.FIPS i.event#i.pop_c#c.popestimate"
	global weight = ""
	global color = "midblue"
	global y = "% {&Delta} Lethal Force"
	global yaxis = "ylabel(-.75(.25).5) ymtick(-.75(.05).5) ysc(titlegap(-5))"
	global pos = 1
	global title1 = "" 
	global title2 = ""
	global path="_pop_time"
	do "Do Files/Figures - Event Time Effects.do"
	
	* Figure 2-3
	global outcome = "homicides"
	global absorb = "i.event#i.time event#FIPS##c.time event#pop_c##c.popestimate"
	global weight = ""
	global color = "pink"
	global y = "% {&Delta} Lethal Force"
	global yaxis = "ylabel(-.75(.25).5) ymtick(-.75(.05).5) ysc(titlegap(-5))"
	global pos = 1
	global title1 = "" 
	global title2 = ""
	global path="_linear"
	do "Do Files/Figures - Event Time Effects.do"
	
	* Figure 2-4
	global outcome = "homicides"
	global absorb = "i.event#i.time#i.pop_c event#FIPS##c.time i.event#i.pop_c#c.popestimate"
	global weight = ""
	global color = "orange_red"
	global y = "% {&Delta} Lethal Force"
	global yaxis = "ylabel(-.75(.25).5) ymtick(-.75(.05).5) ysc(titlegap(-5))"
	global pos = 1
	global title1 = "" 
	global title2 = ""
	global path="_pop_time_linear"
	do "Do Files/Figures - Event Time Effects.do"
	
********************************
	   // 5) Appendix
********************************

* County level panel appendix
do "Do Files/Appendix - County figures.do"

* Case study appendix
do "Do Files/Appendix - Case study heterogeneity figure.do"

* Video event study appendix
do "Do Files/Appendix - Video event time figures.do"
do "Do Files/Appendix - Video overall figures.do"