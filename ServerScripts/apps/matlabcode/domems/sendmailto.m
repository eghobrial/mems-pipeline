function sendmailto (to,subject,body,sdate,jobID,datadir)
% Usage: sendmailto (to,subject,body,sdate,jobID,datadir)
% Function sends email
% Input: 
%   to
%   subject
%   body
% Output:
%      
% Author: Eman Ghobrial
%         fMRI center, Radiology, UC San Diego
%         April 2013
%
%==================================================================================================

hostname = getenv('HOST');
%setpref('Internet','SMTP_Server','fmrimems.ucsd.edu');
setpref('Internet','SMTP_Server',hostname);
setpref('Internet','E_mail','memsadmin@fmrimems.ucsd.edu');
% Send the email
subjects = sprintf('Your job number %s terminated with %s',jobID,subject);
bodys = sprintf ('Date: %s \n Data Directory: %s \n %s ',sdate, datadir,body)
sendmail(to,subjects,bodys);

end