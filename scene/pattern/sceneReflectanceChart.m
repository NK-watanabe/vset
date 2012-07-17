function [scene, sSamples, reflectance] = sceneReflectanceChart(sFiles,sSamples,pSize,wave,grayFlag,sampling)
% Create a reflectance chart for testing
%
%   [scene, sampleList, reflectances] = ...
%      sceneReflectanceChart(sFiles,sSamples,pSize,[wave],[grayFlag=1],[sampling])
%
% Inputs
%  The surfaces are drawn from the cell array of sFiles{}.  
%  sFiles:   Cell array of file names with reflectance spectra
%  sSamples: This can either be
%      - Vector indicating how many surfaces to sample from each file
%      - A cell array of specifying the list of samples from each file 
%  pSize:    The number of pixels on the side of each square patch
%  wave:     Wavelength Samples
%  grayFlag: Fill the last part of the chart with gray surfaces (20% reflectance)
%
% Returns
%   scene:         Reflectance chart as a scene
%   sSamples:      A cell array of the surfaces from each file, as above
%   reflectances:  The actual reflectances
%  
%Example:
%  sFiles = cell(1,4);
%  sFiles{1} = fullfile(isetRootPath,'data','surfaces','reflectances','MunsellSamples_Vhrel.mat');
%  sFiles{2} = fullfile(isetRootPath,'data','surfaces','reflectances','Food_Vhrel.mat');
%  sFiles{3} = fullfile(isetRootPath,'data','surfaces','reflectances','DupontPaintChip_Vhrel.mat');
%  sFiles{4} = fullfile(isetRootPath,'data','surfaces','reflectances','Skin_Vhrel.mat');
%  sSamples = [12,12,25,25]*5; nSamples = sum(sSamples);
%  pSize = 24; 
%
%  [scene, samples] = sceneReflectanceChart(sFiles,sSamples,pSize);
%  scene = sceneAdjustLuminance(scene,100);
%  vcAddAndSelectObject(scene); sceneWindow;
%
% See also: macbethChartCreate
%
% Copyright ImagEval Consultants, LLC, 2010.

if ieNotDefined('sFiles'), error('Surface files required'); 
else                       nFiles = length(sFiles);
end

if ieNotDefined('sSamples'), error('Surface samples required'); end
if ieNotDefined('pSize'),    pSize = 32; end
if ieNotDefined('grayFlag'), grayFlag = 1; end
if ieNotDefined('sampling'), sampling = 'r'; end %With replacement by default

% Default scene
scene = sceneCreate;
if ieNotDefined('wave'), wave = sceneGet(scene,'wave');
else                     scene = sceneSet(scene,'wave',wave);
end
nWave = length(wave);

if length(sSamples) ~= nFiles
    error('Mis-match between number of files and sample numbers');
end
defaultLuminance = 100;  % cd/m2

% Get the reflectance samples
[reflectance, sSamples] = ieReflectanceSamples(sFiles,sSamples,wave,sampling);

% sSamples might be a vector, indicating the number of samples, or a cell
% array specifying which samples.
if iscell(sSamples)
    nSamples = 0;
    for ii=1:nFiles, nSamples = length(sSamples{ii}) + nSamples; end
else nSamples = sum(sSamples);  
end

% Spatial arrangement
r = ceil(sqrt(nSamples)); c = ceil(nSamples/r);

% reflectance is in wave x surface format.  We fill up the end of the matrix with
% gray surface reflectances.
if grayFlag
    % Create a column of gray surfaces, 20 percent reflectance
    g = 0.2*ones(nWave,r);
    reflectance = [reflectance, g];
    c = c + 1;
end
rcSize = [r,c];

% Convert the scene reflectances into photons assuming an equal energy
% illuminant.
ee         = ones(nWave,1);           % Equal energy vector
e2pFactors = Energy2Quanta(wave,ee);  % Energy to photon factor

% Illuminant
illuminantPhotons = diag(e2pFactors)*ones(nWave,1);

% Convert the reflectances into photons
% Data from first file are in the left columns, second file next set of
% cols, and so forth. There may be a gray strip at the end.
% Scale reflectances by incorporating energy to photon scale factr
radiance = diag(e2pFactors)*reflectance;    

% Put these into the scene data structure.  These are in photon units, but
% they are not scaled to reasonable photon values.
sData = zeros(rcSize(1),rcSize(2),nWave);
for rr=1:rcSize(1)
    for cc=1:rcSize(2)
        idx = sub2ind(rcSize,rr,cc);
        if idx <= size(radiance,2)
            sData(rr,cc,:) = radiance(:,idx);
        else
            sData(rr,cc,:) = 0.2*illuminantPhotons;
        end
    end
end

% Build up the size of the image regions - still reflectances
sData = imageIncreaseImageRGBSize(sData,pSize);

% Add data to scene, using equal energy illuminant
scene = sceneSet(scene,'cphotons',sData);
scene = sceneSet(scene,'illuminantPhotons',illuminantPhotons);
scene = sceneSet(scene,'illuminantComment','Equal energy');
scene = sceneSet(scene,'name','Reflectance Chart (EE)');
% vcAddAndSelectObject(scene); sceneWindow;

% Adjust the illuminance to a default level in cd/m2
scene = sceneAdjustLuminance(scene,defaultLuminance);
% vcAddAndSelectObject(scene); sceneWindow;

return


