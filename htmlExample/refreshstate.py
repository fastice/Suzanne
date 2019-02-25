#!/usr/bin/python3
#
# This program runs in a directory of EOF orbit files from ESA. It checks the last file downloaded, and then proceeds to
# download all new files to present
#
import utilities as u
from datetime import datetime,timedelta
import requests
from html.parser import HTMLParser
import copy
import urllib
#
# subclass my parser to grab data
class myHTMLParser(HTMLParser) :
    # store my data here
    S1A=''
    S1B=''
    # redefine handle_date
    def handle_data(self,data) :
        if 'EOF' in data :
            if 'S1A' in data :
                self.S1A=data
            elif 'S1B' in data :
                self.S1B=data
            else :
                u.myerror('invalid orbit file')
#
# parse returned HTML to get file names
def parseFileNames(myText) :
    myParser=myHTMLParser()
    myParser.feed(myText)
    return myParser.S1A,myParser.S1B
#
# get the last orbit downloaded to determine starting point
def getLastOrbDate() :
    #
    # dir to get last name
    S1A=u.dols('ls S1A_OPER*.EOF')[-1]
    S1B=u.dols('ls S1B_OPER*.EOF')[-1]
    # get the dates
    dirDateA=   datetime.strptime(S1A.split('_')[5].split('T')[0],"%Y%m%d")
    dirDateB=   datetime.strptime(S1B.split('_')[5].split('T')[0],"%Y%m%d")    
    return dirDateA,dirDateB

def getFilePaths(dirDate) :
    myPaths=[]
    # get today to know when to stop
    today=datetime.now()
    # first data to process
    workingDate=dirDate+timedelta(1)
    #
    # loop until done
    #
    #count=0
    while 1 :
        #
        # server path to the dated directory
        myPath='http://aux.sentinel1.eo.esa.int/POEORB/'+workingDate.strftime('%Y/%m/%d/')
        # grab the contents
        res=requests.get( myPath)
        # parse out the names
        S1A,S1B=parseFileNames(res.text)
        # append names to paths
        if len(S1A) > 1 :
            S1Apath=myPath+S1A
            myPaths.append(S1Apath)
        if len(S1B) > 1 :
            S1Bpath=myPath+S1B
            myPaths.append(S1Bpath)
        # advance to next date
        workingDate += timedelta(1)
        # exit if past present
        if workingDate > today :
            break
       # count+=1
        #if(count > 60) :
          #  break
    return myPaths

def downloadOrbFiles(orbPaths) :
    for orbPath in orbPaths :
        print('Downloading : ',orbPath)
        # save to local directory with same filename
        fileName=orbPath.split('/')[-1]
        urllib.request.urlretrieve(orbPath,fileName)
        
def main() :
    # check what has been downloaded and start from there
    dirDateA,dirDateB=getLastOrbDate()
    #-----    
    #dirDateA= datetime.strptime("20150301","%Y%m%d")
    # both should be the same, but in case not go with earliest
    bestDate=min(dirDateA,dirDateB)
    print('Downloading all data after ', bestDate)
    #
    orbPaths=getFilePaths(bestDate)
    #-----
    #print(orbPaths)
    #orbPaths=orbPaths[0:59]
    #
    downloadOrbFiles(orbPaths)


main()
