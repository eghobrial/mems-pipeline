function run_recon (pfn1,pfn2)
%% Add path to spiralfmap2.m
addpath('/apps/afni_matlab/matlab', '-begin');
addpath('/apps/matlabcode/spiralfmap2/irt/utilities', '-begin');
addpath('/apps/matlabcode/spiralfmap2', '-begin');


% filenames -- output has to be .mat file (saving a .BRIK takes too long currently)
% coil sensitivity
outputnames(1) = {sprintf('%s_coilmap', pfn1(1:end-2))};
% blipped CAIPI
outputnames(2) = {sprintf('%s_bcaipi', pfn2(1:end-2))};

% switch to choose between SENSE recon and slGRAPPA
dosense = false;

%% recon command -- some of the swithces are explained in spiralfmap2.m help
%                   {'nsl', 1, ...} switches are for getzwiggle.m so the trajectory is setup correctly
%                                   these should match the CVs to get the correct trajectory
%                   'reps' and 'slices' is to select a subset of the data to recon (default is all reps and slices)
% coil sensitivity
%recon(1,:) = {{'epi', 1.2, '', {'nsl', 1, 'zmod', 0}, 'reps', 'end-1:end'}};
%recon(2,:) = {{'zwiggle', 1.2, sprintf('%s.mat',outputnames{1}), {'nsl', 3, 'seprat', 16, 'zmod', 2, 'ncaipi', 2}}};
if dosense
      % coil sensitivity
    recon(1,:) = {{'epi', 1.2, '', {'nsl', 1, 'seprat', 9, 'zmod', 2, 'ncaipi', 3, 'yfov', 18, 'inplsense', 0}, 'reps', 1}};
    recon(2,:) = {{'zwiggle', 1.2, sprintf('%s.mat',outputnames{1}), {'zmod', 2, 'seprat', 9, 'nsl', 8, 'ncaipi', 3, 'yfov', 18, 'inplsense', 0}}};
else
    recon(1,:) = {{'epi', 1, '', {}, 'reps', 'end'}};
 %   recon(2,:) = {{'slgrappa', 1, {pfn1}, {}, 'slices', 1, 'reps', 10}};
   recon(2,:) = {{'slgrappa', 1, {pfn1}}};
end


%% calling spiralfmap2 twice, 
%coil sensitivity
data = pfn1;
fmap1 = '';
fmap2 = '';
outputname = outputnames{1};
doreg = false;
skip_slice = 0;
ASL = false;

% save complex-valued coil data
docomplex(1) = {false};
docomplex(2) = {false};

% run recon with multiple cores -- recon is parallelized over reps with a parfor loop
doparallel(1) = {false};  % set to true to use all cores or number to use subset ({2} uses 2 cores)
doparallel(2) = {10};

% if false save .mat files (.BRIK is slow, especially for blippedCAIPI images)
dowriteBRIK(1) = {false};
dowriteBRIK(2) = {true};

if dosense && ~exist(sprintf('%s.mat', outputname), 'file')
%     [~, ~, chan_image] = spiralfmap2(data, fmap1, fmap2, ...
%                       outputname, doreg, skip_slice, ASL, recon{1}, doparallel{1}, ...
%                       docomplex{1}, dowriteBRIK{1});
% 
%     % save coil sensitivity map
%     coilmap = mean(chan_image, 5);
%     save(sprintf('%s.mat', outputnames{1}), 'coilmap');
%     clear coilmap;  
%     clear chan_image;
    coilmap = randn(10);
    save(sprintf('%s.mat', outputnames{1}), 'coilmap');
end

              
%% blipped-CAIPI recon
% recon parameters
data = pfn2;
fmap1 = '';
fmap2 = '';
doreg = false;
skip_slice = 0;
ASL = false;
repchunk = 6;   % split recon into 6 parts -- needed due to excessive memory usage

% reconstruct each chunk of data
h = getpheader(data);
nrepschunk = floor(h.reps ./ repchunk);
for ii = 1:repchunk
    outputname = sprintf('%s_part%i', outputnames{2}, ii);
    reconii = recon{2};
    if length(reconii) == 3
        reconii{4} = {};
    end
    if ii == repchunk
        reconii(end+1:end+2) = {'reps', 1+(ii-1)*nrepschunk:h.reps};
    else
        reconii(end+1:end+2) = {'reps', 1+(ii-1)*nrepschunk:ii*nrepschunk};
    end

    %takes less time only recon one point
%     spiralfmap2(data, fmap1, fmap2, ...
%       outputname, doreg, skip_slice, ASL, recon{2}, doparallel{2}, ...
%       docomplex{2}, dowriteBRIK{2});
  
  %takes longer recon all
  spiralfmap2(data, fmap1, fmap2, ...
      outputname, doreg, skip_slice, ASL, reconii, doparallel{2}, ...
      docomplex{2}, dowriteBRIK{2});
end

% concatenate subpart BRIKs
disp('Concatenating all subparts into a single BRIK...')
prefixbrik = sprintf('%sbrik', outputnames{2});
partbriks = sprintf([outputnames{2} '_part%ibrik+orig '], [1:repchunk]);
if exist([prefixbrik '+orig.BRIK'], 'file')
    warning('BRIK already exists...backing up old BRIK');
    system(['mv ' prefixbrik '+orig.BRIK ' prefixbrik '_old+orig.BRIK']);
    system(['mv ' prefixbrik '+orig.HEAD ' prefixbrik '_old+orig.HEAD']);
end
system(['3dTcat -verb -prefix ' prefixbrik ' ' partbriks]);

% re-add notes and history
part1brik = sprintf('%s_part1brik+orig', outputnames{2});
[~, part1brikInfo] = BrikInfo(part1brik);
for ii = 1:part1brikInfo.NOTES_COUNT
    system(sprintf('3drefit -atrcopy %s NOTE_NUMBER_%03i %s+orig', part1brik, ii, prefixbrik));
    system(sprintf('3drefit -atrcopy %s NOTE_DATE_%03i %s+orig', part1brik, ii, prefixbrik));
end
system(sprintf('3drefit -atrcopy %s NOTES_COUNT %s+orig', part1brik, prefixbrik));
system(sprintf('3drefit -atrcopy %s HISTORY_NOTE %s+orig', part1brik, prefixbrik));

if exist([prefixbrik '+orig.BRIK'], 'file')
    system(['rm ' sprintf([outputnames{2} '_part%ibrik+orig.BRIK '], [1:repchunk])]);
    system(['rm ' sprintf([outputnames{2} '_part%ibrik+orig.HEAD '], [1:repchunk])]);
else
    error('Not able to save BRIK with concatenated BRIKs');
end
