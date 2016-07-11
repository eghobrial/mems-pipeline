function initstudyinfo(pfn1,pfn2)
% This function takes two p files and constists of three parts
% Check for errors email and write to user status file to confirm each step
% Part one: check to make sure we have valid  input
% Part two: Call and run recon script
% Part three: Call and run qa script

%% Add path to spiralfmap2.m
addpath('/mnt/raid16/apps/matlabcode/spiralfmap2', '-begin');
%addpath('/mnt/raid16/emang/data/Oct04rdstest', '-begin');

pwd

%% Create the connection
javaclasspath('/usr/lib/pgsql//postgresql-8.4-703.jdbc3.jar');
conn = database('mems_db','emang','','Vendor','PostGreSQL');
%% get needed info and initialize flags
sdate=getsqldate();
fdatestamp = getfiledatestamp();
uname=getUserName();
to = sprintf('%s@fmrimems.ucsd.edu',deblank(uname))
durl = pwd;
surl = pwd;
statusfilename = sprintf('%s_%s',deblank(uname),deblank(fdatestamp));
sfile_id = fopen(statusfilename,'w');
reconf=0;
reconm = 'Did not run';
qaf = 0;
qam = 'Did not run';

% Part One: Verify the input make sure we have a coil senstivity pfile
strind = strfind(pfn1, '_Sens');
if isempty(strind)
  %check other pfile
  strind = strfind(pfn2, '_Sens');
  if isempty(strind)
    %user did not provide a coil senstivity file
    % error and exit
  else     
     %check first file to make sure you have data and switch order
     strind = strfind(pfn1, '_spepecw5');
     if isempty(strind)
         %no data file
         %error and exit
     else
         pfns=pfn2;
         pfndata=pfn1;
     end
  end  
else
      strind = strfind(pfn2, '_spepecw5');
        if ~isempty(strind)
            %we have both files
            pfns=pfn1;
             pfndata=pfn2;
             %write step one we have valid inut
             fprintf(sfile_id,'**Part one success: We have valid input files\n');
        else
            fprintf(sfile_id,'We do not have valid input files');
            % we do not have data file
            %error and exit
        end    

end  

% having right inputs
spfuid = getuniquePfileID(pfn1);
dpfuid = getuniquePfileID(pfn2);

%Part Two: Run the recon script

try 
  %  run_recon(pfns,pfndata);
   %  reconf = 1;
    reconm = 'Recon module ran';
    fprintf(sfile_id,'**Part two success: Recon module ran fine\n');
catch me
    reconf = 0;
    reconm = me.identifier;
    fprintf(sfile_id,'**Part two failed: Error %s \n',reconm);
    ebody = sprintf('Recon module did not run; error message %s please check with the pipeline team ',reconm);
    sendmailto(to,'Problems',ebody);
    % mail the pipeline group
    % write to log file (for pipeline group only )
    % write to status file (to be seen by user)
    %log on the database
     %% Insert initial record
% Define the table fields names
colNames = {'studydate','username','dataurl','statusfurl','dpfilename','dpfileuid','spfilename','spfileuid','reconflag','reconoutput','qaflag','qaoutput'};
% Insert
insert (conn,'studyinfo',colNames, {sdate,uname,durl,surl,pfn2,dpfuid,pfn1,spfuid,reconf,reconm,qaf,qam});
    %exit program
    rethrow(me);
end   
    


%reconf = 1;
reconm = 'done';


sname = sprintf('%s_bcaipi_sensebrik+orig', pfndata(1:end-2));

%Part Three: Run the QA script
try
  qa_mems(sname);
  qaf = 1;
  qam = 'QA module ran';
  fprintf(sfile_id,'**Part Three success: QA module ran fine\n');
catch qame
  qaf = 0;
  qam = qame.identifier;
  fprintf(sfile_id,'**Part three failed: Error %s \n',qam);
  ebody = sprintf('QA module did not run; error message %s please check with the pipeline team',qam)
  sendmailto(to,'Problems',ebody);
  % mail the pipeline group
  % write to log file (for pipeline group only )
  % write to status file (to be seen by user)
  %% Insert initial record
% Define the table fields names
colNames = {'studydate','username','dataurl','statusfurl','dpfilename','dpfileuid','spfilename','spfileuid','reconflag','reconoutput','qaflag','qaoutput'};
% Insert
insert (conn,'studyinfo',colNames, {sdate,uname,durl,surl,pfn2,dpfuid,pfn1,spfuid,reconf,reconm,qaf,qam});

  rethrow(qame);
end   
    

%% Insert initial record
% Define the table fields names
colNames = {'studydate','username','dataurl','statusfurl','dpfilename','dpfileuid','spfilename','spfileuid','reconflag','reconoutput','qaflag','qaoutput'};
% Insert
insert (conn,'studyinfo',colNames, {sdate,uname,durl,surl,pfn2,dpfuid,pfn1,spfuid,reconf,reconm,qaf,qam});

if ((reconf) && (qaf))
    {
    % looks like everything went fine email user and write to status file
    sendmailto(to,'Success','Your job was submitted and executed succesfule');
    }


close(conn);
fclose(sfile_id);

end
