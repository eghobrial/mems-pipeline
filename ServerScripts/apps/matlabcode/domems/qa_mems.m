function [snr2mean, snr2max10, snr2std] = qa_mems(sname)
% function  qa_mems(sname)
% 
%INPUTS
%   sname: name of the data (in AFNI briks or NIFTI)
%          If AFNI briks, include '+orig' in the name
%          If NIFTI: include 'nii' or 'nii.gz'
%OUTPUTS:
%

if strfind(sname,'+orig')
    disp('analyze the afni brik');
    idx=strfind(sname,'+orig');
    sname=sname(1:idx-1);
    smode=1;
elseif strfind(sname,'.nii')
    disp('analyze nifti')
    idx=strfind(sname,'.nii');
    prefix=sname(1:idx-1);
    if ~exist([prefix '+orig.HEAD'])
    eval(['!3dcopy ' sname ' ' prefix '+orig' ]);
    end
    sname=sname(1:idx-1);
    smode=1;    
        
else
    disp('Wrong data format!');
    return;
end

%savefile='n';
%srcdir=[''];


%gobirn2_new(sname,smode,savefile,srcdir);
%gobirn2_new(snum,smode,savefile,srcdir,flip,slnum,im1,debugflag);


opwd = pwd


if ~exist('im1');
im1 = 3;
end



% BIRN QA analysis on the slnum-th slice
%eval(sprintf('chdir %s',srcdir));
disp('Reading into MATLAB');
r = sname;
h = ReadAFNIHead([r,'+orig.HEAD']);
B0 = ReadBRIK([r,'+orig.BRIK'],h.xdim,h.ydim,h.zdim,h.nvols,'int16',0);

if ~exist('slnum');
  slnum = ceil(size(B0,3)/2);
 end


B = squeeze(B0(:,:,slnum,:)); % get slnum-th slice
nim = size(B,3)
roisize = 15;
B = B(:,:,im1:nim);

if exist('mean+orig.BRIK');
  ! rm -f mean+orig.BRIK;
  ! rm -f mean+orig.HEAD;
end
if exist('mask+orig.BRIK');
  ! rm -f mask+orig.BRIK;
  ! rm -f mask+orig.HEAD;
end
if exist('mask1+orig.BRIK');
  ! rm -f mask1+orig.BRIK;
  ! rm -f mask1+orig.HEAD;
end



afnistr=sprintf('! 3dTstat -mean -prefix ./mean  ''%s+orig[%d-%d]''  ',sname,im1-1,nim-1);
eval(afnistr);

afnistr = sprintf('! 3dAutomask -q -dilate 4 -prefix mask  mean+orig ');
eval(afnistr);

afnistr = sprintf('! 3dAutomask -q  -prefix mask1  mean+orig ');
eval(afnistr);

%mean image
h = ReadAFNIHead(['mean+orig.HEAD']);
mean0 = ReadBRIK(['mean+orig.BRIK'],h.xdim,h.ydim,h.zdim,h.nvols,'float32',0);
imean = mean0(:,:,slnum);

%dilated mask
h = ReadAFNIHead(['mask+orig.HEAD']);
mask0 = ReadBRIK(['mask+orig.BRIK'],h.xdim,h.ydim,h.zdim,h.nvols,'char',	0);
mask = mask0(:,:,slnum);

%non-dilated mask
h = ReadAFNIHead(['mask1+orig.HEAD']);
mask01 = ReadBRIK(['mask1+orig.BRIK'],h.xdim,h.ydim,h.zdim,h.nvols,'char',	0);
mask1 = mask01(:,:,slnum);

tr= 2000;  % set to 2 sec for now. should be read from the header.  

%disp('Running BIRN QA Analysis');
[snr2,snr2mean, snr2max10, snr2std] = qa2(B,roisize, mask1);
%[rms,sfnr,rdc,drift,drift2] = qa(B,roisize,tr,snr2);

saveas(100, [sname '_QA.jpg']);

% AUTOMATED REPORTING OF PASS OR FAIL
disp('*****************************************')
fprintf('Mean tSNR                  = %.3f  (Taret:)\n',snr2mean);
fprintf('Top 10 percent tSNR        = %.3f  (Taret:)\n',snr2max10);
fprintf('Std tSNR                   = %.3f  (Taret:)\n',snr2std);
disp('*****************************************')


