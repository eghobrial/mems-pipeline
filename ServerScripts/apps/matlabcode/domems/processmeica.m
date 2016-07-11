function processmeica()
% Usage: processmeica
% Function calls meica.py
% -- Multi-Echo Independent Components Analysis (ME-ICA) v2.0 --

% Please cite: 
% Kundu, P., Inati, S.J., Evans, J.W., Luh, W.M. & Bandettini, P.A. Differentiating 
% BOLD and non-BOLD signals in fMRI time series using multi-echo EPI. NeuroImage (2011).
% Input: 
%   
% Output:
%     
% Author: Eman Ghobrial
%         fMRI center, Radiology, UC San Diego
%         July 2013
%
%==================================================================================================

e2='2';
e1='1';
e3='3';
eval(sprintf('!python2.7 /apps/me-ica/meicaX.py -e 13.8,32.5,51.2 -d "myhifipa_e0[%s,%s,%s]_afni_al.nii.gz" -f 1mm -b 14 -a anat.nii.gz --t2salign --cpus=1 --label=_f1mm_hp0_daw10',e2,e1,e3));