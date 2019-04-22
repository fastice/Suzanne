#!/usr/bin/python

# Usage:
#
#    In a terminal/command line, cd to the directory where this file lives. Then...
#    python getgimp.py -h  
#        to get list of command line arguments 
#

# Python 2 and 3:
from __future__ import print_function   

import csv
import os, os.path, sys
#sys.path.insert(0, '/Users/suzanne/git_repos/')
#import utilities as u
import re
from bs4 import BeautifulSoup
import argparse
import threading

import base64
import datetime, time, calendar
import getpass

import requests
from runMyThreads import runMyThreads

# This next block is a bunch of Python 2/3 compatability                                                                                                                       
try:
   # Python 3.x Libs             
    import urllib.request                                                                                                                                    
    from urllib.request import build_opener, install_opener, Request, urlopen
    from urllib.request import HTTPHandler, HTTPSHandler, HTTPCookieProcessor
    from urllib.error import HTTPError, URLError
    from urllib.parse import urlparse  

    from http.cookiejar import MozillaCookieJar
    from io import StringIO

except ImportError as e:
   # Python 2.x Libs                                                                                                                                                           
    from urllib2 import build_opener, install_opener, Request, urlopen, HTTPError
    from urllib2 import URLError, HTTPSHandler,  HTTPHandler, HTTPCookieProcessor

    from cookielib import MozillaCookieJar
    from StringIO import StringIO


###                                                                                                                                                                            


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
          # If we get this error, again, it likely means the user has not agreed to current EULA
          print ("\nIMPORTANT: ")
          print ("User appears to lack permissions to download data from the Earthdata Datapool.")
          print ("\n\nNew users: you must first have an account at Earthdata https://urs.earthdata.nasa.gov")
          exit(-1)
    
       # This return codes indicate the USER has not been approved to download the data
       if resp_code in (300, 301, 302, 303):    
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

def get_names(urldir,args):
    alist=[]
    try:
        r = requests.get(urldir)
    except requests.exceptions.RequestException as e:
        print(e)
        exit(-1)
    if r.status_code:
        soup =  BeautifulSoup(r.text, 'html.parser')
        for table in soup.find_all('table',{'id':'indexlist'}):
            for tr in table.find_all('tr',{'class':['even','odd']}):                 
                for td in tr.find_all('td',{'class':'indexcolicon'}): # gets file names
                    for a in td.find_all('a'):
                        if '/pub/DATASETS/' not in a['href'] and '/MEASURES/' not in a['href']:
                            alist.append(a['href'])
                            
        flist = [item for item in alist if not item.endswith('/')]
        dlist = [item for item in alist if item.endswith('/')]
        
        if args.type in dlist:
                dlist = [item for item in alist if item == args.type]
                
        if args.region and args.region != 'all' and not urldir.endswith(args.region):
            dlist = [item for item in alist if item == args.region.strip('/') + '/']  # to make dirs a list with one element
            if not dlist and args.region not in urldir:
                print()
                print('Region {0} is not available for product {1}.'.format(args.region,args.prod))
                print()
                print('Possible regions include:')
                time.sleep(2) # in case list is longer then terminal window is tall.
                for item in alist:
                    if item.endswith('/'):
                        print(item)
                exit(-1)
                
        return flist, dlist
    else:
        print('requests.get response has bad status_code')
        exit(-1)
        
# if user only put in tenths of a degree, region directory name includes the hundreths place, so insert the zero
def check_region_name(region):
    try:
        decdeg = re.findall('\.(\d+)',region) # find all digits after the dot.
        if len(decdeg[0]) < 2:
            mydot = region.find('.')
            region = region[:mydot+2] + '0' + region[mydot+2:]
        region = region.strip('/') + '/'
        
        return region
    except:
        return ''

