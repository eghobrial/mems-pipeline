#!/usr/bin/python
# memscopy.py is written by Peter Wong for UCSD Center for functional MRI
import sys,os,re,time,subprocess,shlex,datetime
import operator
#from datetime import datetime, timedelta
from optparse import OptionParser


elist = []
elist2 = []
tobecopied = []
timestamp = time.strftime('%Y_%m_%d_%H_%M_%S')

def main():
	print "\nStarting memscopy\n"	
	usage = "Usage: %prog [options] -d <new directory name> username"
	parser = OptionParser(usage)
	parser.add_option("-d", "--dir", dest="newdir", type="string", help="Specify directory name to be created on server, the default is the timestamp.")
	parser.add_option("-o", "--oldset", dest="oldset", default=False, action="store_true", help="Look for older Pfiles to copy.")
	(options, args) = parser.parse_args()
	if not options.newdir:   # if filename is not given
		parser.error('Directory name not given')
	if len(args) != 1:
		print parser.print_help() 
		parser.error("incorrect number of arguments")

	newdir = options.newdir
	oldset = options.oldset
	uname = sys.argv[-1]
	
	print "User: " +uname
	print "New Dir: " + newdir
	elist = []
	elist2 = []



	elist = getPfileDirList()

	if elist:
		for newpath in elist:
			newpathdate = os.path.getmtime(newpath)
			elist2.append([newpathdate,newpath])
		elist2.sort(reverse=True)
	else:
		print "The current directory does not contain any rds data, please run this program using the -o option."
		sys.exit(0)
	
	if oldset is False:
		(dateofdir, curdir) = elist2[0]
		print "The newest Pfile folder is: " + curdir +"\n"
	else:
		curdir = chooselistdir(elist2)
		print "The Pfile folder you selected is: " + curdir +"\n"

	PList=getPfileList(curdir)
	
	if PList:
		PList.sort(reverse=True)
		PListtmp = PList
		PList = sorted(PListtmp, key=operator.itemgetter(0))
		(etime0,fname0,pid0,sdate0,stime0,rds0,fsize0) = PList[0]
		print "Patient ID: "+pid0
		print "Scan Date: "+sdate0
		print "RDS: "  + rds0
		for etime,fname,pid,sdate,stime,rds,fsize in PList:
			tdiff = etime0 - etime
			if (tdiff < (60*60*6)): #to include files that span up to 6 hours
				print fname + '\tTime: ' + stime + '\tSize: ' + fsize
				tobecopied.append(curdir+"/"+fname)			
	else:
		print "The current directory does not contain any rds data, please run this program using the -o option."
		sys.exit(1)

	valid = {"yes":True, "y":True, "ye":True}
	try:
		response = raw_input("\nAre these the correct files to be copied? (Yes/No): ").lower()
	except:
		print 'Exiting, Copying files failed'
		sys.exit(0)
	if response in valid:
		try:		
			command_line = "rm -rf /tmp/mems"+timestamp+" ; mkdir /tmp/mems"+timestamp+""
			p = subprocess.Popen(command_line, shell=True)
			sts = os.waitpid(p.pid, 0)
			
			for fullpath in tobecopied:
				command_line = "ln -s " + fullpath + " /tmp/mems"+timestamp+""
				p = subprocess.Popen(command_line, shell=True)
				sts = os.waitpid(p.pid, 0)
		except:
			scpdone = False
		try:	
			command_line = "scp -rp /tmp/mems"+timestamp+" " + uname +"@fmrimems.ucsd.edu:~/data/"+newdir+"; rm -rf /tmp/mems"+timestamp+""
			print "Command: " +command_line
			p = subprocess.Popen(command_line, shell=True)
			sts = os.waitpid(p.pid, 0)
			scpdone = True
		except:
			scpdone = False			
		if scpdone:
			print "Finished copying files"
		else:
			print "Copying files failed"
			sys.exit(0)	
	else:
		print "Exiting, Copying files failed"
		
