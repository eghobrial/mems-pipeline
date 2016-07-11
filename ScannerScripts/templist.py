#!/usr/bin/python

# templist.py is written by Peter Wong for UCSD Center for functional MRI
import sys,os,re,time,subprocess,shlex,datetime
import operator
#from datetime import datetime, timedelta
from optparse import OptionParser


def main():
    print "\nList Current Temp\n"
    readtempfile()

def readtempfile():
    file = open("/usr/g/service/log/paramdata/sriTemp.xml", "r")
    #wfile = open("/tmp/mems"+timestamp+"/temp.csv", "w")
    lines = file.readlines()
    file.close()
    rawtemp = []
    
    entry = 1	
    for index in range(len(lines)):
        match = re.search(r'Gradient Raw', lines[index])
        if match:
            rawtemp.append(lines[index+1].lstrip())
	    entry = entry+1
            #print entry 
            #a = re.split(',|"|>|<|\.',rawtemp)
	    
    rawtempt = rawtemp[entry-2]
    print rawtempt
    #print rawtempt.split()
    #print rawtemp[entry-2]
    a = re.split(',|"|>|<|\.',rawtempt)
    atime =  a[4]
    #match = re.search('([\w]+),',rawtempt)
    #if match:
    #   print match.group()

    amax = max(int(a[7]),int(a[8]),int(a[9]),int(a[10]))
    amax1 = amax/10
    s = 'Time: '+atime+' Current Max Temp: '+str(amax1)
    print s

if __name__ == "__main__":
    main()