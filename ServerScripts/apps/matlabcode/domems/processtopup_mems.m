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
%        June 2013
%
%==================================================================================================


%% Call Data Validation to get the flags
[dvf,pfname,isdataav,pencode,prefix] = datavalidation_mems()

 if pencode == 1
    peprefix = 'fwd';
 else
    peprefix = 'rev';
 end    

%% Make dir for processed data and Move BRIKs to
mkdir processed;
eval(['!cp *.BRIK processed']);
eval(['!cp *.HEAD processed']);
eval(['!cp *.gz processed']);
eval(['!cp *.mat processed']);
eval(['!cp *.tif processed']);
eval(['!cp *.csv processed']);
eval(['!cp *.jpg processed']);

cd processed;

%% Create a script with command line calls
fdatestamp = getfiledatestamp();
scriptfilename = sprintf('script_%s.sh',deblank(fdatestamp))
sfile_id = fopen(scriptfilename,'w');

%% Converting BRIKs to NIFTI
eval (sprintf('!3dAFNItoNIFTI -prefix PhaseOne.nii.gz topup_%s_fwdbrik+orig',prefix));
eval (sprintf('!3dAFNItoNIFTI -prefix PhaseTwo.nii.gz topup_%s_revbrik+orig',prefix));

eval (sprintf('!3dAFNItoNIFTI -prefix mems_e01.nii.gz bcaipi_brik_e01+orig')); 
eval (sprintf('!3dAFNItoNIFTI -prefix mems_e02.nii.gz bcaipi_brik_e02+orig')); 
eval (sprintf('!3dAFNItoNIFTI -prefix mems_e03.nii.gz bcaipi_brik_e03+orig')); 

%eval(['!fslroi PhaseOne.nii.gz PhaseOne0.nii.gz 0 1']);
%eval(['!fslroi PhaseTwo.nii.gz PhaseTwo0.nii.gz 0 1']);
eval(['!fslmerge -t BothPhases PhaseOne PhaseTwo']);

%eval(['!3dinfo bcaipi_spep_hcp_rest_revbrik+orig > restpainfo.txt']);
 eval(['!3dToutcount -autoclip -range mems_e02.nii.gz > restpa_outcount.1D']);
% Write the commands to the script file 
fprintf(sfile_id,'#**Converting BRIKs to NIFTI and prep for topup**\n');
fprintf(sfile_id,(sprintf('!3dAFNItoNIFTI -prefix PhaseOne.nii.gz topup_%s_fwdbrik+orig\n',prefix)));
fprintf(sfile_id,(sprintf('!3dAFNItoNIFTI -prefix PhaseTwo.nii.gz topup_%s_revbrik+orig\n',prefix)));

%% Motion Correction - Using align_epi_anat

    rep2 = getRep('restpa_outcount.1D');
   %rep2 = 5;
    eval(['!/apps/afni_bin_new/linux_openmp_64/3dSkullStrip -input PhaseTwo.nii.gz -overwrite -push_to_edge -init_radius 75 -orig_vol -prefix PhaseTwo_ns.nii.gz']);
    eval(sprintf('!align_epi_anat.py -anat PhaseTwo_ns.nii.gz -epi mems_e02.nii.gz -volreg_base %d -epi_base 5 -deoblique off -overwrite -epi2anat -anat_has_skull no -tshift off -cost nmi -Allineate_opts "-warp shr"',rep2));
    eval(['!mv mems_e02.nii.gz_al.nii.gz mems_e02_afni_al.nii.gz']);

    eval(['!3dvolreg -float -Fourier -prefix mems_e01_vr.nii.gz -dfile mems_e01_motion.1D -base 5 mems_e01.nii.gz']);
    eval(['!3dAllineate -source mems_e01_vr.nii.gz -prefix mems_e01_afni_al.nii.gz -1Dmatrix_apply mems_e02.nii.gz_al_mat.aff12.1D']);
    eval(['!3dvolreg -float -Fourier -prefix mems_e03_vr.nii.gz -dfile mems_e03_motion.1D -base 5 mems_e03.nii.gz']);
    eval(['!3dAllineate -source mems_e03_vr.nii.gz -prefix mems_e03_afni_al.nii.gz -1Dmatrix_apply mems_e02.nii.gz_al_mat.aff12.1D']);
    eval(['!mv mems_e01.nii.gz_al.nii.gz mems_e01_afni_al.nii.gz']);
    eval(['!mv mems_e03.nii.gz_al.nii.gz mems_e03_afni_al.nii.gz']);

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
eval(['!applytopup --imain=mems_e01_afni_al.nii.gz --datain=acqparams5r.txt --inindex=6 --topup=Coefficents --out=myhifipa_e01_afni_al --method=' jacv ' -v']);
eval(['!applytopup --imain=mems_e02_afni_al.nii.gz --datain=acqparams5r.txt --inindex=6 --topup=Coefficents --out=myhifipa_e02_afni_al --method=' jacv ' -v']);
eval(['!applytopup --imain=mems_e03_afni_al.nii.gz --datain=acqparams5r.txt --inindex=6 --topup=Coefficents --out=myhifipa_e03_afni_al --method=' jacv ' -v']);

