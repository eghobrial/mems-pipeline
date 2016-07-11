% scrip to run spiralfmap2

% % EDIT: add path to spiralfmap2.m
% addpath('/home/volafsso/cvsrepos/spiralfmap2_clean', '-begin');
% addpath('/home/volafsso/cvsrepos/spiralfmap2_clean/irt/utilities', '-begin');
% EDIT: add path to spiralfmap2.m
addpath('/apps/matlabcode/spiralfmap2', '-begin');
addpath('/apps/matlabcode/spiralfmap2/irt/utilities', '-begin');
addpath('/apps/afni_matlab/matlab', '-begin');

ddir = './';


[dvf, pfname, isdataav,pencode,prefix] = datavalidation_mems();



if pencode == 1
    peprefix = 'fwd';
else
    peprefix = 'rev';
end    



% EDIT: p-file names
% pfname(1) = {'P56320_spep_mems_110510_0903.7'}; % SESS cal
% pfname(2) = {'P56832_spep_mems_110510_0905.7'}; % MESS cal
% pfname(3) = {'P57344_spep_mems_110510_0906.7'}; % MEMS
% pfname(4) = {'P58368_spep_mems_110510_0907.7'}; % topup - fwd
% pfname(5) = {'P58880_spep_mems_110510_0908.7'}; % topup - rev

% switches for recon loop lower
if dvf
if ~exist('dovecs')
    dovecs = [true true true ...
              true true];
end
end


% filenames -- output has to be .mat file (saving a .BRIK takes too long currently)
outputnames(1) = {sprintf('coilmap_%s_%s_sess_fmap',prefix,peprefix)};
outputnames(2) = {sprintf('coilmap_%s_%s_mess_pen1p10',prefix,peprefix)};
outputnames(3) = {sprintf('bcaipi_%_%s_mems_pen1p10_realcmap',prefix,peprefix)};
outputnames(4) = {sprintf('topup_%s_fwd',prefix)};
outputnames(5) = {sprintf('topup_%s_rev',prefix)};



%% field maps
%fmaps(1,:) = {sprintf('%s/e595/s4186',ddir)};
fmaps(1,:) = fmapdir();
fmaps(2,:) = {''};
fmaps(3,:) = {''};
fmaps(4,:) = {''};
fmaps(5,:) = {''};
%keyboard
%% recon command -- some of the swithces are explained in spiralfmap2.m help
%                   {'nsl', 1, ...} switches are for getzwiggle.m so the trajectory is setup correctly
%                                   these should match the CVs to get the correct trajectory
%                   'reps' and 'slices' is to select a subset of the data to recon (default is all reps and slices)
recon(1,:) = {{'epi', 1.05, '', {}, 'reps', '2:end', 'fmap_scale', 1-1/2}};
recon(2,:) = {{'zwiggle', 1, {sprintf('%s.mat', outputnames{1})}, {}, 'reps', '2:end'}};
recon(3,:) = {{'zwiggle', 1, {sprintf('%s.mat', outputnames{1}), sprintf('%s/%s', ddir, pfname{2})}}};
recon(4,:) = {{'zwiggle', 1, {sprintf('%s.mat', outputnames{1})}, {}, 'reps', '2:end'}};
recon(5,:) = {{'zwiggle', 1, {sprintf('%s.mat', outputnames{1})}, {}, 'reps', '2:end'}};

% save complex-valued coil data
docomplex(1) = {false};
docomplex(2) = {false};
docomplex(3) = {false};
docomplex(4) = {false};
docomplex(5) = {false};

% run recon with multiple cores -- recon is parallelized over reps with a parfor loop
doparallel(1) = {5};
doparallel(2) = {5};
doparallel(3) = {10};
doparallel(4) = {5};
doparallel(5) = {5};

% if false save .mat files (.BRIK is slow, especially for blippedCAIPI images)
dowriteBRIK(1) = {true};
dowriteBRIK(2) = {true};
dowriteBRIK(3) = {true};
dowriteBRIK(4) = {true};
dowriteBRIK(5) = {true};

