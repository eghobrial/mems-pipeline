function name = getUserName()
% Usage: name = getUserName()
% Function gets current user name
% Input: 
%
% Output:
%       name login user name
%
% Author: Eman Ghobrial
%         fMRI center, Radiology, UC San Diego
%         April 2013
%
%==================================================================================================
%
    if isunix()
        name = getenv('USER');
    else
        name = getenc('username');
    end
end