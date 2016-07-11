function [dvf, pfname, isdataav,pencode,prefix] = datavalidation_mems()
% Usage: [dvf, pfname, isdataav,pencode] = datavalidation
% Checks current directory and figure out which PFile is which to pass to
% the recon and processtop module
% Input: 
%
% Output:
%    dvf   the flag is set to 1 if the data is valid
%    pfname  cell array with pfilenames in the right order for recon
%    isdataav cell array to define whether the data set will be recon
%    pencode  phase encoding direction, 1 for fwd and -1 for rev     
%
% Author: Eman Ghobrial
%         fMRI center, Radiology, UC San Diego
%         June 2013
%
%==================================================================================================

%% determine which scan is which start with a full set in one orientation%
datadir = pwd

%pfileslist = dir (fullfile('./*.7'))
pfileslist = dir(fullfile(sprintf('%s/*.7',datadir)));
idataav = [false false false...
              false false];
ihavesefwd = 0;
ihaveserev = 0;
ihavecalsess = 0;
ihavecalmems = 0;
ihavedatarev  = 0;
ihavedatafwd = 0;

 
 for ii = 1: length(pfileslist) 
     
        [u8 u9 u13 u14 yfov ras] = getmemsinfo_mems(pfileslist(ii).name)
        
        % need to make sure all data sets are in the same orientation
        
        if u9 == 1
            %this is a SpinEcho scan
            if u14 == 0
                %this forward scan, topup
                pfname(4) = cellstr(pfileslist(ii).name);
                isdataav(4) = true;
                ihavesefwd = 1;
            else
                %this is the rev scan, topup, epyneg = 1
                pfname(5) = cellstr(pfileslist(ii).name);
                isdataav(5) = true;
                ihaveserev = 1;
            end    
        else
            %this GRE scan
            if u13 == 0
                %this is my data
                pfname(3) = cellstr(pfileslist(ii).name);
                isdataav(3) = true;
                if u14 == 0
                    ihavedatafwd = 1;
                else
                    ihavedatarev = 1;
                end    
                    
            else   
                % this is a cal scan
                if yfov == 216
                    % fully sampled cal scan
                    pfname(1) =  cellstr(pfileslist(ii).name);
                    isdataav(1) = true;
                    ihavecalsess = 1;
                else
                    % part sampled cal scan
                    pfname(2) =  cellstr(pfileslist(ii).name);
                    isdataav(2) = true;
                    ihavecalmems = 1;
                end    
            end 
        end 
    
 end
 
   if (ras == 'I') || (ras == 'S')
    %axial data
    prefix = 'axi';
 elseif ras == 'L'
        prefix = 'sag';
  elseif (ras == 'P') 
        prefix = 'cor';
   else
       prefix = 'mems';
  end    
   
 
if ihavesefwd && ihaveserev && ihavecalsess && (ihavedatafwd||ihavedatarev) && ihavecalmems
    % I have the 5 sets
     dvf = 1;
     if ihavedatafwd
         pencode = 1;
     else
         pencode = -1;
     end    
    
else
   %do not have valid data
    dvf = 0;  
end



        