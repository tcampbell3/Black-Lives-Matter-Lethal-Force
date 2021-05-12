
import delimited "Data\BLM Protests\protests_scrape.csv", varnames(1) clear 
duplicates drop

// Remove Sport and Political Protests
	split subject, parse("| ")
	local subjects = r(varlist)
	foreach s in `subjects'{
	
		drop if `s' == "National Anthem"
		drop if `s' == "Donald Trump"
		drop if `s' == "NFL"
		drop if `s' == "Trump"
		drop if `s' == "Neo-Nazism"
		drop if `s' == "Milo Yiannopoulos"
		drop if `s' == "Minimum Wage"
		drop if `s' == "Confederate Symbols"
		drop if `s' == "Confederacy"
		drop if `s' == "Ben Shapiro"
		drop if `s' == "Bill Clinton"
		drop if `s' == "Hillary Clinton"
		drop if `s' == "White Nationalism"
		
	}
	drop `subjects'
	
// Remove Non-In-Person Meetings, Sport and Political Protests
	split desc, parse(" " "|")
	local descs = r(varlist)
	foreach s in `descs'{
	
		drop if `s' == "WNBA's"
		drop if `s' == "WNBA"
		drop if `s' == "NFL"
		drop if `s' == "basketball"
		drop if `s' == "anthem"
		drop if `s' == "boycott"
	}
	drop `descs'


// State
	split location, parse("| ")
	rename location3 stabb
	replace stabb=location2 if stabb==""
	
// delete all nonstates, identified by having more than 2 characters. These are outside of the USA.
	cap drop test
	gen test = strlen(stabb)
	drop if test>2
	
// City
	rename location2 city
	cap drop test
	gen test = strlen(city)
	replace city = location1 if test==2
	replace city = subinstr(city, "|", "",.) 

// Participants (popnum)
	g popnum=.
	split participants, parse("-" " ")
	local dummies = r(varlist)
	foreach d in `dummies'{
		
		replace `d' = lower(`d')
		replace `d' = subinstr(`d', "+", "",.)  
		replace `d' = subinstr(`d', "+", "",.)  
		destring `d', gen(_`d') force
		
		replace popnum = _`d' if popnum == .
		replace popnum = 200 if `d' == "hundreds"
		replace popnum = 2000 if `d' == "thousands"
		replace popnum = 24 if `d' == "dozens"

		drop _`d'
	}
	drop `dummies'
	
// Year
	split date, parse("| ")
	destring date3, gen(year)
	sum year
	assert r(min)==2014

// Quarter
	split date2
	gen qtr=1
	replace qtr=2 if(date21=="April"|date21=="May"|date21=="June")
	replace qtr=3 if(date21=="July"|date21=="August"|date21=="September")
	replace qtr=4 if(date21=="October"|date21=="November"|date21=="December")
	replace qtr=year*10+qtr
	sum qtr
	assert r(min)==20143

//Month
	gen month = 1 if date21 == "January"
	replace month = 2 if date21 == "February"
	replace month = 3 if date21 == "March"
	replace month = 4 if date21 == "April"
	replace month = 5 if date21 == "May"
	replace month = 6 if date21 == "June"
	replace month = 7 if date21 == "July"
	replace month = 8 if date21 == "August"
	replace month = 9 if date21 == "September"
	replace month = 10 if date21 == "October"
	replace month = 11 if date21 == "November"
	replace month = 12 if date21 == "December"
	mdesc month
	assert r(percent) == 0
	
// Day
	destring date22, gen(day)

// Date
	drop date*
	g date = mdy(month,day,year)
	format date %d
	
* Clean subject, most important seems to be listed first, generally name of vicum then officers
keep subject date
split subject, parse("|" " - ")
drop subject 
foreach v of varlist subject*{
	replace `v' = subinstr(`v', ".", "",.)
	replace `v'=trim(lower(`v'))
	replace `v' = "paul witherspoon/stephanie washington" if inlist(`v',"paul witherspoon","stephanie washington")
	replace `v' = "john crawford iii" if inlist(`v',"john crawford")
	replace `v' = "ronald johnson iii" if inlist(`v',"ronald johnson")
	replace `v' = "sam dubose" if inlist(`v',"samuel dubose")
	replace `v' = "antwon rose" if inlist(`v',"antwon rose jr")
	replace `v' = "de'von bailey" if inlist(`v',"deâvon bailey")
	replace `v' = "tony robinson" if inlist(`v',"tony robinson jr","tony terrell robinson jr")
}

