import delimited "Data\news_blogs_scrape.csv", varnames(1) clear
split url, parse("/")
keep url1
gduplicates drop
g test=subinstr(url, "..", "",.) 
drop if url1!=test
drop test
export delimited using "C:\Users\travi\Dropbox\Police Killings\Data\news_blogs_scrape_clean.csv", replace