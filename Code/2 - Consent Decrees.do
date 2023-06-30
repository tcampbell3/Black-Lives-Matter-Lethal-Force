use DTA/Summary, clear

/* Define variables from source: https://www.justice.gov/crt/page/file/922456/download  (download 3/12/2020)

Consent Decrees occure in three stages:
1) Investigation begins (only counted if something was found)
2) Problematic pattern is identified (sometimes missing)
3) Court ordered consent decree or memorandum of agreement (MOA)

This dofile creates an indicator for each stage of process for places that are eventually given a consent decree. 
*/

* Investigation
cap drop consent_decree1
g consent_decree1 = 0

* Identified Problem
cap drop consent_decree2
g consent_decree2 = 0

* Consent Decree or MOA
cap drop consent_decree3
g consent_decree3=0


/*	Omitt Baltimore and Ferguson since caused by BLM	*/

* Yonkers
replace consent_decree1 = 1 if  city=="Yonkers city" & stabb=="NY" & qtr >= 20073 // August 2007
replace consent_decree2 = 1 if  city=="Yonkers city" & stabb=="NY" & qtr >= 20092 // June
replace consent_decree3 = 1 if  city=="Yonkers city" & stabb=="NY" & qtr >= 20164 // Novemeber

* Alamance county (sheriff office in Graham)
replace consent_decree1 = 1 if city=="Graham city" & stabb=="NC" & qtr >= 20102 // June 2010
replace consent_decree2 = 1 if city=="Graham city" & stabb=="NC" & qtr >= 20123 // September
replace consent_decree3 = 1 if city=="Graham city" & stabb=="NC" & qtr >= 20163 //  August

* Newark 
replace consent_decree1 = 1 if city=="Newark city" & stabb=="NJ" & qtr >= 20112 // May 2011
replace consent_decree2 = 1 if city=="Newark city" & stabb=="NJ" & qtr >= 20143 // July
replace consent_decree3 = 1 if city=="Newark city" & stabb=="NJ" & qtr >= 20162 //  April

* Miami
replace consent_decree1 = 1 if city=="Miami city" & stabb=="FL" & qtr >= 20114 // November 2011
replace consent_decree2 = 1 if city=="Miami city" & stabb=="FL" & qtr >= 20133 // July
replace consent_decree3 = 1 if city=="Miami city" & stabb=="FL" & qtr >= 20161 //  February

* Meridian
replace consent_decree1 = 1 if city=="Meridian city" & stabb=="MS" & qtr >= 20114 // December 2011
replace consent_decree2 = 1 if city=="Meridian city" & stabb=="MS" & qtr >= 20123 // August
replace consent_decree3 = 1 if city=="Meridian city" & stabb=="MS" & qtr >= 20153 //  September

* Maricopa County (sheriff office in Pheonix)
replace consent_decree1 = 1 if city=="Phoenix city" & stabb=="AZ" & qtr >= 20091 // March 2009
replace consent_decree2 = 1 if city=="Phoenix city" & stabb=="AZ" & qtr >= 20114 // December
replace consent_decree3 = 1 if city=="Phoenix city" & stabb=="AZ" & qtr >= 20153 //  July

* Cleveland
replace consent_decree1 = 1 if city=="Cleveland city" & stabb=="OH" & qtr >= 20003 // August 2000
replace consent_decree2 = 1 if city=="Cleveland city" & stabb=="OH" & qtr >= 20144 // December
replace consent_decree3 = 1 if city=="Cleveland city" & stabb=="OH" & qtr >= 20152 //  June

* Albuquerque
replace consent_decree1 = 1 if city=="Albuquerque city" & stabb=="NM" & qtr >= 20124 // November 2012
replace consent_decree2 = 1 if city=="Albuquerque city" & stabb=="NM" & qtr >= 20142 // April
replace consent_decree3 = 1 if city=="Albuquerque city" & stabb=="NM" & qtr >= 20144 //  "Late"

* Los Angeles County #1 (Palmdale)
replace consent_decree1 = 1 if city=="Palmdale city" & stabb=="CA" & qtr >= 20113 // August 2011
replace consent_decree2 = 1 if city=="Palmdale city" & stabb=="CA" & qtr >= 20132 // June
replace consent_decree3 = 1 if city=="Palmdale city" & stabb=="CA" & qtr >= 20162 //  May

