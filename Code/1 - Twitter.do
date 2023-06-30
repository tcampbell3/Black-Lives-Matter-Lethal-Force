
* Open geograph file
use "Data/Twitter/twitter_geo.dta", clear
keep GOVID FSTATE FPLACE
g fips = string(FSTATE,"%02.0f") + string(FPLACE,"%05.0f") 

* Define year
expand 11
bys GOVID: g year = _n+2009
order GOVID year

* Merge Twitter data
merge m:1 GOVID year using "Data/Twitter/twitter_sentiment_041921.dta", nogen 

* Code zeros for no tweets
foreach v in tweet_counts polarity sub_tweet_counts sub_polarity index_total_sent{
	replace `v' = 0 if inlist(`v', .)
}

* Total tweets
bys GOVID: gegen total_tweets = sum(tweet)

* Clean and save
drop obs tot_obs tot_tweets avg_tweets
compress
save DTA/Twitter, replace