% if true, correct for B0drift by using the center most kspace coordinite
doB0cor(1) = {false};
doB0cor(2) = {false};
doB0cor(3) = {false};
doB0cor(4) = {false};
doB0cor(5) = {false};

% size of reps chunks that the data will be split into
repchunk(1) = {1};
repchunk(2) = {1};
repchunk(3) = {1};
repchunk(4) = {1};
repchunk(5) = {1};

%% recon loop
for kk = 1:length(dovecs);
    if dovecs(kk)
        data = sprintf('%s/%s', ddir, pfname{kk})

        % set field map
        if isempty(fmaps{kk})
            fmap1   = '';
            fmap2   = '';
        else
            fmap1   = fmaps{kk};
            fmap2   = fmaps{kk};
        end

        doreg = false;
        skip_slice = 0;
        ASL = false;
        parallel = doparallel{kk};
        doComplex = docomplex{kk};
        writeBRIK = dowriteBRIK{kk};
        B0cor = doB0cor{kk};

        h = getpheader(data);
        nrepschunk = floor(h.reps ./ repchunk{kk});
        for ii = 1:repchunk{kk}
            if repchunk{kk} > 1
                outputname = sprintf('%s_part%i', outputnames{kk}, ii);
                reconii = recon{kk};
                if length(reconii) == 3
                    reconii{4} = {};
                end
                if ii == repchunk{kk}
                    reconii(end+1:end+2) = {'reps', 1+(ii-1)*nrepschunk:h.reps};
                else
                    reconii(end+1:end+2) = {'reps', 1+(ii-1)*nrepschunk:ii*nrepschunk};
                end
            else
                outputname = outputnames{kk};
                reconii = recon{kk};
            end

            [~, td{kk}, chan_image] = spiralfmap2(data, fmap1, fmap2, ...
              outputname, doreg, skip_slice, ASL, reconii, parallel, ...
              doComplex, writeBRIK, B0cor);
        end

        % concatenate and readd notes and history
        if repchunk{kk} > 1
            % concatenate all BRIKs
            disp('Concatenating all runs into a single BRIK...')
            prefixbrik = sprintf('%sbrik', outputnames{kk});
            partbriks = sprintf([outputnames{kk} '_part%ibrik+orig '], [1:repchunk{kk}]);
            if exist([prefixbrik '+orig.BRIK'], 'file')
                warning('BRIK already exists...backing up old BRIK');
                system(['mv ' prefixbrik '+orig.BRIK ' prefixbrik '_old+orig.BRIK']);
                system(['mv ' prefixbrik '+orig.HEAD ' prefixbrik '_old+orig.HEAD']);
            end
            system(['3dTcat -verb -prefix ' prefixbrik ' ' partbriks]);

            % add notes and history
            part1brik = sprintf('%s_part1brik+orig', outputnames{kk});
            [~, part1brikInfo] = BrikInfo(part1brik);
            for ii = 1:part1brikInfo.NOTES_COUNT
                system(sprintf('3drefit -atrcopy %s NOTE_NUMBER_%03i %s+orig', part1brik, ii, prefixbrik));
                system(sprintf('3drefit -atrcopy %s NOTE_DATE_%03i %s+orig', part1brik, ii, prefixbrik));
            end
            system(sprintf('3drefit -atrcopy %s NOTES_COUNT %s+orig', part1brik, prefixbrik));
            system(sprintf('3drefit -atrcopy %s HISTORY_NOTE %s+orig', part1brik, prefixbrik));

            if exist([prefixbrik '+orig.BRIK'], 'file')
                system(['rm ' sprintf([outputnames{kk} '_part%ibrik+orig.BRIK '], [1:repchunk{kk}])]);
                system(['rm ' sprintf([outputnames{kk} '_part%ibrik+orig.HEAD '], [1:repchunk{kk}])]);
            else
                warning 'Not able to save BRIK with concatenated BRIKs';
                keyboard;
            end
        end

        if any(kk == [1 6 11])
            % save coil sensitivity map
            coilmap = mean(chan_image, 5);
            save(sprintf('%s.mat', outputnames{kk}), 'coilmap');
            clear coilmap;
        end
        clear chan_image;
    end
    %close all;
end