# find dates in directory names 
def directory_dates(dirs,args):
    dt_f = {'mmm':'%b','mm':'%m','yyyy':'%Y','yy':'%y','dd':'%d'}
    days_in_month = {1:31,2:28,3:31,4:30,5:31,6:30,7:31,8:31,9:30,10:31,11:30,12:31}
    t0=[]
    t1=[]
    
    dirdate_format = prod_path[args.prod][args.dival['dateFormat']]  # in dir names
    dd_f = re.findall(r"[\w']+",dirdate_format)

    try:
        sep  = re.findall(r"[.-]+",dirdate_format)[0]
    except:
        sep = ''
    dt_format = '-'.join([dt_f[dd_f[item]] for item in range(len(dd_f))]) # python-ese

    for dirname in dirs:
        # build format to convert from, in python-ese
        if len(dd_f)==3:
            
            #forma = sep.join[len(dd_f[i]) for i in len(dd_f)]
            pattern = re.compile(r'(\w{%d}%s\w{%d}%s\w{%d})' % (len(dd_f[0]),sep,len(dd_f[1]),sep,len(dd_f[2]))) # doesn't like list comp
            m = re.findall(pattern,dirname)
            if m:
                dt = time.strptime(m[0].replace(sep,'-'),dt_format)
                t0.append(datetime.date(dt.tm_year,dt.tm_mon,dt.tm_mday)) 
                if len(m)>1:
                    dt = time.strptime(m[1],dt_format)
                    t1.append(datetime.date(dt.tm_year,dt.tm_mon,dt.tm_mday))
                else:
                    t1.append(datetime.date(dt.tm_year,dt.tm_mon,days_in_month[dt.tm_mon]))
            else:
                t0.append(datetime.date(2100,1,1)) # will not get dirs if no dates in them, use --byname
                t1.append(datetime.date(1900,1,1))

        # sometimes there are only year and month
        elif len(dd_f)==2:
            pattern = re.compile(r'(\w{%d}%s\w{%d})' % (len(dd_f[0]),sep,len(dd_f[1]))) 
            m = re.findall(pattern,dirname) 
            if m:
                dt = time.strptime(m[0],dt_format)
                t0.append(datetime.date(dt.tm_year,dt.tm_mon,dt.tm_mday)) # default is first day
                if len(m)>1:
                    dt = time.strptime(m[1],dt_format)
                    t1.append(datetime.date(dt.tm_year,dt.tm_mon,dt.tm_mday))
                else:          
                    t1.append(datetime.date(dt.tm_year,dt.tm_mon,days_in_month[dt.tm_mon])) # set to last day
            else:
                t0.append(datetime.date(2100,1,1)) # will not get dirs if no dates in them, use --byname
                t1.append(datetime.date(1900,1,1))
            
        # sometimes there is only year
        elif len(dirdate_format.split('-'))==1:
            pattern = re.compile(r'(\d{%d})' % len(dd_f[0]))
            m = re.findall(pattern,dirname) 
            if m:
                dt = time.strptime(m[0],dt_format)
                t0.append(datetime.date(dt.tm_year,dt.tm_mon,dt.tm_mday)) # default is first month, first day
                if len(m)>1:
                    dt = time.strptime(m[1],dt_format)
                else:
                    dt = time.strptime(m[0],dt_format)
                t1.append(datetime.date(dt.tm_year,12,31))                # set to last month, last day
            else:
                t0.append(datetime.date(2100,1,1)) # will not get dirs if no dates in them, use --byname
                t1.append(datetime.date(1900,1,1))
                
    mask = [t1[ii]>=firstdate and t0[ii]<=lastdate for ii in range(len(t0))]
    return [dirs[ii] for ii in range(len(dirs)) if mask[ii]]    

def establish_dir(download_dir):
   if not os.path.exists(download_dir):
        os.makedirs(download_dir)
        if os.access(download_dir, os.W_OK) is False:  # I haven't checked this one
            print ("WARNING: Cannot write to this path! Check permissions for {0}".format(download_dir))
            exit(-1)
    
def download_files(url,args,dirpath,file_list):
    for file in file_list:
        outfile = args.outpath + '/' + dirpath + file
        fullpath = url + dirpath + file

        # if the file is in the path, and it's the right size, skip.
        if os.path.isfile(outfile) and (int(os.path.getsize(outfile)) == int(requests.get(fullpath,stream=True).headers['Content-Length']) and not args.overwrite):
            print('Skipping: ',outfile )
        else:
            print('Downloading: ',outfile)
            try:
                r = requests.get(fullpath)             
            except requests.exceptions.RequestException as e:
                print(e)
                exit(-1)
            with open(outfile,'wb') as f:
                 f.write(r.content)

