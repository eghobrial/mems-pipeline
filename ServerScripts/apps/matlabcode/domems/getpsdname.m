function [ psdname ] = getpsdname(pfilename)
% Usage: [ psdname ] = getpsdname(pfilename)
% Function gets info off pfile header
% Input: 
%   pfilename
% Output:
%      psdname
% Author: Eman Ghobrial
%         fMRI center, Radiology, UC San Diego
%         April 2013
%
%==================================================================================================

%%
%pfilename = 'P65024_spepgjCAIPI_Sens_110726_1151.7';
%pfilename = 'P65536_spepgjCAIPI_110726_1155.7';

pfid = fopen(pfilename, 'r', 'native', 'US-ASCII');
p.hdr = readgehdr22x(pfid);
p.hdrsize = p.hdr.rdb.off_data;
fclose(pfid);
psdname=p.hdr.image.psdname
%psdname=deblank(p.hdr.image.psdname)

end

