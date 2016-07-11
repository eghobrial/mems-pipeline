function [ u8 u9 u13 u14 yfov ras] = getmemsinfo_mems(pfilename)
% Usage: [ u8 u9 u13 u14 ] = getmemsinfo(pfilename)
% Function gets info off pfile header
% Input: 
%   pfilename
% Output:
%      userdata8 
%      userdata9 (SpinEcho (1))
%      userdata13
%      userdata14 (PhaseEncoding Dir)
% Author: Eman Ghobrial
%         fMRI center, Radiology, UC San Diego
%         April 2013
%
%==================================================================================================



%% rhuser constants needed to read bitfields
% nl
nlBITS = 6;
nlPOSN = 0;
% phases
phasesBITS = 6;
phasesPOSN = 10;
% vte
vteBITS = 3;
vtePOSN  = nlBITS + 2;
% sense
senseBITS = 4;
sensePOSN = vtePOSN + vteBITS;
% sptraj
sptrajBITS = 4;
sptrajPOSN = sensePOSN + senseBITS;
% gtype
gtypeBITS = 4;
gtypePOSN = 0;
% spdir
spdir1BITS = 1;
spdir2BITS = 1;
spdir1POSN = gtypeBITS + 1;
spdir2POSN = spdir1POSN + spdir1BITS;
% dif
difBITS = 1;
difPOSN = spdir2POSN + spdir2BITS;
% fsat
fsatBITS = 1;
fsatPOSN = difPOSN + difBITS;
% fpmode
fpmodeBITS = 1;
fpmodePOSN = fsatPOSN + fsatBITS;
% fiestamode
fiestamodeBITS = 1;
fiestamodePOSN = fpmodePOSN + fpmodeBITS;
% zbalance
zbalanceBITS = 1;
zbalancePOSN = fiestamodePOSN+ fiestamodeBITS;
% rf1mode
rf1modeBITS = 1;
rf1modePOSN = zbalancePOSN + zbalanceBITS;
% oppseq -- is the sequence SE (1) or GRE (2)
oppseqBITS = 2;
oppseqPOSN = rf1modePOSN + rf1modeBITS;
% epiflats
epiflatBITS = 8;
epiflatPOSN = 0;



pfid = fopen(pfilename, 'r', 'native', 'US-ASCII');
p.hdr = readgehdr22x(pfid);
p.hdrsize = p.hdr.rdb.off_data;
fclose(pfid);
u8 = p.hdr.image.user8;
u9 = bit_read(p.hdr.rdb.user9, oppseqPOSN, oppseqBITS);
%u9=p.hdr.rdb.user9;
u13=p.hdr.image.user13;
u14=p.hdr.image.user14;
yfov = p.hdr.image.dfov_rect;
%scantime = p.hdr.rdb.scan_time
%psdname=deblank(p.hdr.image.psdname)

ras = p.hdr.series.start_ras;

function y = bit_read(x, xposn, maskbits)
% performs:
%   y = (x >> xposn)  & ~(~0 << maskbits)

    %x_bitshft = bitsrl(fi(int32(x)), xposn);
    %bitmask = bitcmp(bitsll(bitcmp(fi(int32(0))), maskbits));
    %y = bin2dec(bin(bitand(x_bitshft, bitmask)));
    x_bitshft = bitshift(uint32(x), -xposn);
    bitmask = bitcmp(bitshift(bitcmp(uint32(0)), maskbits));
    y = bitand(x_bitshft, bitmask);
    y = double(y);
