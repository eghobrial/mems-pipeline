function [jobID] = getJobID()
% Usage: [jobID] = getJobID()
% Function gets the job ID number off the text file
% 
%
% Input: 
% 
% Output:
%     jobID
%
% Author: Eman Ghobrial
%         fMRI center, Radiology, UC San Diego
%         August 2013
% 
%==================================================================================================
fid = fopen('memslastid.txt');
jobID = fscanf(fid,'%s');
fclose(fid);