* Keep only subjects that appear in first subject to delete officer names, etc.
tempfile temp
preserve
	rename subject1 _subject
	keep _subject
	gduplicates drop
	save `temp', replace
restore
foreach v of varlist subject*{
	rename `v' _subject
	merge m:1 _subject using `temp', keep(1 3)
	replace _subject="" if !inlist(_merge,3)
	drop _merge
	rename _subject `v'
}

* Collapse into summary statistics
g id=_n
greshape long subject, i(id)
drop if inlist(subject,"")
g count=1
gcollapse (sum) total_protests=count (min) first_protest=date, by(subject) 
gsort - total_protests + subject first_protest
order total_protests subject first_protest

* Drop subjects that are not victum names or police officer names
drop if inlist(subject,"general","campus racism","people's monday","general local issues","other","local issues","chicago police department","emanuel nine","black trans women")
drop if inlist(subject,"fair cops ordinance","police reform","sacramento police department","black friday")
drop if inlist(subject,"colorado springs police department","education","hennepin county attorney mike freeman","nypd","#freemanfridays")
drop if inlist(subject,"racial discrimination","starbucks","us department of justice","#sayhername","black trans lives","black women/girls/femmes")
drop if inlist(subject,"ferguson police department","hamden police department","hoover police department","lapd chief charlie beck")
drop if inlist(subject,"new york police department","assembly bill 392","criminal justice reform","hamden police commission")
drop if inlist(subject,"martin luther king jr","new york police department (nypd)","portland police association contract")
drop if inlist(subject,"president jonathan veitch","school racism","white supremacy","campus issues","charlottesville","discrimination")
drop if inlist(subject,"gary police department","lgbt rights","los angeles police commission","mayor curt balzano leng")
drop if inlist(subject,"stand your ground","state college police department","toledo police department","westland police department","#nocopacademy","assistant city manager jay chapa")

* Keep top 30
keep in 1/30

* Store city, timing of video, timing of first protest, for each event
g double video=.
g city=""
g fips=""

* Michael Brown
replace video=0 if inlist(subject,"michael brown")
replace city="Ferguson" if inlist(subject,"michael brown")
replace fips="2923986" if inlist(subject,"michael brown")

