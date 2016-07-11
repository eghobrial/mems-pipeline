function [ sqldate ] = getfiledatestamp()
% Usage: [ sqldate ] = getfiledatestamp()
% Function gets current date
% Input: 
%
% Output:
%       sqldate current date/time (sql format
%
% Author: Eman Ghobrial
%         fMRI center, Radiology, UC San Diego
%         April 2013
%
%==================================================================================================

%%
dstr = datestr(now);

dvec = datevec(dstr);

sqldate= sprintf('%4d-%02d-%02d-%02d:%02d:%02d',dvec(1,1),dvec(1,2),dvec(1,3),dvec(1,4),dvec(1,5),dvec(1,6));



end