def download_filesTh(url,args,dirpath,file_list):
#    def web_file_size(inf):
#        if inf.endswith( ('.txt','.xml')):
#            return len(requests.get(inf).content)
#        else:
#            return int(requests.get(inf,stream=True).headers['Content-Length'])
                       
    def do_one(outf,inf):        
        if os.path.isfile(outf) and (int(os.path.getsize(outf)) == int(requests.get(inf,stream=True).headers['Content-Length']) and not args.overwrite):
            pass #print('Skipping: ',outf )
        else:
            try:
                r = requests.get(inf)             
            except requests.exceptions.RequestException as e:
                print(e)
                exit(-1)
            with open(outf,'wb') as f:
                f.write(r.content)    
            # check size after download
            if not int(os.path.getsize(outf)) == int(requests.get(inf,stream=True).headers['Content-Length']):
                print('\n {0} did not fully download:'.format(outf))
                print('\n\t {0} size has {1} bytes.'.format(inf,int(requests.get(inf,stream=True).headers['Content-Length'])))
                print('\n\t {0} size has {1} bytes.'.format(outf,int(os.path.getsize(outf))))
                exit(-1)
            
    threads = []
    for file in file_list:
        outfile = args.outpath + '/' + dirpath + file
        if not dirpath in url:
            fullpath = url + dirpath + file   
        else:
            fullpath = url + file
        t = threading.Thread(target=do_one, args=(outfile,fullpath))
        threads.append(t)
        
    msg = 'Downloading ' + dirpath
    runMyThreads(threads,10,msg,prompt=False)
    
def download_prod(urldir_path,args,nsidc_url):
    if nsidc_url in urldir_path:
        local_dirname = urldir_path.replace(nsidc_url,'')
        establish_dir(args.outpath  + '/' + local_dirname)
        fl,dl = get_names(urldir_path,args)
        
        download_filesTh(urldir_path,args,local_dirname,fl)

def help_msg(keys):
    message = "GIMP NSIDC dataset numbers available for download: %s. Use -pd for descriptions" % ' \n'.join([str(key) for key in keys])  # \n doesn't work
    return message

def use_msg(msg):
    print()
    print(msg)
    print()

def exit_msg(msg):
    use_msg(msg)
    exit(-1)
    
############################################################################