def getPfileDirList():		
	for top, dirs, files in os.walk('/data0/rt'):
		for subdir in dirs:
			if (re.search( r'[e|E]\d{3,}$', top, re.M|re.I) and re.match( r'^[e|E]\d{3,}$', subdir, re.M|re.I)):
				newpath =  os.path.join(top, subdir)
				newlist = os.listdir(newpath)
				foundPfile = False
				for filelist in newlist:
					if re.match( r'^[P]\d{3,}.*?\.7$', filelist, re.M|re.I):
						foundPfile = True
						break
				if (newpath not in elist and foundPfile and getPfileList(newpath)):
					elist.append(newpath)
	return elist
	
def getPfileList(curdir):
	PList = []
	rdscount = 0
	rdsvalid = {"1572864":True} #cv rds valid numbers
	dirList=os.listdir(curdir)
	for fname in dirList:
		i = 0
		rds = ""
		pid = sdesc = pfile = sdate = stime = ""
		if re.match( r'^[P]\d{3,}.*?\.7$', fname, re.M|re.I):
			i += 1
			#print 'checking: ' + curdir + '/' + fname
			command_line = 'ReadPool ' + curdir + '/' +fname
			args = shlex.split(command_line)
			outputlist = subprocess.Popen(args, stdout=subprocess.PIPE)
			for lines in outputlist.stdout:	
				if ('No raw data file' in lines):
					print 'Error: ' + curdir + '/' + fname + " Contains no Data"
					break
				elif ('Pfile: P0.7' in lines):
					print 'Error: ' + curdir + '/' + fname + " Contains no Data"
					break
				elif ('Patient ID:' in lines):
					pid = lines.strip().split( )
					pid = pid[3]
				elif ('Scan Date' in lines):
					sdate = lines.strip().split( )
					sdate = sdate[3]
				elif ('Scan Time' in lines):
					stime = lines.strip().split( )
					stime = stime[3]
				elif ('RDS mode:' in lines):
					rds = lines.strip().split( )
					rds = rds[2]
					break
			#print 'rds value is ' + str(rds)
			if rds in rdsvalid:
				#print 'rds value matched '
				month,day,year = sdate.strip().split("/")
				year = int(year) + 1900
				sdate = str(month)+"/"+str(day)+"/"+str(year)
				etime=time.mktime(time.strptime(sdate+" "+stime, "%m/%d/%Y %H:%M"))
				fsize=str(convert_bytes(os.path.getsize(curdir + '/' +fname)))
				PList.append([etime,fname,pid,sdate,stime,rds,fsize])
				rdscount += 1

	#print 'rdc count is ' + str(rdscount) + ' for ' + curdir
	if (rdscount == 0):
		return False
	return PList
			
def chooselistdir(elist2):
	j = 0
	print "Here's a list of the exam directory:"
	for (ldate,lpath) in elist2:

		print "["+str(j)+"] " + time.strftime("%d %b %Y %H:%M:%S ", time.localtime(ldate)) + " " + lpath
		j += 1
	try:
		number = raw_input('\nPlease enter a number of the directory you want to copy: ')
	except:
		print 'Exiting, Copying files failed'
		sys.exit(0)
	try:
		number = int(number)
		is_number = True
	except:
		is_number = False
	if is_number:
		print 'You entered the number %i.' % (number)
	else:
		print 'you did not enter a integer'
		sys.exit(0)

	try:
		(dateofdir, curdir) = elist2[number]
		in_range = True
	except:
		in_range = False
	if not in_range:
		print 'you did not enter a integer in the displayed range'
		sys.exit(0)		
	return curdir
		


def convert_bytes(bytes):
	bytes = float(bytes)
	if bytes >= 1099511627776:
		terabytes = bytes / 1099511627776
		size = '%.2fT' % terabytes
	elif bytes >= 1073741824:
		gigabytes = bytes / 1073741824
		size = '%.2fG' % gigabytes
	elif bytes >= 1048576:
		megabytes = bytes / 1048576
		size = '%.2fM' % megabytes
	elif bytes >= 1024:
		kilobytes = bytes / 1024
		size = '%.2fK' % kilobytes
	else:
		size = '%.2fb' % bytes
	return size
		
if __name__ == "__main__":
    main()

