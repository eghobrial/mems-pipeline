function [dvf, pfname, isdataav,numofRS] = datavalidation()
% Usage: [dvf, pfname, isdataav,numofRS] = datavalidation
% Checks current directory and figure out which PFile is which to pass to
% the recon and processtop module
% Input: 
%
% Output:
%    dvf   the flag is set to 1 if the data is valid
%    pfname  cell array with pfilenames in the right order for recon
%    isdataav cell array to define whether the data set will be recon
%    numofRS  number of phase encoding direction data sets, return 1 for fwd and -1 for rev     
%			  2 for both
% Author: Eman Ghobrial
%         fMRI center, Radiology, UC San Diego
%         June 2013
%
%==================================================================================================

%% determine which scan is which
pfileslist = dir (fullfile('./*.7'));

idataav = [false false ...
              false false ...
              false false];
ihavesefwd = 0;
ihaveserev = 0;
ihavecalfwd = 0;
ihaversfwd = 0;
ihavecalrev = 0;
ihaversrev  = 0;
 
 for ii = 1: length(pfileslist) 
     if pfileslist(ii).bytes == 266602780 || pfileslist(ii).bytes == 799508764
         % This is either a calibortion file or an SE
         % dermine and label
        [u8 u9 u13 u14] = getmemsinfo(pfileslist(ii).name);
        if u9 == 1
            %this is a SpinEcho scan
            if u14 == 0
                %this forward scan, topup
                pfname(5) = cellstr(pfileslist(ii).name);
                isdataav(5) = true;
                ihavesefwd = 1;
            else
                %this is the rev scan, topup, epyneg = 1
                pfname(6) = cellstr(pfileslist(ii).name);
                isdataav(6) = true;
                ihaveserev = 1;
            end    
        else
            %this is a ref scan GRE
             if u14 == 0
                 disp (['I am tryin to save a ref scan file'])
                %this forward scan, cal
                pfname(1) =  cellstr(pfileslist(ii).name);
                isdataav(1) = true;
                ihavecalfwd = 1;
             else
                %this is rev scan, cal
                pfname(3) = cellstr(pfileslist(ii).name);
                isdataav(3) = true;
                ihavecalrev = 1;
            end   
        end 
     else
         % This is a Resting State Scan
         % Determine the PE and lable
         [u8 u9 u13 u14] = getmemsinfo(pfileslist(ii).name);
         % this a resting state scan
          if u14 == 0
                %this forward scan, rest
                pfname(2) = cellstr(pfileslist(ii).name);
                isdataav(2) = true;
                ihaversfwd = 1;
          else
                 %this rev scan, rest
                pfname(4) = cellstr(pfileslist(ii).name);
                isdataav(4) = true;
                ihaversrev = 1;
            end   
         
     end
 end
 
 
if ihavesefwd && ihaveserev && ihavecalfwd && ihaversfwd && ihavecalrev && ihaversrev
    % I have the 6 sets
     dvf = 1;
     numofRS = 2;
elseif ihavesefwd && ihaveserev && ihavecalfwd && ihaversfwd 
     dvf = 1;
     numofRS = 1;
elseif ihavesefwd && ihaveserev && ihavecalrev && ihaversrev   
     dvf = 1;
     numofRS = -1;
else
   %do not have valid data
    dvf = 0;  
end



        