% if (snr2 < 350 | rms > 0.06 | rdc<4.5 | drift2 >0.007)
% 
%   disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
%   disp('!!!!!!THIS SCAN FAILS THE BIRN TEST!!!!!!');
%    disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
% 
%   for k = 1:5;beep;pause(0.5);end;
%   status = 'FAIL';
% else
% 	disp('******************************************');
% 	disp('!!!!!!THIS SCAN PASSES THE BIRN TEST!!!!!!');
% 	disp('******************************************');
% 
%   status = 'PASS';
% end


chdir(opwd);




function [snr2,snr2mean, snr2max10, snr2std] = qa2(B,roisize, mask);
  
% Check the fBIRN calcs using vectorized code.
% actually not faster because I'm flattening the whole volume!
% could rewrite to just flatten the ROI, but not slow enough to warrant
% that.   
% ttliu@ucsd.edu
  
  if ~exist('mask')
      mask=1
  end
  
  numimgs = size(B,3);
  Bf = flatten3(B,2);
  Bf1 = flatten3(B,1);
  span = -(fix(roisize/2))+(0:(roisize-1));
  roix = span+32;
  roiy = span+32;
  Broi00 = B(roix,roiy,:);
  Broi0 = Bf1(roix,roiy,:);
  Broi = Bf(roix,roiy,:);
  
  mBv = mean(mean(Broi,1),2);
  mBv0 = mean(mean(Broi00,1),2);  
  sBv = std(mBv);
  snr1 = sBv/mean(mBv)*100;
  
  % average SNR in each voxel in the ROI
%  Bstd = std(Broi0,[],3);  % original code just did linear fit
  Bstd = std(Broi,[],3);
  Bmean = mean(Broi,3);
  snr2 = mean(mean(Bmean./Bstd));

  
  
  %plot SNR2map
  Bfstd = std(Bf,[],3);
  Bfmean = mean(Bf,3);
  snr2map=(Bfmean./Bfstd);
  snr2mean=mean(nonzeros(snr2map(:).*mask(:)));
  snr2std=std(nonzeros(snr2map(:).*mask(:)));
  
  temp=sort(abs(snr2map(:).*mask(:)),'descend');
  nv=length(snr2map(:));
  snr2max10=mean(temp(1: round(nv/10)));
  
  temp2=abs(snr2map(:).*mask(:));
  histBins=[5:5:100];
  N = histc(nonzeros(temp2),histBins);
  
  
  figure(100);
  subplot(1,2,1)
  imagesc(flipud(snr2map.*mask),[0 100]);
  title(sprintf('SFNR: Mean = %.2f, top10%% = %.2f',snr2mean,snr2max10));
  axis square;
  colorbar
  
  subplot(1,2,2)
  bar(histBins,N);xlim([0,100]);
  axis square
  title(sprintf('SFNR: Mean = %.2f, std = %.2f',snr2mean,snr2std));

  % average difference image calc a la Gary's method
  % I don't quite understand all the scaling that's going on
  diffim0 = mean(Broi00(:,:,2:2:numimgs),3)-mean(Broi00(:,:,1:2:numimgs),3);
  diffim = diffim0*198/2;
  diffsig = std(diffim(:))/sqrt(198);
  snr3 = mean(mBv0)/diffsig;
 
  
  %  do the RDC calc
  r1 = 1;r2 = roisize;  
  F = NaN*ones(roisize,1);
  for thisroisize = r1:r2
   span = -(fix(thisroisize/2))+(0:(thisroisize-1));
   roix = span+32;
   roiy = span+32;    
   thisBroi = squeeze(Bf(roix,roiy,:));    
   if thisroisize == 1
   thismean = thisBroi;
   else
   thismean = mean(mean(thisBroi,1),2);
   end
   
   F(thisroisize) = std(thismean)/mean(thismean)*100;
  end
  rdc = F(1)/F(roisize);
  

  fprintf('Sanity check: RMS %.4f SNR %.1f  SFNR %.1f rdc %.1f\n',snr1,snr3,snr2,rdc);
  
  


  
