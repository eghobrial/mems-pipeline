function initstudyinfo_mems (pwd1,flag)
% This function takes one input (current directory) and constists of four parts
% Checks for errors email and write to user status file to confirm each step
% Stores info about the run in a postgresql database
% Part one: check to make sure we have valid  input
% Part two: Call and run recon script
% Part three: Call and run qa script
% Part four: Call and run processtop script
% Input: 
%   current directory
%
% Output:
%   
% Author: Eman Ghobrial
%         fMRI center, Radiology, UC San Diego
%         June 2013
%
%==================================================================================================


%% Add path to spiralfmap2.m
addpath('/apps/matlabcode/spiralfmap2', '-begin');
%addpath('/mnt/raid16/emang/data/Oct04rdstest', '-begin');

%% cd to current dir where data is
eval(['cd ' pwd1 ' ']);

%% Create the connection
javaclasspath('/usr/lib64/pgsql/postgresql-8.4-703.jdbc3.jar');
conn = database('mems_db2','emang','','Vendor','PostGreSQL');
%% get needed info and initialize flags
[jobID] = getJobID()
sdate=getsqldate();
fdatestamp = getfiledatestamp();
uname=getUserName();
hostname = getenv('HOST');
%to = sprintf('%s@fmrimems.ucsd.edu',deblank(uname))
to = sprintf('%s@%s',deblank(uname),deblank(hostname))
durl = pwd1;
surl = pwd1;
mkdir log;
datadir = pwd;
statusfilename = sprintf('%s/log/%s_%s',datadir,deblank(uname),deblank(fdatestamp))
sfile_id = fopen(statusfilename,'w');
pfns = 'init';
reconf=0;
reconm = 'Did not run';
qaf = 0;
qam = 'Did not run';
flags = 'not set';
msgs = 'not set';
rs1attrb = 'not set';
rs2attrb = 'not set';
scrptver = '1.0';
notes = 'add';

%% Check data
%determine which scan is which, we need 5 scans

[dvf, pfname, isdataav,pencode,prefix] = datavalidation_mems();

% 
 if pencode == 1
    peprefix = 'fwd';
 else
    peprefix = 'rev';
 end    

% pfileslist = dir (fullfile(sprintf('%s/*.7',deblank(pwd1))));

fprintf(sfile_id,sprintf('**** LOG FILE, Date: %s ****\n',sdate));
fprintf(sfile_id,sprintf('**** Job ID: %s ****\n',jobID));
fprintf(sfile_id,sprintf('**** Data Directory: %s ****\n',datadir));
if dvf  
    fprintf(sfile_id,'**Part one success: We have valid input files\n');
    
         %write step one we have valid inut
     pfns = sprintf('%s,%s,%s',pfname{1},pfname{2},pfname{3});
     %cpfnf = pfname{1};
     cpfnr = pfname{2};
     %pfnf = pfname{2};
     pfnr = pfname{3};
     %cfuid = getuniquePfileID(cpfnf);
     %rsfuid = getuniquePfileID(pfnf);
    cruid = getuniquePfileID(cpfnr);
    rsruid = getuniquePfileID(pfnr);
    pfuids = sprintf('%s,%s',cruid,rsruid);
    
else
    fprintf(sfile_id,'We do not have valid input files');
    sendmailto(to,'Errors','We do not have valid input',sdate,jobID,datadir);
    
%             % we do not have data file
%             %error and exit  
end           
 

 
%% Part Two: Run the recon script

try 
   
    run_recon_mems();
    reconf = 1;
    reconm = 'Recon module ran';
    %sfile_id
    fprintf(sfile_id,'**Part two success: Recon module ran fine\n');
   %  keyboard
catch me
    reconf = 0;
    reconm = me.identifier;
    fprintf(sfile_id,'**Part two failed: Error %s \n',reconm);
    ebody = sprintf('Recon module did not run. \n Error message: %s please check with the pipeline team ',reconm);
    sendmailto(to,'Errors',ebody,sdate,jobID,datadir);
    % mail the pipeline group
    % write to log file (for pipeline group only )
    % write to status file (to be seen by user)
    %log on the database
%% Insert initial record
% Define the table fields names
flags = int2str(reconf);
msgs = reconm;
rs1attrb = 'not set';
rs2attrb = 'not set';
colNames = {'stdyd','prcsd','scrptver','username','dataurl','pfilens','pfileuids','flags','msgs','rs1attrb','rs2attrb','notes'};
% Insert
insert (conn,'studyinfo',colNames, {sdate,sdate,scrptver,uname,durl,pfns,pfuids,flags,msgs,rs1attrb,rs2attrb,notes});
    %exit program
    rethrow(me);
end 
reconm = 'done';

%% Part Three: Run the QA script

%sname1 = sprintf('bcaipi_%s_%s_mems_pen1p10_realcmap',prefix,peprefix); 
sname1 = 'bcaipi_brik_e02+orig.BRIK'
try
    [snr2mean1, snr2max101, snr2std1] = qa_mems(sname1);
        
         rs1attrb=sprintf('%.3f,%.3f,%.3f',snr2mean1,snr2max101,snr2std1);
      
         qaf = 1;
        qam = 'QA module ran';
        fprintf(sfile_id,'**Part Three success: QA module ran fine\n');
catch qame
  qaf = 0;
  qam = qame.identifier;
  fprintf(sfile_id,'**Part three failed: Error %s \n',qam);
  ebody = sprintf('QA module did not run. \n Error message: %s please check with the pipeline team',qam)
  sendmailto(to,'Errors',ebody,sdate,jobID,datadir);
  % mail the pipeline group
  % write to log file (for pipeline group only )
  % write to status file (to be seen by user)
  %% Insert initial record
% Define the table fields names
colNames = {'stdyd','prcsd','scrptver','username','dataurl','pfilens','pfileuids','flags','msgs','rs1attrb','rs2attrb','notes'};
% Insert
insert (conn,'studyinfo',colNames, {sdate,sdate,scrptver,uname,durl,pfns,pfuids,flags,msgs,rs1attrb,rs2attrb,notes});
  rethrow(qame);
end   
%% Part 4 creating a structural nii file
processanat();
fprintf(sfile_id,'**Part Four success: writing a structure brik ran fine\n');
%% Part 5 topup/alignment pre-processing
processtopup_mems();
fprintf(sfile_id,'**Part Five success: Topup pre-processing ran fine\n');
%% Part 6 ME-ICA processing
processmeica();
fprintf(sfile_id,'**Part Six success: ME-ICA processing ran fine\n');

%% Insert final record
% Define the table fields names
flags = '1,1,1,1';
msgs = 'all ran fine';
colNames = {'stdyd','prcsd','scrptver','username','dataurl','pfilens','pfileuids','flags','msgs','rs1attrb','rs2attrb','notes'};
% Insert
insert (conn,'studyinfo',colNames, {sdate,sdate,scrptver,uname,durl,pfns,pfuids,flags,msgs,rs1attrb,rs2attrb,notes});

if ((reconf) && (qaf))
   % looks like everything went fine email user and write to status file
    sendmailto(to,'Success','Your job was submitted and executed succesfully',sdate,jobID,datadir);
    
end 

close(conn);
fclose(sfile_id);