* Los Angeles County #2 (Lancaster)
replace consent_decree1 = 1 if city=="Lancaster city" & stabb=="CA" & qtr >= 20113 // August 2011
replace consent_decree2 = 1 if city=="Lancaster city" & stabb=="CA" & qtr >= 20132 // June
replace consent_decree3 = 1 if city=="Lancaster city" & stabb=="CA" & qtr >= 20162 //  May

* Portland
replace consent_decree1 = 1 if city=="Portland city" & stabb=="OR" & qtr >= 20112 // June 2011
replace consent_decree2 = 1 if city=="Portland city" & stabb=="OR" & qtr >= 20123 // September
replace consent_decree3 = 1 if city=="Portland city" & stabb=="OR" & qtr >= 20124 //  2012

* Missoula
replace consent_decree1 = 1 if city=="Missoula city" & stabb=="MT" & qtr >= 20122 //  May 2012
replace consent_decree2 = 1 if city=="Missoula city" & stabb=="MT" & qtr >= 20132 // May
replace consent_decree3 = 1 if city=="Missoula city" & stabb=="MT" & qtr >= 20132 //  May

* Suffolk County

* New Orleans
replace consent_decree1 = 1 if city=="New Orleans city" & stabb=="LA" & qtr >= 20102 // May 2010
replace consent_decree2 = 1 if city=="New Orleans city" & stabb=="LA" & qtr >= 20111 // March
replace consent_decree3 = 1 if city=="New Orleans city" & stabb=="LA" & qtr >= 20131 //  January

* East Haven CT (not in population data?)

* Seattle
replace consent_decree1 = 1 if city=="Seattle city" & stabb=="WA" & qtr >= 20111 // March 2011
replace consent_decree2 = 1 if city=="Seattle city" & stabb=="WA" & qtr >= 20114 // December
replace consent_decree3 = 1 if city=="Seattle city" & stabb=="WA" & qtr >= 20123 //  September

* Beacon
replace consent_decree1 = 1 if city=="Beacon city" & stabb=="NY" & qtr >= 20052 // June 2005
replace consent_decree3 = 1 if city=="Beacon city" & stabb=="NY" & qtr >= 20103 & qtr <= 20163 //  September 2010 - august 2016

* Warren
replace consent_decree1 = 1 if city=="Seattle city" & stabb=="WA" & qtr >= 20044 // December 2004 
replace consent_decree3 = 1 if city=="Seattle city" & stabb=="WA" & qtr >= 20121 //  January

* Orange County (sheriff office in Orlando)
replace consent_decree1 = 1 if city=="Orlando city" & stabb=="FL" & qtr >= 20071 // January 2007
replace consent_decree2 = 1 if city=="Orlando city" & stabb=="FL" & qtr >= 20083 // August
replace consent_decree3 = 1 if city=="Orlando city" & stabb=="FL" & qtr >= 20103 & qtr <= 20132 //  September 2010 - April 2013

* Easton
replace consent_decree1 = 1 if city=="Easton city" & stabb=="PA" & qtr >= 20054 // October 2005
replace consent_decree3 = 1 if city=="Easton city" & stabb=="PA" & qtr >= 20103 & qtr <= 20153 //  August 2010 - July 2015

* Prince George’s County (located Landover)

* Villa Rica
replace consent_decree1 = 1 if city=="Villa Rica city" & stabb=="GA" & qtr >= 20031 // January 2003
replace consent_decree3 = 1 if city=="Villa Rica city" & stabb=="GA" & qtr >= 20034 & qtr <= 20063 //  December 2003 - December 2006

* Detriot
replace consent_decree1 = 1 if city=="Detriot city" & stabb=="MI" & qtr >= 20012 // May 2001
replace consent_decree2 = 1 if city=="Detriot city" & stabb=="MI" & qtr >= 20021 // March
replace consent_decree3 = 1 if city=="Detriot city" & stabb=="MI" & qtr >= 20033 & qtr <= 20161 //  July 2003 - March 2016

