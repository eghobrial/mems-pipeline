function processtopup()
% Usage: processtopup
% Function prep data for registeration, motion correction using
% align_epi_anat.py afni script
% and distorion correction using FSL topup tool.
% Input: 
%
% Output:
%       
%
% Author: Eman Ghobrial
%         fMRI center, Radiology, UC San Diego
%         April 2013
%
%==================================================================================================
%% Call Data Validation to get the flags
[dvf,pfname,isdataav,numofRS] = datavalidation()

%% Make dir for processed data and Move BRIKs to
mkdir processed;
eval(['!cp *.BRIK processed']);
eval(['!cp *.HEAD processed']);
eval(['!cp *.mat processed']);
eval(['!cp *.tif processed']);
eval(['!cp *.csv processed']);
eval(['!cp *.jpg processed']);
cd processed;

%% Converting BRIKs to NIFTI
eval(['!3dAFNItoNIFTI -prefix PhaseOne.nii.gz topup_epyneg0brik+orig']);
eval(['!fslroi PhaseOne.nii.gz PhaseOne0.nii.gz 0 1']);
eval(['!3dAFNItoNIFTI -prefix PhaseTwo.nii.gz topup_epyneg1brik+orig']);
eval(['!fslroi PhaseTwo.nii.gz PhaseTwo0.nii.gz 0 1']);
eval(['!fslmerge -t BothPhases PhaseOne PhaseTwo']);
if numofRS == 2
    eval(['!3dinfo bcaipi_spep_hcp_rest_fwdbrik+orig > restapinfo.txt']);
    eval(['!3dinfo bcaipi_spep_hcp_rest_revbrik+orig > restpainfo.txt']);
    eval(['!3dAFNItoNIFTI -prefix restap.nii.gz bcaipi_spep_hcp_rest_fwdbrik+orig']);
    eval(['!3dAFNItoNIFTI -prefix restpa.nii.gz bcaipi_spep_hcp_rest_revbrik+orig']);
    eval(['!3dToutcount -autoclip -range restap.nii.gz > restap_outcount.1D']);
    eval(['!3dToutcount -autoclip -range restpa.nii.gz > restpa_outcount.1D']);
elseif numofRS == 1
    eval(['!3dinfo bcaipi_spep_hcp_rest_fwdbrik+orig > restapinfo.txt']);
    eval(['!3dAFNItoNIFTI -prefix restap.nii.gz bcaipi_spep_hcp_rest_fwdbrik+orig']);
    eval(['!3dToutcount -autoclip -range restap.nii.gz > restap_outcount.1D']);
elseif numofRS == -1   
    eval(['!3dinfo bcaipi_spep_hcp_rest_revbrik+orig > restpainfo.txt']);
    eval(['!3dAFNItoNIFTI -prefix restpa.nii.gz bcaipi_spep_hcp_rest_revbrik+orig']);
    eval(['!3dToutcount -autoclip -range restpa.nii.gz > restpa_outcount.1D']);
end    

%% Motion Correction - Using align_epi_anat
if numofRS == 2
    rep1 = getRep('restap_outcount.1D');
    rep2 = getRep('restpa_outcount.1D');
    eval(['!/apps/afni_bin_new/linux_openmp_64/3dSkullStrip -input PhaseOne0.nii.gz -overwrite -push_to_edge -init_radius 75 -orig_vol -prefix PhaseOne_ns.nii.gz3dSkullStrip -input PhaseOne0.nii.gz -overwrite -push_to_edge -init_radius 75 -orig_vol -prefix PhaseOne_ns.nii.gz']);
    eval(sprintf('!align_epi_anat.py -anat PhaseOne_ns.nii.gz -epi restap.nii.gz -volreg_base %d  -epi_base 10 -deoblique off -overwrite -epi2anat -anat_has_skull no -tshift off -cost nmi -Allineate_opts  "-warp shr"',rep1));
    eval(['!mv restap.nii.gz_al.nii.gz restap_afni_al.nii.gz']);
    eval(['!/mnt/raid16/apps/afni_bin_new/linux_openmp_64/3dSkullStrip -input PhaseTwo0.nii.gz -overwrite -push_to_edge -init_radius 75 -orig_vol -prefix PhaseTwo_ns.nii.gz']);
    eval(sprintf('!align_epi_anat.py -anat PhaseTwo_ns.nii.gz -epi restpa.nii.gz -volreg_base %d -epi_base 10 -deoblique off -overwrite -epi2anat -anat_has_skull no -tshift off -cost nmi -Allineate_opts "-warp shr"',rep2));
    eval(['!mv restpa.nii.gz_al.nii.gz restpa_afni_al.nii.gz']);
