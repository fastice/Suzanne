# Python 2 and 3:
from __future__ import print_function   
import os
import time
import sys
from datetime import datetime
#import utilities as u


def runMyThreads(threads,maxThreads,message,delay=0.2,prompt=False) :
    """ Loop through a list of  -- threads -- starting each one.   Allow -- maxThreads -- running at once.
 In each loop iteration check status and print number running along with -- message."""
    #
    # Optional prompt
    #
    if prompt :
        while(1) :
            ans=input('\n\033[1mDownload these ' +str(len(threads) )+ ' files ?  [y/n] \033[0m\n')
            if ans.lower() == 'y'  :
                break
            if ans.lower() == 'n'  :
                print("User prompted abort")
                sys.exit()
    
    notDone=True
    nRun=count=0
    running=[]
    # make sure always calling from home directory 
    home=os.getcwd()
    # delay 
    if delay < 0.2 :
        delay=0.2
    # format codes
    bs='\033[1m'      # 1 indicates bold
    norm='\033[0m'    # 0 indicates normal
    grs='\033[1;42m'  # 42 is green, 44 is blue
    bls='\033[1;46m'  # 46 is cyan, 40 is black
    # time for counter
    start=datetime.now()
    # loop counter
    n=0    
    print(grs,message,norm,end='\n')
    while notDone :
        #
        # Start a thread is < maxThreads
        #
        if n % 1 == 0 :
            timeElapsed=datetime.now() - start
            print('Threads (max =',maxThreads,')',norm,': nRunning ',bs,'{:5}'.format(nRun),norm,'nStarted ',bs,'{:5}'.format(count)  , \
                  norm,'nToGo ',bs,'{:5}'.format(len(threads)-count),'  ',bls,timeElapsed,norm ,'     '.ljust(maxThreads+8),end='\r')
            print('Threads (max =',maxThreads,')',norm,': nRunning ',bs,'{:5}'.format(nRun),norm,'nStarted ',bs,'{:5}'.format(count)  ,\
                  norm,'nToGo ',bs,'{:5}'.format(len(threads)-count),'  ',bls,timeElapsed,norm ,'     ',end='')            
            sys.stdout.flush()
            
        while count < len(threads) and nRun < maxThreads:
            # run thread and always make sure to return to current directory
            os.chdir(home)
            print('.',end='')
            sys.stdout.flush()
            threads[count].start()
            time.sleep(delay)
            running.append(threads[count])
            nRun+=1
            count +=1
            #
            # check status of threads
            #
        toRemove=[]
        #
        # loop through running thread to find threads that are done
        for t in running :
            if not t.isAlive() :
                toRemove.append(t)
        #
        # update list of running
        for t in toRemove :
                nRun-=1
                running.remove(t)
        time.sleep(1)        
        #
        print('',end='\r')
        n+=1
        if nRun == 0 and count >= len(threads) :
            notDone=False
    print('\n')
    #u.myalert('Threads Done') 
    return
