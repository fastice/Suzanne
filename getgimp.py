#!/usr/bin/python

# Usage:
#
#    In a terminal/command line, cd to the directory where this file lives. Then...
#
#    With embedded urls: ( download the hardcoded list of files in the 'files =' block below)
#
#       python ./download-all-2019-02-07_22-33-17.py
#
#    Download all files in a Metalink/CSV: (downloaded from ASF Vertex)
#
#       python ./download-all-2019-02-07_22-33-17.py /path/to/downloads.metalink localmetalink.metalink localcsv.csv
#
#    Compatibility: python >= 2.6.5, 2.7.5, 3.0
#
#    If downloading from a trusted source with invalid SSL Certs, use --insecure to ignore
#
#    For more information on bulk downloads, navigate to:
#        https://www.asf.alaska.edu/data-tools/bulk-download/
#
#
#
#    This script was generated by the Alaska Satellite Facility's bulk download service.
#    For more information on the service, navigate to:
#        http://bulk-download.asf.alaska.edu/help
#

import csv
import os, os.path
import re
from bs4 import BeautifulSoup
import argparse

import base64
import datetime
import getpass
import ssl
import xml.etree.ElementTree as ET

import requests
from urllib.request import build_opener, install_opener, Request, urlopen, urlretrieve
from urllib.request import HTTPHandler, HTTPSHandler, HTTPCookieProcessor
from urllib.error import HTTPError, URLError

from http.cookiejar import MozillaCookieJar


class cookie_maintenance:
    ### cookie methods from script generated by the Alaska Satellite Facility's bulk download service ###
    
    def __init__(self):
        # Local stash of cookies so we don't always have to ask                                                                                              
        self.cookie_jar_path = os.path.join( os.path.expanduser('~'), ".gimp_download_cookiejar.txt")
        self.cookie_jar = None
        # For SSL
        self.context = {}
        # Make sure cookie_jar is good to go!                                                                                                                
        self.get_cookie()
        
        self.asf_urs4 = { 'url': 'https://urs.earthdata.nasa.gov/oauth/authorize',
                 'client': 'BO_n7nTIlMljdvU6kRRB3g'} #,
              #   'redir': 'https://vertex.daac.asf.alaska.edu/services/urs4_token_request'}

    # Get and validate a cookie
    def get_cookie(self):
       if os.path.isfile(self.cookie_jar_path):
          self.cookie_jar = MozillaCookieJar()
          self.cookie_jar.load(self.cookie_jar_path)
    
          # make sure cookie is still valid
          if self.check_cookie():
             print(" > Re-using previous cookie jar.")
             return True
          else:
             print(" > Could not validate old cookie Jar")
    
       # We don't have a valid cookie, prompt user for creds
       print ("No existing URS cookie found, please enter Earthdata username & password:")
       print ("(Credentials will not be stored, saved or logged anywhere)")
    
       # Keep trying 'till user gets the right U:P
       while self.check_cookie() is False:
          self.get_new_cookie()
    
       return True
    
    # Validate cookie before we begin
    def check_cookie(self):
    
       if self.cookie_jar is None:
          print (" > Cookiejar is bunk: {0}".format(self.cookie_jar))
          return False
    
       # File we know is valid, used to validate cookie
       file_check = 'https://urs.earthdata.nasa.gov/profile'
    
       # Apply custom Redirect Handler
       opener = build_opener(HTTPCookieProcessor(self.cookie_jar), HTTPHandler(), HTTPSHandler(**self.context))
       install_opener(opener)
    
       # Attempt a HEAD request
       request = Request(file_check)
       request.get_method = lambda : 'HEAD'
       try:
          print (" > attempting to download {0}".format(file_check))
          response = urlopen(request, timeout=30)
          resp_code = response.getcode()
          # Make sure we're logged in
          if not self.check_cookie_is_logged_in(self.cookie_jar):
             return False
    
          # Save cookiejar
          self.cookie_jar.save(self.cookie_jar_path)
    
       except HTTPError:
          # If we ge this error, again, it likely means the user has not agreed to current EULA
          print ("\nIMPORTANT: ")
          print ("User appears to lack permissions to download data from the Earthdata Datapool.")
          print ("\n\nNew users: you must first have an account at Earthdata https://urs.earthdata.nasa.gov")
          exit(-1)
    
       # This return codes indicate the USER has not been approved to download the data
       if resp_code in (300, 301, 302, 303):