elseif numofRS == 1
    rep1 = getRep('restap_outcount.1D');
    eval(['!/apps/afni_bin_new/linux_openmp_64/3dSkullStrip -input PhaseOne.nii.gz -overwrite -push_to_edge -init_radius 75 -orig_vol -prefix PhaseOne_ns.nii.gz']);
    eval(sprintf('!align_epi_anat.py -anat PhaseOne_ns.nii.gz -epi restap.nii.gz -volreg_base %d -epi_base 10 -deoblique off -overwrite -epi2anat -anat_has_skull no -tshift off -cost nmi -Allineate_opts  "-warp shr"',rep1));
    eval(['!mv restap.nii.gz_al.nii.gz restap_afni_al.nii.gz']);
elseif numofRS == -1  
    rep2 = getRep('restpa_outcount.1D');
    eval(['!/apps/afni_bin_new/linux_openmp_64/3dSkullStrip -input PhaseTwo.nii.gz -overwrite -push_to_edge -init_radius 75 -orig_vol -prefix PhaseTwo_ns.nii.gz']);
    eval(sprintf('!align_epi_anat.py -anat PhaseTwo_ns.nii.gz -epi restpa.nii.gz -volreg_base %d -epi_base 10 -deoblique off -overwrite -epi2anat -anat_has_skull no -tshift off -cost nmi -Allineate_opts "-warp shr"',rep2));
    eval(['!mv restpa.nii.gz_al.nii.gz restpa_afni_al.nii.gz']);
end   

%% Copy default config files to the current dir
eval(['!cp /apps/matlabcode/domems/b02b0.cnf .']);
%add a way to check num of reps
eval(['!cp /apps/matlabcode/domems/acqparams5r.txt .']);

%% GET Coefficents to feed applytopup
% Addtional outputs only avaiable with the hcp version of topup
% topup --imain=BothPhases.nii.gz --datain=acqparams.txt --config=b02b0.cnf --out=Coefficents --iout=Magnitudes --fout=TopupField --dfout=WarpField --rbmout=MotionMartix --jacout=Jacobian -v
eval(['!topup --imain=BothPhases.nii.gz --datain=acqparams5r.txt --config=b02b0.cnf --out=Coefficents --iout=Magnitudes --fout=TopupField -v']);


%% Apply Topup on AFNI aligned data"
jacv = 'jac';
if numofRS == 2
    eval(['!applytopup --imain=restap_afni_al.nii.gz --datain=acqparams5r.txt --inindex=1 --topup=Coefficents --out=myhifiap_afni_al --method=' jacv ' -v']);
    eval(['!applytopup --imain=restpa_afni_al.nii.gz --datain=acqparams5r.txt --inindex=6 --topup=Coefficents --out=myhifipa_afni_al --method=' jacv ' -v']);
  elseif numofRS == 1
        eval(['!applytopup --imain=restap_afni_al.nii.gz --datain=acqparams5r.txt --inindex=1 --topup=Coefficents --out=myhifiap_afni_al --method=' jacv ' -v']);
elseif numofRS == -1    
     eval(['!applytopup --imain=restpa_afni_al.nii.gz --datain=acqparams5r.txt --inindex=6 --topup=Coefficents --out=myhifipa_afni_al --method=' jacv ' -v']);
end 
