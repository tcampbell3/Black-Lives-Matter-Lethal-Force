#Instructions from https://www.youtube.com/watch?v=XQgXKtPSzUI&t=174s

#How to open python in command prompt:
	#1) Shift+Right Click -> open command prompt
	#2) type "conda activate"
	#3) type "python"

#To run the python script, type the following line into the command prompt:
#python "C:\Users\travi\Dropbox\Police Killings\Do Files\webscrape.py"

# import packages
import time
import itertools 
import csv
import codecs
from bs4 import BeautifulSoup
from selenium  import webdriver
from time import sleep

# access website through automated chrome
chrome_path=r"C:\Users\travi\Anaconda3\Lib\site-packages\selenium\chromedriver.exe"
driver = webdriver.Chrome(chrome_path)
driver.get('https://elephrame.com/textbook/BLM')
sleep(2)

# save csv
filename = "../Data/BLM Protests/protests_scrape.csv"
f = codecs.open(filename, encoding='utf-8', mode='w+')
headers = "Location, Date, Subject, Description, Participants\n"
f.write(headers)

# loop clicks over all pages
page_new = 1
pagenum = -1
while(pagenum < page_new):

	#click to next page
	if pagenum > -1:

		driver.find_element_by_xpath("""//*[@id="blm-results"]/div[1]/ul/li[4]""").click()

		# don't overflow website
		sleep(2)

		#update page numbers for while statement
		page_new = driver.find_element_by_xpath("""//*[@id="blm-results"]/div[1]/ul/li[3]/input""").get_attribute("value")
		page_new = int(page_new, 10) #coverts from string to numeric
	
	pagenum = pagenum + 1

	# append data from this click
	locations = driver.find_elements_by_class_name("item-protest-location")
	dates = driver.find_elements_by_class_name("protest-start")
	participants = driver.find_elements_by_class_name("item-protest-participants")
	descriptions = driver.find_elements_by_class_name("item-protest-description")
	subjects = driver.find_elements_by_class_name("item-protest-subject")

	for (a, b, c, d, e) in zip(locations, dates, subjects, descriptions, participants):
		print(a.text, b.text, c.text, d.text, e.text)
		f.write(a.text.replace(",", "|") + "," + b.text.replace(",", "|") + "," + c.text.replace(",", "|").replace("Subject(s): ","") + "," + d.text.replace(",", "|").replace("Description: ","") + "," + e.text + "\n")

# close browser
driver.quit()

# close csv file
f.close()