* Philando Castile (https://en.wikipedia.org/wiki/Shooting_of_Philando_Castile)
replace video=20160706 if inlist(subject,"philando castile") 
replace city="St. Paul" if inlist(subject,"philando castile")					// outskirts of saint paul
replace fips="2758000" if inlist(subject,"philando castile")

* Alton Sterling (https://www.youtube.com/watch?v=pdGXhSQvTKc)
replace video=20160706 if inlist(subject,"alton sterling")
replace city="Baton Rouge" if inlist(subject,"alton sterling")
replace fips="2205000" if inlist(subject,"alton sterling")

* Eric Garner (https://www.nydailynews.com/new-york/staten-island-man-dies-puts-choke-hold-article-1.1871486)
replace video=20140718 if inlist(subject,"eric garner")
replace city="New York" if inlist(subject,"eric garner")
replace fips="3651000" if inlist(subject,"eric garner")

* Anthony Lamar Smith (https://www.youtube.com/watch?v=ukKP6iSEX60&feature=emb_logo)
replace video=20170907 if inlist(subject,"anthony lamar smith")
replace city="St. Louis" if inlist(subject,"anthony lamar smith")
replace fips="2965000" if inlist(subject,"anthony lamar smith")

* Stephon Clark (//https://www.youtube.com/watch?v=-WYzv7kPYNo)
replace video=20180323 if inlist(subject,"stephon clark")
replace city="Sacramento" if inlist(subject,"stephon clark")
replace fips="0664000" if inlist(subject,"stephon clark")

* Laquan Mcdonald (https://www.youtube.com/watch?v=Ow27I3yTFKc)
replace video=20151124 if inlist(subject,"laquan mcdonald")
replace city="Chicago" if inlist(subject,"laquan mcdonald")
replace fips="1714000" if inlist(subject,"laquan mcdonald")

* Jamar Clark (https://www.youtube.com/watch?v=ORoZMZh0SuE)
replace video=20160330 if inlist(subject,"jamar clark")
replace city="Minneapolis" if inlist(subject,"jamar clark")
replace fips="2743000" if inlist(subject,"jamar clark")

* Freddie Gray (https://www.youtube.com/watch?v=7YV0EtkWyno)
replace video=20150421 if inlist(subject,"freddie gray")
replace city="Baltimore" if inlist(subject,"freddie gray")
replace fips="2404000" if inlist(subject,"freddie gray")

* Tamir Rice (https://www.youtube.com/watch?v=7Z8qNUWekWE)
replace video=20141126 if inlist(subject,"tamir rice")
replace city="Cleveland" if inlist(subject,"tamir rice")
replace fips="3916000" if inlist(subject,"tamir rice")

* Keith Lamont Scott (https://www.cnn.com/videos/justice/2016/09/23/charlotte-keith-lamont-scott-cell-video.cnn)
replace video=20160923 if inlist(subject,"keith lamont scott")
replace city="Charlotte" if inlist(subject,"keith lamont scott")
replace fips="3712000" if inlist(subject,"keith lamont scott")

* Paul Witherspoon and Stephanie Washington (https://www.youtube.com/watch?v=Gf6DUQFFCY8)
replace video=20190423 if inlist(subject,"paul witherspoon/stephanie washington")
replace city="New Haven" if inlist(subject,"paul witherspoon/stephanie washington")
replace fips="0952000" if inlist(subject,"paul witherspoon/stephanie washington")

* Terence Crutcher (https://www.youtube.com/watch?v=n9F-Bxwu3_Y)
replace video=20160919 if inlist(subject,"terence crutcher")
replace city="Tulsa" if inlist(subject,"terence crutcher")
replace fips="4075000" if inlist(subject,"terence crutcher")

* Sandra Bland (https://www.wfaa.com/article/news/investigations/new-cellphone-video-shows-what-sandra-bland-saw-during-arrest-by-texas-trooper/287-44ff2f5b-f481-48c3-a5ca-fad15296d979)
replace video=20190506 if inlist(subject,"sandra bland")
replace city="Houston" if inlist(subject,"sandra bland")					// prairie view, outskirts of houston
replace fips="4835000" if inlist(subject,"sandra bland")

* Sam Dubose (https://www.youtube.com/watch?v=kYINt6uNjA0)
replace video=20150729 if inlist(subject,"sam dubose")
replace city="Cincinnati" if inlist(subject,"sam dubose")
replace fips="3915000" if inlist(subject,"sam dubose")

* Dontre Hamilton 
replace video=0 if inlist(subject,"dontre hamilton")
replace city="Milwaukee" if inlist(subject,"dontre hamilton")
replace fips="5553000" if inlist(subject,"dontre hamilton")

* De'von Bailey (https://www.youtube.com/watch?v=Jfz4IGMlh0g)
replace video=20190815 if inlist(subject,"de'von bailey")		// protests release footage
replace city="Colorado Springs" if inlist(subject,"de'von bailey")
replace fips="0816000" if inlist(subject,"de'von bailey")

* Decynthia Clements (https://www.youtube.com/watch?v=OzdiO_xgmfo)
replace video=20180322 if inlist(subject,"decynthia clements")
replace city="Elgin" if inlist(subject,"decynthia clements")
replace fips="1723074" if inlist(subject,"decynthia clements")

* Antwon Rose (https://www.facebook.com/shauny.prettytriqqa/videos/2135530893142291/ and https://www.youtube.com/watch?v=wQLFI5uTBBs)
replace video=20180621 if inlist(subject,"antwon rose")						// posted on facebook first but deleted
replace city="Pittsburgh" if inlist(subject,"antwon rose")					// East pittsburgh
replace fips="4261000" if inlist(subject,"antwon rose")

* Atatiana Jefferson (https://www.youtube.com/watch?v=xpcV0ODTy0Y)
replace video=20191012 if inlist(subject,"atatiana jefferson")
replace city="Fort Worth" if inlist(subject,"atatiana jefferson")
replace fips="4827000" if inlist(subject,"atatiana jefferson")

* Ronald Johnson III (https://www.youtube.com/watch?v=he8rbLd2zt8)
replace video=20151207 if inlist(subject,"ronald johnson iii")		// video released from laquan mcdonal protests
replace city="Chicago" if inlist(subject,"ronald johnson iii")
replace fips="1714000" if inlist(subject,"ronald johnson iii")

* David Jones (https://www.nbcphiladelphia.com/news/national-international/man-on-dirt-bike-shot-to-death-by-police-in-north-philadelphia/18822/)
replace video=20170609 if inlist(subject,"david jones")
replace city="Philadelphia" if inlist(subject,"david jones")
replace fips="4260000" if inlist(subject,"david jones")

* John Crawford III (https://www.youtube.com/watch?v=0XYNOTUWfHE)
replace video=20140924 if inlist(subject,"john crawford iii")			// video released after grand jury
replace city="Beavercreek" if inlist(subject,"john crawford iii")
replace fips="3904720" if inlist(subject,"john crawford iii")

* Jonathan Ferrell (https://www.youtube.com/watch?v=p86K-8kTv68)
replace video=20150805 if inlist(subject,"jonathan ferrell")
replace city="Charlotte" if inlist(subject,"jonathan ferrell")
replace fips="3712000" if inlist(subject,"jonathan ferrell")

* Mario Woods (https://www.youtube.com/watch?v=ij5TZuohoRg&ab_channel=KQEDNews)
replace video=20151207 if inlist(subject,"mario woods")
replace city="San Francisco" if inlist(subject,"mario woods")
replace fips="0667000" if inlist(subject,"mario woods")

* Tony Robinson (https://www.youtube.com/watch?v=L934DUn33UI&ab_channel=GuardianNews)
replace video=20150513 if inlist(subject,"tony robinson")
replace city="Madison" if inlist(subject,"tony robinson")
replace fips="5548000" if inlist(subject,"tony robinson")

* Tyre King
replace video=0 if inlist(subject,"tyre king")
replace city="Columbus" if inlist(subject,"tyre king")
replace fips="3918000" if inlist(subject,"tyre king")

* Aura Rosser
replace video=0 if inlist(subject,"aura rosser")
replace city="Ann Arbor" if inlist(subject,"aura rosser")
replace fips="2603000" if inlist(subject,"aura rosser")

* Ezell Ford
replace video=0 if inlist(subject,"ezell ford")
replace city="Los Angeles" if inlist(subject,"ezell ford")
replace fips="0644000" if inlist(subject,"ezell ford")

* Harith Augustus (https://www.youtube.com/watch?v=lWdqee-itN8&ab_channel=NBCNews)
replace video=20180715 if inlist(subject,"harith augustus")					// video released after protest
replace city="Chicago" if inlist(subject,"harith augustus")
replace fips="1714000" if inlist(subject,"harith augustus")

* Date
g year=int(video/10000)
g month=int((video-year*10000)/100)
g day=int(video-year*10000-month*100)
g video_date = mdy(month,day,year)
drop month day year video
format video_date %d

* State
merge m:1 fips using "DTA/fips", keep(3) nogen keepus(stabb)

* Table of case studies
gsort - total_protests
cap drop _col*
g _col1 = _n
label var _col1 "\#"
g _col2 = "\small "+ subinstr(subinstr(proper(subject), "Iii", "III",.), "/", " and \newline ",.)
label var _col2 "Name of victim"
g str _col3 = "\small " +city +", " +stabb
label var _col3 "Location"
g _col4 = total_protests
label var _col4 "Total protests"
g _col5="\small "+string(month(first_protest))+"/"+string(day(first_protest))+"/"+string(year(first_protest)-2000)
label var _col5 "First protest"
g _col6="\small "+string(month(video_date))+"/"+string(day(video_date))+"/"+string(year(video_date)-2000)
replace _col6="" if inlist(video_date,.)
label var _col6 "Video release"
g _col7 = "\checkmark" if first_protest<video_date & !inlist(video_date,.)
label var _col7 "Protest before video"
texsave _col* using output/case_studies, replace frag autonumber varlabels nofix align(l p{4cm} X P{1.5cm} P{1.6cm} P{1.6cm} P{1.5cm}) title("List of High Profile Police Killings from 2014 to 2019") label(tab:case_studies) footnote("\textit{Notes:} Philando Castile, Sandra Bland, and Antwon Rose were killed outside of the reported city in nearby areas below the 20,000 population screen.")
drop _col*

* Keep only first event in each city
bys city (first_protest): g test=_n
keep if inlist(test,1)
drop test

* Drop events with too little post-treatment data
drop if year(first_protest)>=2019

* Save
g date=first_protest
save DTA/case_studies, replace