#          try:
#             redir_url = response.info().getheader('Location')
#          except AttributeError:
#             redir_url = response.getheader('Location')
#    
#          #Funky Test env:
#          if ("vertex.daac.asf.alaska.edu" in redir_url and "test" in self.asf_urs4['redir']):
#             print ("Cough, cough. It's dusty in this test env!")
#             return True
    
          print ("Redirect ({0}) occured, invalid cookie value!".format(resp_code))
          return False
    
       # These are successes!
       if resp_code in (200, 307):
          return True
    
       return False
    
    def get_new_cookie(self):
       # Start by prompting user to input their credentials
    
       # Another Python2/3 workaround
       try:
          new_username = raw_input("Username: ")
       except NameError:
          new_username = input("Username: ")
       new_password = getpass.getpass(prompt="Password (will not be displayed): ")
    
    
       try:
          #python2
          user_pass = base64.b64encode (bytes(new_username+":"+new_password))
       except TypeError:
          #python3
          user_pass = base64.b64encode (bytes(new_username+":"+new_password, "utf-8"))
          user_pass = user_pass.decode("utf-8")
    
       # Authenticate against URS, grab all the cookies
       self.cookie_jar = MozillaCookieJar()
       opener = build_opener(HTTPCookieProcessor(self.cookie_jar), HTTPHandler(), HTTPSHandler(**self.context))
       request = Request('https://daacdata.apps.nsidc.org/pub/DATASETS/', headers={"Authorization": "Basic {0}".format(user_pass)})
    
       # Watch out cookie rejection!
       try:
          response = opener.open(request)
       except HTTPError as e:
          if e.code == 401:
             print (" > Username and Password combo was not successful. Please try again.")
             return False
          else:
             # If an error happens here, the user most likely has not confirmed EULA.
             print ("\nIMPORTANT: There was an error obtaining a download cookie!")
             print ("Your user appears to lack permission to download data from the ASF Datapool.")
             print ("\n\nNew users: you must first log into Vertex and accept the EULA. In addition, your Study Area must be set at Earthdata https://urs.earthdata.nasa.gov")
             exit(-1)
       except URLError as e:
          print ("\nIMPORTANT: There was a problem communicating with URS, unable to obtain cookie. ")
          print ("Try cookie generation later.")
          exit(-1)
    
       # Did we get a cookie?
       if self.check_cookie_is_logged_in(self.cookie_jar):
          #COOKIE SUCCESS!
          self.cookie_jar.save(self.cookie_jar_path)
          return True
    
       # if we aren't successful generating the cookie, nothing will work. Stop here!
       print ("WARNING: Could not generate new cookie! Cannot proceed. Please try Username and Password again.")
       print ("Response was {0}.".format(response.getcode()))
       print ("\n\nNew users: you must first log into Vertex and accept the EULA. In addition, your Study Area must be set at Earthdata https://urs.earthdata.nasa.gov")
       exit(-1)
    
    # make sure we're logged into URS
    def check_cookie_is_logged_in(self, cj):
       for cookie in cj:
          if cookie.name == 'urs_user_already_logged':
              # Only get this cookie if we logged in successfully!
              return True
       
       return False

def get_names(urldir,pullflag):
    tdclass='indexcolname'
    if pullflag:
        tdclass = 'indexcolicon'
    dlist=[]
    r = requests.get(urldir)
    if r.status_code:
        soup =  BeautifulSoup(r.text, 'html.parser')
        for table in soup.find_all('table',{'id':'indexlist'}):
            for tr in table.find_all('tr',{'class':['even','odd']}):                
                for td in tr.find_all('td',{'class':tdclass}):
                    for a in td.find_all('a'):
                        if '/pub/DATASETS/' not in a['href']:
                            dlist.append( a['href'])
        return dlist
        
# if user only put in tenths of a degree, region directory name includes the hundreths place, so insert the zero
def check_region_name(region):
    try:
        decdeg = re.findall('\.(\d+)',region) # find all digits after the dot.
        if len(decdeg[0]) < 2:
            mydot = region.find('.')
            region = region[:mydot+2] + '0' + region[mydot+2:]
        return region
    except:
        return None

