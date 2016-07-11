% simple processing script for
% correlation analysis on single echo BOLD data
% here is the pipeline:
% caution: use AFNI to make sure anatomical data is well aligned with the
% functional data. If not, use align_epi_anat.py!!!
% assume motion parameters are available, otherwise use 3dvolreg before
% running this script
% needs fsl 5.0
% 1. load anatomical, partial volume maps and resample them in functional space
% 2. create brain mask
% 3. generate nuisance regressors e.g. legendre, motion, WMcsf
% 4. identify ROI and obtain average BOLD signal
% 5. perform correlation analysis
% 6. same the correlation file and roi mask in AFNI BRIK format
%
% Author: Chi Wah (Alec) Wong May 22 2012
% $Id: example_corr_analysis_1echo.m,v 1.1 2012/05/24 21:26:00 awong Exp $

clear all; close all;
% specify file locations
fmri.dir.anat='./';
fmri.dir.func='./';
fmri.study.name='';
fmri.study.visitID={''};
fmri.anat.name='anat_obl+orig';
fmri.func.name={'myhifiap_afni_al+orig'};
fmri.func.motionFile={'restap.nii.gz_vr_motion.1D'};
fmri.func.atlas_template='/home/awong/templates/Talairach/TT_avg152T1+tlrc';

% specify processing parameters
fmri.flags.WMcsf=1;
fmri.flags.lp=0.08; %set to zero if no low pass filter, or the stopband if do low pass filtering
fmri.flags.legorder=2;
fmri.flags.im1=6;

% number of subjects
nsub=length(fmri.study.visitID);
seed_coord=[0 51 26 1]; %PCC

for subjCnt=1:nsub

    fullPath_anat=[fmri.dir.anat,fmri.study.name,'/',fmri.study.visitID{subjCnt},'/',fmri.anat.name]
    
    % do 3dskull strip
    [fullPath_anatSS]=afni_3dSkullStrip(fullPath_anat);
    
    
    for runCnt=1:size(fmri.func.name,2)
        
        funcName=fmri.func.name{runCnt};
        % define path to functionals and anatomicals
        fullPath_func=[fmri.dir.func,fmri.study.name,'/',fmri.study.visitID{subjCnt},'/',fmri.func.name{runCnt}];
        %fullPath_func = fmri.func.name;
        % make sure the dataset are in RAI orientation (for easy
        % visualization)
        [fullPath_funcOR]=afni_reorient(fullPath_func);

        % load functional data
        [fmri.func.headinfo,funcData,funcROI]=loadFunc(fullPath_funcOR);
        
        % extract some useful variables on functional data dimensions
        xdim=fmri.func.headinfo.xdim; % number of voxels
        ydim=fmri.func.headinfo.ydim; % number of voxels
        zdim=fmri.func.headinfo.zdim; % number of voxels
        xvox=fmri.func.headinfo.xvox; % voxel size
        yvox=fmri.func.headinfo.yvox; % voxel size
        zvox=fmri.func.headinfo.zvox; % voxel size
        im1=fmri.flags.im1;  % the first time point
        nvols=fmri.func.headinfo.nvols; % num of time points
        
        % load anatomical data
        [anatData]=loadAnat(fullPath_anatSS,fullPath_funcOR);
        
        % load partial-volume map, do fast segmentation if needed
        [pv_mask]=fsl_loadpv(fullPath_anatSS,fullPath_funcOR);
        
        % convert seed voxels in talairach space to subject space
        voxel_coord=tlrc2orig(fullPath_anatSS,fullPath_funcOR,...
            fmri.func.atlas_template,seed_coord'); %% avg152T1 or icbm452
        
        % define roi for processing
        roi_global = smoothmask(funcROI>0);
        
        for ii=1:size(roi_global,3)
            roi_global(:,:,ii)=bwmorph(roi_global(:,:,ii),'close',Inf);
            roi_global(:,:,ii)=bwmorph(roi_global(:,:,ii),'erode',2);
        end;
        
        % REGRESSOR: Legendre polynomial
        if fmri.flags.legorder>0
            regressor=legendremat(fmri.flags.legorder,nvols);
            regressor=regressor((im1+1):end,:);
        else regressor=[];
        end;
        
        % REGRESSOR: motion
        reg_motion=genPreg_motion(fullPath_funcOR,[],[fmri.dir.func,fmri.study.name,'/',fmri.study.visitID{subjCnt},'/',fmri.func.motionFile{runCnt}]);
        reg_motion=reg_motion(im1:end,:); %im1 is ok since the difference effect has already taken care of
 
        % REGRESSOR: data-drive WM/CSF physiological regressor
        wm_slice=int8([voxel_coord(3,1)-15/zvox voxel_coord(3,1)+15/zvox]);
        csf_slice=int8([voxel_coord(3,1)-30/zvox voxel_coord(3,1)]);
        pv_mask.white(:,:,[1:wm_slice(1) wm_slice(2):end])=0;
        pv_mask.csf(:,:,[1:csf_slice(1) csf_slice(2):end])=0;
        if (fmri.flags.WMcsf==1)
            reg_WMcsf=genPreg_WMcsf(funcData,pv_mask,roi_global);
            reg_WMcsf=reg_WMcsf(im1:end,:);
        else
            reg_WMcsf=[];
        end;
        
        % concatenate all regressors
        regressor=[regressor reg_motion reg_WMcsf];
        
        % remove reps in the front
        %regressor=regressor(im1:end,:);
        funcData=funcData(:,:,:,(im1+1):end); % im+1 to reflect the difference effect
        
        % regress out nuisance terms
        [funcDataCorr,doff]=processPreg_RS(funcData,regressor,roi_global,fmri.flags.lp,fmri.func.headinfo.TR);
        
        funcData2DCorr=reshape(funcDataCorr,xdim*ydim*zdim,nvols-im1);
        funcData2DCorr=funcData2DCorr./repmat(mean(funcData2DCorr,2),1,size(funcData2DCorr,2));
        funcDataCorr = reshape(funcData2DCorr,xdim,ydim,zdim,nvols-im1);
         
        % calculate mean BOLD signal using the PCC seed (12mm diameter
        % sphere)
        [roi_avg2,roi_plot,error_flag]=calcROIseed(funcData2DCorr,voxel_coord,(roi_global>0),6./[xvox yvox zvox],1);

        % display ROI mask on anatomical
        delete('./roi_plot+orig*');
        Mat2AFNI(double(roi_plot{1}),'./roi_plot',fullPath_funcOR,3);
        ShowActivity(fullPath_anat,'./roi_plot+orig',[1 1 4],0.6,1);
        print('-dtiff',[fmri.func.name{runCnt},'_PCCseed.tif'],'-r300');
        delete('./roi_plot+orig*');

        funcData2DCorr_roi=funcData2DCorr(roi_global>0,:);
        z_map=zeros(size(roi_global));
        
        % voxel wise correlation
        [~,~,z_map2]=mcorr(roi_avg2(1,:)',funcData2DCorr_roi',doff);
        z_map(roi_global>0)=z_map2;

        % print out the correlation map
        delete('./corr+orig*');
        Mat2AFNI(double(z_map),'./corr',fullPath_funcOR,3);
        ShowActivity(fullPath_anat,'./corr+orig',[1 1 5],0,7);
        print('-dtiff',[fmri.func.name{runCnt},'_PCCcorr_lp',num2str(fmri.flags.lp*100),'.tif'],'-r300');
        delete('./corr+orig*');
        close all;
        
    end;
end;
