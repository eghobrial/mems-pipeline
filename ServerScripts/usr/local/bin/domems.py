#! /usr/bin/python
import sys,os,re,time,subprocess,shlex,datetime
import getpass
from optparse import OptionParser,OptionGroup

timestamp = time.strftime('%Y%m%d-%H%M%S')
user = getpass.getuser()
filename = os.path.expanduser("temppipelinecommand"+timestamp+".sh")
completeIDName = os.path.expanduser("memslastid.txt")	
workdir = os.getcwd()

def main():

	print "\nStarting memsqueue\n"	
	usage = "%prog (This will take the current directory to be processed"
	parser = OptionParser(usage=usage)
	#parser.add_option("--anat", dest="anat", type="string", help="Anatomy file")
	parser.add_option("--procrest", dest="procrest", default=False, action="store_true", help="Process resting state")
	#group = OptionGroup(parser, "pfile1",
    #                "Calibration scan")
	#parser.add_option_group(group)				
	#group = OptionGroup(parser, "pfile2",
    #                "Data file")					
	#parser.add_option_group(group)
	(options, args) = parser.parse_args()
	#if len(args) < 2:
		#print parser.print_help() 
	#	parser.error("incorrect number of arguments")
	#anat = options.anat

	if options.procrest:
		procrest = "true"
	else:
		procrest = "false"
	#var = "\\\',\\\'".join(args) # stores all pfiles with comma into var
	
	FILE = open(filename,"w+")
	FILE.write("#PBS -N memspipeline \n")
	FILE.write("#PBS -q batch \n")
	FILE.write("#PBS -l nodes=1 \n")
	#FILE.write("#PBS -l cput=1000:00:00 \n")
	FILE.write("#PBS -c none \n")
	FILE.write("#PBS -m bea \n")
	FILE.write("#PBS -M memsadmin \n")
	FILE.write("#PBS -d " + workdir + " \n")
	FILE.write("/usr/local/bin/matlab -nodesktop -nosplash -nodisplay -r initstudyinfo_mems\(\\\'" + workdir + "\\\',\\\'" + procrest + "\\\'\) > & /var/log/mems/" + user + timestamp + ".log \n")
	FILE.close()
	#print "\nJobs exceeding 10 hours or will be terminated.\n"
	print "\nYour Job Info is:\n"
	command_line = "qsub "+filename
	p = subprocess.Popen(command_line, shell=True, stdout=subprocess.PIPE)


	line, err = p.communicate()
	
	IDOUTFILE = open(completeIDName,"w")
	IDOUTFILE.write(line)
	IDOUTFILE.close()
	print line
	
	print "\nCurrent job list:\n"
	command_line = "qstat"
	p = subprocess.Popen(command_line, shell=True)



		
if __name__ == "__main__":
    main()