# find dates in directory names (Suzanne, can you look for yyyy-mm-dd in each dir name? re.match() ? )
def directory_dates(dirs,prod,region=None):
    mon = {'Jan':1,'Feb':2,'Mar':3,'Apr':4,'May':5,'Jun':6,'Jul':7,'Aug':8,'Sep':9,'Oct':10,'Nov':11,'Dec':12}
    t0=[]
    t1=[]
    for dirname in dirs:
        if prod == '0481' and region:
            m = re.findall(r'(\w{3}\-\d{2}\-\d{4})',dirname)  # Mmm-dd-yyyy
            month0,d0,y0 = m[0].split('-')
            m0 = mon[month0]
            month1,d1,y1 = m[1].split('-')
            m1 = mon[month1]
            
        if prod == '0731':
            m = re.findall(r'(\d{4}\-\d{2}\-\d{2})',dirname)  # yyyy-mm-dd
            y0,m0,d0 = m[0].split('-')
            y1,m1,d1 = m[1].split('-')
            
        t0.append(datetime.date(int(y0),int(m0),int(d0)))
        t1.append(datetime.date(int(y1),int(m1),int(d1))) 
    return t1, t0




if __name__ == '__main__':
    
    # read product names and their paths into dictionary.
    try:   
        with open('productPaths.csv','r') as infile:
            rows = csv.reader(infile)
            prod_path= {row[0]:row[1] for row in rows}
    except:
        print('Need productPaths.csv file indicating paths of products')
        exit(-1)
    
    # parse command line arguments
    parser = argparse.ArgumentParser(description='Retrieves GIMP files of specified products.')    
    # add parameters to parse
    parser.add_argument('-l', '--list', dest='prodlist', help='product name',default=None)  
    parser.add_argument('-p', '--pull', dest='prodpull', help='product name',default=None) 
    parser.add_argument('-r', '--region', dest='region', help='regional, glaciar box name',default=None)
    parser.add_argument('-fd','--firstdate', dest='firstdate', help='first date as yyyy-mm-dd',default=None)
    parser.add_argument('-ld','--lastdate', dest='lastdate', help='fast date as yyyy-mm-dd (default is first date)',default=None)
    parser.add_argument('-o', '--outdir', dest='outdir', help='directory name for downloaded files (default is cwd)',default='./')
    parser.add_argument('-np', '--noprompt', action='store_true', help='suppress question about downloading')
    # parse the arguments
    args = parser.parse_args()
    
    args.prod = args.prodlist or args.prodpull  
    args.region = check_region_name(args.region)
    
    if args.firstdate and not args.lastdate:
        args.lastdate = args.firstdate  
        
    # if issues
    if args.prod not in prod_path:
        print('Product listed, {0}, is not available, please see or update ./productPaths.csv'.format(args.prod))
        exit(-1)

    if args.prodlist and args.prodpull:
        print('You can only list or pull, not both.')
        exit(-1)

    if args.prod=='0731' and args.region is not None:
        print('Product {0} does not have regions'.format(args.prod))
        exit(-1)
        
    if args.region and args.firstdate and args.prod is None:
        print('This run needs a product, ie -list prod')
        exit(-1)
        
    if os.access(args.outdir, os.W_OK) is False:  # I haven't checked this one
        print ("WARNING: Cannot write to current path! Check permissions for {0}".format(args.outdir))
        exit(-1)
    
    cookie_maintenance()
    
    # url and directory names.
    url = prod_path[args.prod] + (args.region or '') 
    dirs = get_names(url,bool(args.prodpull))
    
    # put -firstdate and -lastdate arguments into python datetime format
    if args.firstdate:
        yf,mf,df = [int(item) for item in args.firstdate.split('-')]
        firstdate = datetime.date(yf,mf,df)  # converted to the datetime format
        yl,ml,dl = [int(item) for item in args.lastdate.split('-')]
        lastdate = datetime.date(yl,ml,dl)
        
        dir_date1,dir_date2 = directory_dates(dirs,args.prod,args.region)
        
        # find directories that are within -firstdate and -lastdate arguments
        mask = [dir_date1[ii]>=firstdate and dir_date2[ii]<=lastdate for ii in range(len(dir_date1))]
        dirs = [dirs[ii] for ii in range(len(dirs)) if mask[ii]]
        
    
    # list directories to screen
    answer = ''
    if args.prodlist:    
        print()
        print('Available directories:')
        for item in dirs:
            print(item)
        if not args.noprompt:
            answer = input('Do you want to download these products [y/n] :')
        
    if answer.startswith('y') or args.prodpull:
#    if args.prodpull:    
        print()
        print('Downloading:')
        for dirname in dirs:
            print(dirname)
            files = get_names(url + '/' + dirname,bool(args.prodpull))
            for file in files:
                fullpath = url + '/' + dirname + '/' + file
                r = requests.get(fullpath)
                
                outfile = args.outdir.strip('/') + '/' + file
                print(outfile)
                with open(outfile,'wb') as f:
                    f.write(r.content)
        print('Done')
        
