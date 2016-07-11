#!/bin/bash 
set -e
echo -e "\n START: Converting BRIKs to NIFTI"

3dAFNItoNIFTI -prefix PhaseOne.nii.gz topup_epyneg0brik+orig
3dAFNItoNIFTI -prefix PhaseTwo.nii.gz topup_epyneg1brik+orig
fslmerge -t BothPhases PhaseOne PhaseTwo

3dAFNItoNIFTI -prefix restap.nii.gz bcaipi_spep_hcp_rest_fwdbrik+orig
3dAFNItoNIFTI -prefix restpa.nii.gz bcaipi_spep_hcp_rest_revbrik+orig
echo -e "\n END: Converting BRIKs to NIFTI"

echo -e "\n START: Motion Correction - Using align_epi_anat"
3dSkullStrip -input PhaseOne.nii.gz -overwrite -push_to_edge -init_radius 75 -orig_vol -prefix PhaseOne_ns.nii.gz
align_epi_anat.py -anat PhaseOne_ns.nii.gz -epi restap.nii.gz -epi_base 0 -overwrite -epi2anat -anat_has_skull no -tshift off -cost nmi -Allineate_opts  "-warp shr"
mv restap.nii.gz_al.nii.gz restap_afni_al.nii.gz
echo -e "\n END 1: Motion Correction - Using align_epi_anat"
3dSkullStrip -input PhaseTwo.nii.gz -overwrite -push_to_edge -init_radius 75 -orig_vol -prefix PhaseTwo_ns.nii.gz
align_epi_anat.py -anat PhaseTwo_ns.nii.gz -epi restpa.nii.gz -epi_base 0 -overwrite -epi2anat -anat_has_skull no -tshift off -cost nmi -Allineate_opts "-warp shr"
mv restpa.nii.gz_al.nii.gz restpa_afni_al.nii.gz


echo -e "\n START: Topup - GET Coefficents to feed applytopup"
#Addtional outputs only avaiable with 
#topup --imain=BothPhases.nii.gz --datain=acqparams.txt --config=b02b0.cnf --out=Coefficents --iout=Magnitudes --fout=TopupField --dfout=WarpField --rbmout=MotionMartix --jacout=Jacobian -v
topup --imain=BothPhases.nii.gz --datain=acqparams.txt --config=b02b0.cnf --out=Coefficents --iout=Magnitudes --fout=TopupField --dfout=WarpField --rbmout=MotionMartix --jacout=Jacobian -v
echo -e "\n END: Topup - GET Coefficents to feed applytopup"

echo -e "\n START: Topup - Using APPLYTOPUP No aligment"
applytopup --imain=restap.nii.gz --datain=acqparams.txt --inindex=1 --topup=Coefficents --out=myhifiap --method='jac' -v
applytopup --imain=restpa.nii.gz --datain=acqparams.txt --inindex=2 --topup=Coefficents --out=myhifipa --method='jac' -v
echo -e "\n END: Topup - Using APPLYTOPUP"

echo -e "\n START: Apply Topup on AFNI aligned data"
applytopup --imain=restap_afni_al.nii.gz --datain=acqparams.txt --inindex=1 --topup=Coefficents --out=myhifiap_afni_al --method='jac' -v
applytopup --imain=restpa_afni_al.nii.gz --datain=acqparams.txt --inindex=2 --topup=Coefficents --out=myhifipa_afni_al --method='jac' -v
echo -e "\n END: Apply Topup on AFNI aligned data"

echo -e "\n START: Motion Correction - Using FSL Tools"
bet PhaseOne.nii.gz PhaseOne_bet 
bet restap.nii.gz restap_bet 
flirt -cost normmi -dof 6 -in restap_bet.nii.gz -ref PhaseOne_bet.nii.gz -out restap2PhaseOne -omat restap2PhaseOne.mat 
applywarp -i restap.nii.gz -o restap_fsl_al -r PhaseOne_bet.nii.gz --premat=restap2PhaseOne.mat --interp=trilinear 
bet PhaseTwo.nii.gz PhaseTwo_bet 
bet restpa.nii.gz restpa_bet 
flirt -cost normmi -dof 6 -in restpa_bet.nii.gz -ref PhaseTwo_bet.nii.gz -out restpa2PhaseTwo -omat restpa2PhaseTwo.mat 
applywarp -i restpa.nii.gz -o restpa_fsl_al -r PhaseTwo_bet.nii.gz --premat=restpa2PhaseTwo.mat --interp=trilinear 
echo -e "\n END: Motion Correction - Using FSL Tools"

echo -e "\n START: Apply Topup on FSL aligned data"
applytopup --imain=restap_fsl_al.nii.gz --datain=acqparams.txt --inindex=1 --topup=Coefficents --out=myhifiap_fsl_al --method='jac' -v
applytopup --imain=restpa_fsl_al.nii.gz --datain=acqparams.txt --inindex=2 --topup=Coefficents --out=myhifipa_fsl_al --method='jac' -v
echo -e "\n END: Apply Topup on FSL aligned data"


