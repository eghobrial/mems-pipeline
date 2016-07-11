function [ uniquePfileID ] = getuniquePfileID( pfilename )
% Usage: [ uniquePfileID ] = getuniquePfileID( pfilename )
% Function gets info off pfile header
% Input: 
%   pfilename
% Output:
%      uniquePfileID
% Author: Eman Ghobrial
%         fMRI center, Radiology, UC San Diego
%         April 2013
%
%==================================================================================================

%%

pfid = fopen(pfilename,'r', 'native', 'US-ASCII');
p.hdr = readgehdr22x(pfid);
p.hdrsize = p.hdr.rdb.off_data;
fclose(pfid);
%uniquePfileID= sprintf('%s%s%s',deblank(p.hdr.exam.hospname),deblank(p.hdr.rdb.scan_date),deblank(p.hdr.rdb.scan_time))
uniquePfileID= sprintf('%s_%s',deblank(p.hdr.exam.hospname),deblank(pfilename))



end