if __name__ == '__main__':
    
    # read product names and their urls.
    try:   
        with open('productPaths.csv') as csvfile:
            rows = csv.reader(csvfile)
            prod_path = {row[0]:[int(row[1]),row[2],row[3].strip(),row[4].strip()] for row in rows}   # product number : [#dir levels, date format in directory name, product description, url-path to product]
        dival = {'dateLevel':0,'dateFormat':1,'description':2,'url':3}
    except:
        use_msg('Need productPaths.csv file containing path info.')
    
    # parse command line arguments
    parser = argparse.ArgumentParser(description='Retrieves GIMP files of specified products.')    
    # add parameters to parse
    parser.add_argument('-l', '--list', dest='prodlist', metavar='product number', help=help_msg(prod_path.keys()),default=None)  
    parser.add_argument('-p', '--pull', dest='prodpull', metavar='product number', help='product name',default=None) 
    parser.add_argument('-r', '--region', dest='region', help='options: regional glacier box name (e.g., Wcoast-69.10N), all',default='')
    parser.add_argument('-fd','--firstdate', dest='firstdate', help='first date as yyyy-mm-dd',default='1900-01-01')
    parser.add_argument('-ld','--lastdate', dest='lastdate', help='last date as yyyy-mm-dd',default='2100-01-01')
    parser.add_argument('-t', '--type', dest='type', metavar='mosaic type', help='mosaic type for cases with multiple resolutions (e.g., 20byte for 0633/2005_2006/20byte)',default='')
    parser.add_argument('-name', '--byname', dest='byname', metavar='non-date directory name', help='for products with non-date derived names (e.g., multiyear_composite for 0633/multiyear_composite).' ,default='')
    parser.add_argument('-o', '--overwrite', action='store_true', help='download files even if they already exist')
    parser.add_argument('-v', '--verbose', action='store_true', help='list files as well as directories')
    parser.add_argument('-pd', '--description',action='store_true',help='list descriptions of all products available for download')
    args = parser.parse_args()
    args.dival = dival

    if len(sys.argv) == 1: # if no command line arguments
        parser.print_help()
        sys.exit(1)
  
    if args.description:
        line0 = '\n'.join([' '+key+':  '+prod_path[key][2] for key in prod_path.keys()])
        print()
        print('Prod #     Dataset Description')
        print(line0)
        sys.exit(1)
        
    
    # sort out arguments and return errors if need be
    args.prod = args.prodlist or args.prodpull  
    try:
        url = prod_path[args.prod][args.dival['url']]
    except:
        exit_msg('Product number %s is not available. Use --description for current list.' % args.prod)    

    if args.region != 'all': 
        args.region = check_region_name(args.region)
    
    if args.region and prod_path[args.prod][args.dival['dateLevel']]<=1:
        exit_msg('This product, %s, does not have regions.' % args.prod)
        
    args.outpath = './' + args.prod
    
    # put --firstdate and --lastdate arguments into datetime.date format
    yf,mf,df = [int(item) for item in args.firstdate.split('-')]
    firstdate = datetime.date(yf,mf,df)  
    yl,ml,dl = [int(item) for item in args.lastdate.split('-')]
    lastdate = datetime.date(yl,ml,dl)      
    # modify dates if dateFormat dictates
    datetags = prod_path[args.prod][args.dival['dateFormat']].replace('.','-').split('-')  # a list results
    year = month = day = False
    for item in datetags:
        if item.startswith('y'):
            year = True
            if item.endswith('m'): # 0724
                month = True
        if item.startswith('m'):
            month = True
        if item.startswith('d'):
            day = True
    if month and not day:
        df = 1
        wkday,dl = calendar.monthrange(yl,ml)
        firstdate = datetime.date(yf,mf,df)  
        lastdate = datetime.date(yl,ml,dl)      
    if not month and not day:
        mf=1;df=1
        ml=12;dl=31
        firstdate = datetime.date(yf,mf,df)  
        lastdate = datetime.date(yl,ml,dl)      
    
    if args.prodlist and args.prodpull:
        exit_msg('You can only list or pull, not both.')

    if prod_path[args.prod][args.dival['dateLevel']] == 0 and args.region:
        exit_msg('Product {0} does not have directories separated by region or dates.'.format(args.prod))

    # ensure a / on the end
    if args.type:
        args.type = args.type.strip('/') + '/'
    if args.byname:
        args.byname = args.byname.strip('/') + '/'
        if firstdate == datetime.date(1900,1,1) and lastdate == datetime.date(2100,1,1):
            firstdate = datetime.date(2100,1,1)   # if by name, dont get by dates
            lastdate = datetime.date(1900,1,1)
            
    if args.prod not in prod_path:
        exit_msg('Product {0} is not available, please see getgimp.py -h or update ./productPaths.csv'.format(args.prod))
        
    cookie_maintenance()

    ##### list or pull files 
    # dateLevel = 0 currently means no date level, but has types
    #dir_list = []   
    if prod_path[args.prod][args.dival['dateLevel']] == 0:
        files, dirs = get_names(url,args)
        [print('file: ',file) for file in files if args.prodlist if files if args.verbose] 
        if args.prodlist and not args.verbose:
            use_msg('Use --verbose to see file listing for product {0}.'.format(args.prod))
                
        if files and args.prodpull:
            download_prod(url,args,prod_path[args.prod][args.dival['url']])
            #dir_list.append(url)

        if dirs:
            for dirname in dirs:    
                if args.prodlist:
                    print(dirname)
                    subfiles, subdirs = get_names(url+dirname,args)
                    [print('file: ',dirname+file) for file in subfiles if subfiles if args.verbose] 
                else:
                    subfiles, subdirs = get_names(url+dirname,args)
                    if subfiles:
                        download_prod(url+dirname,args,prod_path[args.prod][args.dival['url']])
                        #dir_list.append(url+dirname)
            if not args.type:
                use_msg('Use --type for mosaic type.')                        
        if args.prodlist:
            use_msg('Use --pull instead of --list to pull/download the files.')
    
    # dateLevel = 1 indicates there are dirs within that go by date,
    elif prod_path[args.prod][args.dival['dateLevel']] == 1:     
        files, dirs = get_names(url,args)
        [print('file: ',file) for file in files if args.prodlist if files if args.verbose] 
        if args.prodlist and not args.verbose:
            use_msg('Use --verbose to see file listing for product {0}.'.format(args.prod))

        if files and args.prodpull:
            download_prod(url,args,prod_path[args.prod][args.dival['url']])
            #dir_list.append(url)

        if dirs:
            # trim by dates
            dirs = directory_dates(dirs,args)
            if args.byname and args.byname not in dirs:
                dirs.append(args.byname)

            for dirname in dirs:    
                if args.prodlist:
                    print(dirname)
                    subfiles, subdirs = get_names(url+dirname,args)
                    [print('file: ',dirname+file) for file in subfiles if subfiles if args.verbose] 
                       
                    if subdirs:
                        if args.type and args.type in subdirs or not args.type:
                            for subname in subdirs:
                                print(dirname+subname)
                                if args.verbose:
                                    subsubfiles, subsubdirs = get_names(url+dirname+subname,args)
                                    [print('file: ',dirname+subname+file) for file in subsubfiles if subsubfiles] 
                        
                else:
                    subfiles, subdirs = get_names(url+dirname,args)
                    if subfiles:
                        download_prod(url+dirname,args,prod_path[args.prod][args.dival['url']])
                        #dir_list.append(url+dirname)
                    
                    if subdirs:
                        if args.type and args.type in subdirs or not args.type:
                            for subname in subdirs:
                                subsubfiles, subsubdirs = get_names(url+dirname+subname,args)
                                if subsubfiles:
                                    download_prod(url+dirname+subname,args,prod_path[args.prod][args.dival['url']])
                                    #dir_list.append(url+dirname+subname)
                                if subsubdirs:
                                    print('subsubdirs',subsubdirs)    
                
            if args.prodlist:                
                use_msg('Use --pull instead of --list to pull/download files.')


    # dateLevel = 2 indicates there are dirs that go by date, one level down
    elif prod_path[args.prod][args.dival['dateLevel']] == 2:
        if not args.region:
            files, dirs = get_names(url,args)
            [print('file: ',file) for file in files if args.prodlist if files]     
            if args.prodlist and not args.verbose:
                use_msg('Use --verbose to see file listing for product {0}.'.format(args.prod))
                
            if files and args.prodpull:
                download_prod(url,args,prod_path[args.prod][args.dival['url']])
                #dir_list.append(url)
            
            if dirs:
                for dirname in dirs:
                    print(dirname)
                use_msg('Use --region REGION or --region all to list or download files for product {0}.'.format(args.prod))

                            
        elif args.region:
            files, dirs = get_names(url,args)
            [print('file: ',file) for file in files if args.prodlist if files if args.verbose] 
            if files and args.prodpull:
                download_prod(url,args,prod_path[args.prod][args.dival['url']])
                        
            if dirs:
                for dirname in dirs:
                    if args.prodlist:
                        subfiles, subdirs = get_names(url + dirname,args)
                        [print('file: ',dirname+file) for file in subfiles if subfiles if args.verbose]

                        if subdirs:
                            # trim by date
                            subdirs = directory_dates(subdirs,args)
                            if args.byname:
                                subdirs.append(args.byname)                       
                            [print(dirname+subname) for subname in subdirs if subdirs if not args.verbose]
                        
                            if args.verbose:
                                for subname in subdirs:
                                    subsubfiles, subsubdir = get_names(url + dirname + subname,args)
                                    [print('file: ',dirname+subname+file) for file in subsubfiles if subsubfiles] 
                                
                    else:
                        subfiles, subdirs = get_names(url + dirname,args)                        
                        if subfiles:
                            download_prod(url+dirname,args,prod_path[args.prod][args.dival['url']])
                            #dir_list.append(url+dirname)
                                
                        if subdirs:
                            # trim by date
                            subdirs = directory_dates(subdirs,args)
                            if args.byname:
                                subdirs.append(args.byname)
                       
                            for subname in subdirs:
                                subsubfiles, subsubdirs = get_names(url + dirname + subname,args)
                                if subsubfiles:
                                    download_prod(url+dirname+subname,args,prod_path[args.prod][args.dival['url']])
                                    #dir_list.append(url+dirname+subname)
                                    
                                if subsubdirs:
                                    print('huh ', subsubdirs)
                                    exit(-1)
            if args.prodlist and not args.verbose:
                use_msg('Use --verbose to list files.')
            if args.prodlist:
                use_msg('Use --pull instead of --list to pull/download files.')
                
        if args.prodpull:
            print('Done')
        