function Bout = flatten(B,lorder);
   
% function Bout = flatten(B,lorder);
%  flattens a 1-D time series B
%  or a 3-dimensional matrix B where the third dimension is time
%  or a 4-dimensional matrix B where the 4th dimension is time

%021111 yb vectorized function

sB=size(B);

if length(size(B)) == 2
    one_d = 1;
    T = length(B);
elseif length(sB) == 3
    one_d = 0;nslices = 1;
    [N1,N2,T] = size(B);
elseif length(sB) == 4
    one_d = 0;
    [N1,N2,nslices,T] = size(B);
end




S       = legendremat(lorder,T);
PS      = eye(T)-S*inv(S'*S)*S';
Bout    = zeros(sB);


if one_d
    Bout = PS*B(:)+mean(B(:));
else
    
    %     Bout = zeros(sB);
    if nslices > 1
        for islice = 1:nslices
            for row = 1:N1;
              
                squeezeB=squeeze(B(row,:,islice,:));
                Bout(row,:,islice,:)=(PS*squeezeB'+repmat(mean(squeezeB,2),1,sB(4))')';
                
                
            end
        end
    else
        for row = 1:N1;
            squeezeB=squeeze(B(row,:,:));
            Bout(row,:,:)=(PS*squeezeB'+repmat(mean(squeezeB,2),1,sB(3))')';
            
        end
        
    end    
end
  


function lmat = legendremat(m,n,recur);
 
% lmat = legendremat(n,m);
%
% makes a (n)x(m+1) matrix where the columns are legendre polynomials
% with unit norm.
%
%   n = number of time points;
%   m = maximum order of legendred polynomial
%       (0th order = DC, 1st order = linear trend, etc.)
%   recur: 1: use recursive routine; 0 use hardwired routines up to m = 6
%
% send comments to ttliu@ucsd.edu

if ~exist('recur') & m <=6
	recur = 0;
end

if (mod(n,2) == 0) %even number of points;
	taxis = ((-n/2+.5):(n/2-0.5))/(n/2-0.5);
else
	taxis = (-(n-1)/2:(n-1)/2)/(n/2);
end
taxis = taxis(:);
lmat = NaN*ones(n,m+1);

if recur
	for k = 1:(m+1);
		lmat(:,k) = legpoly(k-1,taxis);
		lmat(:,k) = lmat(:,k)/norm(lmat(:,k));
	end
else
	for k = 1:(m+1)
		switch (k-1)
			case 0
				pl = ones(size(taxis));
				
			case 1
				pl = taxis;
			case 2
				pl = (3*taxis.^2-1)/2;
			case 3
				pl = (5*taxis.^3-3*taxis)/2;
			case 4
				pl = (35*taxis.^4-30*taxis.^2+3)/8;
			case 5
				pl = (63*taxis.^5-70*taxis.^3+15*taxis)/8;
			case 6
				pl=(231*taxis.^6 - 315*taxis.^4+105*taxis.^2-5);

				
			end
			
		lmat(:,k) = pl / norm(pl);
		
		
	end
end








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% function: ReadAFNIHead

% given the name of an AFNI HEAD

% file this function reads the 

% contents and returns information

% in a structure where the fields 

% are arranged as follows:

% contents of the structure are:

% headinfo.xdim ( x dimension size )

% headinfo.ydim ( y dimension size )

% headinfo.zdim ( z dimension size )

% headinfo.xvox ( x voxel size )

% headinfo.yvox ( y voxel size )

% headinfo.zvox ( z voxel size )

% headinfo.nvols ( number of sub-briks, i.e. for 3D+time )

% headinfo.orient ( orientation code, e.g. 351 )

% the orientation code is 3 numbers and corresponds to the following

% convention

% 0 = R-L

% 1 = L-R

% 2 = P-A

% 3 = A-P

% 4 = I-S

% 5 = S-I

% 

% Timothy M. Ellmore (tellmore@nih.gov)

% Laboratory of Brain and Cognition

% National Institute of Mental Health



function headinfo =  ReadAFNIHead(hname)



fid=fopen(hname);

count = 1;

while 1

 line = fgetl(fid);

 if ~isstr(line), break, end

 

 if(strcmp('name = DELTA',line) || strcmp('name  = DELTA',line))

  voxline = count + 2;

 end



 if(strcmp('name = DATASET_DIMENSIONS',line))

  dimline = count + 2;

 end



 if(strcmp('name = BRICK_TYPES',line))

  nvolsline = count + 1;

 end



 if(strcmp('name = ORIENT_SPECIFIC',line))

  orientline = count + 2;

 end



 % disp(line)

 count = count + 1;

end

fclose(fid);



fid=fopen(hname);

count = 1;

while 1

 line = fgetl(fid);

 if ~isstr(line), break, end

 

 if(count == voxline)

   voxinfo = sscanf(line,'%f %f %f');

 end



 if(count == dimline)

  diminfo = sscanf(line,'%d %d %d %d %d');

 end



 if(count == nvolsline)

  nvolsinfo = sscanf(line,'%s = %d');

 end



 if(count == orientline)

  orientinfo = sscanf(line,'%d %d %d');

 end

 

 count = count + 1;

end

fclose(fid);



headinfo.xdim = diminfo(1);

headinfo.ydim = diminfo(2);

headinfo.zdim = diminfo(3);

headinfo.xvox = abs(voxinfo(1));

headinfo.yvox = abs(voxinfo(2));

headinfo.zvox = abs(voxinfo(3));

headinfo.nvols = nvolsinfo(length(nvolsinfo));

headinfo.orient = orientinfo;




function V = ReadBRIK(fname,xdim,ydim,zdim,timepoints,type,byteswap)
% ReadBRIK function to read 3D+time AFNI BRIKs
% of any type and dimensionality
%
% Example:
% brikfname = 'ASt3avvr+orig.BRIK'
% BRIKDATA = ReadBRIK(brikfname,64,64,16,100,'short');
% BRIKDATA is now a 4D matrix (xdim,ydim,zdim,timepoint)

% Written December 4, 1998 by Timothy M. Ellmore
% Laboratory of Brain and Cognition, NIMH

disp(' ')
disp('**********************************')
disp(' ')
disp('ReadBRIK: reading raw data . . . .')
if ~exist('byteswap');byteswap = 1;end;
if byteswap
     fid = fopen(fname, 'r','b');
else
     fid = fopen(fname, 'r');
end

data = fread(fid, [xdim * ydim * zdim * timepoints], type);
fclose(fid);
disp('ReadBRIK: done reading raw data !')
disp(' ')

disp('ReadBRIK: reshaping raw data to 3D+time matrix. . . .')
V = reshape(data,xdim,ydim,zdim,timepoints);
disp('ReadBRIK: done reshaping raw data to 3D+time matrix !')
disp(' ')
disp('**********************************')



function Bout = flatten3(B,lorder);
   
% function Bout = flatten3(B,lorder);
%  flattens a 1-D time series B
%  or a 3-dimensional matrix B where the third dimension is time
%  or a 4-dimensional matrix B where the 4th dimension is time

%021111 yb vectorized function

sB=size(B);

if length(size(B)) == 2
    one_d = 1;
    T = length(B);
elseif length(sB) == 3
    one_d = 0;nslices = 1;
    [N1,N2,T] = size(B);
elseif length(sB) == 4
    one_d = 0;
    [N1,N2,nslices,T] = size(B);
end




S       = legendremat(lorder,T);
PS      = eye(T)-S*inv(S'*S)*S';
Bout    = zeros(sB);


if one_d
    Bout = PS*B(:)+mean(B(:));
else
    
    %     Bout = zeros(sB);
    if nslices > 1
        for islice = 1:nslices
            for row = 1:N1;
              
                squeezeB=squeeze(B(row,:,islice,:));
                Bout(row,:,islice,:)=(PS*squeezeB'+repmat(mean(squeezeB,2),1,sB(4))')';
                
                
            end
        end
    else
        for row = 1:N1;
            squeezeB=squeeze(B(row,:,:));
            Bout(row,:,:)=(PS*squeezeB'+repmat(mean(squeezeB,2),1,sB(3))')';
            
        end
        
    end    
end