* Mount Prospect
replace consent_decree1 = 1 if city=="Mount Prospect village" & stabb=="IL" & qtr >= 20002 // April 2000
replace consent_decree3 = 1 if city=="Mount Prospect village" & stabb=="IL" & qtr >= 20031 & qtr <= 20064 //   2003 - December 2006

* Columbus
replace consent_decree1 = 1 if city=="Columbus city" & stabb=="OH" & qtr >= 19981 // March 1998
replace consent_decree2 = 1 if city=="Columbus city" & stabb=="OH" & qtr >= 20001
replace consent_decree3 = 1 if city=="Columbus city" & stabb=="OH" & qtr >= 20021 & qtr <= 20042 //  2002 - May 2004

* Buffalo
replace consent_decree1 = 1 if city=="Buffalo city" & stabb=="NY" & qtr >= 19974 //  December 1997
replace consent_decree3 = 1 if city=="Buffalo city" & stabb=="NY" & qtr >= 20021 & qtr <= 20082 //  2002 - July 2008

* Cincinnati
replace consent_decree1 = 1 if city=="Cincinnati city" & stabb=="OH" & qtr >= 20012 // May 2001
replace consent_decree2 = 1 if city=="Cincinnati city" & stabb=="OH" & qtr >= 20014 // October
replace consent_decree3 = 1 if city=="Cincinnati city" & stabb=="OH" & qtr >= 20022 & qtr <= 20083 // April 2002 - August 2008

* Washington DC
replace consent_decree1 = 1 if city=="Washington city" & stabb=="DC" & qtr >= 19911 // February 1999
replace consent_decree2 = 1 if city=="Washington city" & stabb=="DC" & qtr >= 20012 // June 2001
replace consent_decree3 = 1 if city=="Washington city" & stabb=="DC" & qtr >= 20012 & qtr <= 20121 // Not specified - February 2012

* Highland Park
replace consent_decree1 = 1 if city=="Highland Park city" & stabb=="IL" & qtr >= 20002 // May 2000
replace consent_decree3 = 1 if city=="Highland Park city" & stabb=="IL" & qtr >= 20003 & qtr <= 20044 // Fall 2000 - December 2004

* Los Angeles
replace consent_decree1 = 1 if city=="Los Angeles city" & stabb=="CA" & qtr >= 19963 // July 1996
replace consent_decree2 = 1 if city=="Los Angeles city" & stabb=="CA" & qtr >= 20002 // May 2000
replace consent_decree3 = 1 if city=="Los Angeles city" & stabb=="CA" & qtr >= 20014 & qtr <= 20132 // November 2001 - May 2013

* Montgomery County Police Department (located in Gaithersburg)
replace consent_decree1 = 1 if city=="Gaithersburg city" & stabb=="MD" & qtr >= 19962 // June 1996
replace consent_decree3 = 1 if city=="Gaithersburg city" & stabb=="MD" & qtr >= 200021 & qtr <= 20051 // 2002 - February 2005

* New Jersey State Police
replace consent_decree1 = 1 if stabb=="NJ" & qtr >= 19962  // April 1996
replace consent_decree2 = 1 if stabb=="NJ" & qtr >= 19994  // December
replace consent_decree3 = 1 if stabb=="NJ" & qtr >= 19994 & qtr <= 20094 // December 1999 - October 2009

* Steubenville
replace consent_decree1 = 1 if city=="Steubenville city" & stabb=="OH" & qtr >= 19963 // September 1996
replace consent_decree2 = 1 if city=="Steubenville city" & stabb=="OH" & qtr >= 19972 // June 1997
replace consent_decree3 = 1 if city=="Steubenville city" & stabb=="OH" & qtr >= 19973 & qtr <= 20051 // September 1997 - March 2005

* Pittsburgh
replace consent_decree1 = 1 if city=="Steubenville city" & stabb=="OH" & qtr >= 19962 // April 1996
replace consent_decree2 = 1 if city=="Steubenville city" & stabb=="OH" & qtr >= 19971 // January 1997
replace consent_decree3 = 1 if city=="Steubenville city" & stabb=="OH" & qtr >= 19972 & qtr <= 20054 // April 1997 - 2005

* Clean and save
replace consent_decree1 = 0 if consent_decree3 == 1 | consent_decree2 == 1
replace consent_decree2 = 0 if consent_decree3 == 1
save DTA/Summary, replace
