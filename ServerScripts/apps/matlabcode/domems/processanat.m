function processanat()
% Usage: processanat
% Function process the anat 
% Input: 
%   
% Output:
%     
% Author: Eman Ghobrial
%         fMRI center, Radiology, UC San Diego
%         April 2013
%
%==================================================================================================


dirlist = dir(fullfile('e*'));
eval(['cd ' dirlist.name ' ']);
dirlists = dir(fullfile('s*'));

for i = 1:length(dirlists)
    eval (['cd ' dirlists(i).name ' ']);
    info = dicominfo('i00001.CFMRI.1');
    if (strcmp(info.Private_0019_109c,'efgre3d'))
        % this is a structural scan?
        % Let us do to3d 
        eval(['!to3d -prefix anat.nii.gz i*']);
        eval(['!mv anat.nii.gz ../..']);
     %   fmap = {sprintf('%s/%s',dirlist.name,dirlists(i).name)};
        eval(['cd ..']);
        
    else
        eval(['cd ..']);
    end    
end    
 eval(['cd ..']);

