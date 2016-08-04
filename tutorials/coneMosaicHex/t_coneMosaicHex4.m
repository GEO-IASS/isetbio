%% t_coneMosaicHex4
%
% Computes hex mosaic isomerization maps for an achromatic Gabor scene and for the Vernier scene
% and illustrates coneMosaicHex's own method for mosaic activation visualization.
%
% NPC, ISETBIO Team, Copyright 2016

%% Initialize
ieInit; clear; close all;

rng('default'); rng(219347);

% Generate a hex mosaic with a medium resamplingFactor
mosaicParams = struct(...
      'resamplingFactor', 8, ...
        'varyingDensity', false, ...              % whether to have an eccentricity based, spatially - varying density
            'centerInMM', [0.5 0.3], ...          % mosaic eccentricity
        'spatialDensity', [0 0.62 0.31 0.07],...
             'noiseFlag', false ...
    );
theHexMosaic = coneMosaicHex(mosaicParams.resamplingFactor, mosaicParams.varyingDensity, ...
                 'center', mosaicParams.centerInMM*1e-3, ...
         'spatialDensity', mosaicParams.spatialDensity, ...
              'noiseFlag', mosaicParams.noiseFlag ...
);

% Set the mosaic's FOV to a wide aspect ratio
theHexMosaic.setSizeToFOVForHexMosaic([0.9 0.6]);
theHexMosaic.displayInfo();


%% Unit test 1: achromatic Gabor scene
[dirName,~] = fileparts(which(mfilename()));
load(fullfile(dirName,'GaborAchromScene.mat'))
gaborScene = sceneSet(gaborScene,'fov', 1.0);

% Compute the optical image
oi = oiCreate;
oi = oiCompute(gaborScene,oi);  

% Compute isomerizations
tic
fprintf('\nComputing isomerizations ...');
isomerizationsGabor = theHexMosaic.compute(oi,'currentFlag',false);
fprintf('Isomerization computation took %2.1f seconds\n', toc);

%% Display isomerizations using coneMosaicHex's own 
%% mosaic activation visualization method
tic
fprintf('\nVisualizing responses ... ');
theHexMosaic.visualizeActivationMaps(...
    isomerizationsGabor, ...                                         % the signal matrix
       'mapType', 'modulated hexagons', ...                          % how to display cones: choose between 'density plot', 'modulated disks' and 'modulated hexagons'
    'signalName', 'isomerizations (R*/cone/integration time)', ...   % colormap title (signal name and units)
      'colorMap', jet(1024), ...                                     % colormap to use for displaying activation level
    'figureSize', [1550 950] ...                                     % figure size in pixels
    );
fprintf('Isomerization visualization took %2.1f seconds\n', toc);


%% Unit test 1: Vernier scene
commandwindow
fprintf('\n<strong>Hit enter to visualize the hex mosaic activation maps for the vernier scene. </strong>');
pause

% Generate the vernier scene
scene = sceneCreate('vernier');
scene.distance = 1;
scene = sceneSet(scene,'fov', 1.0);
vcAddObject(scene); sceneWindow

% Compute the optical image
oi = oiCreate;
oi = oiCompute(scene,oi);  

% Compute isomerizations for both mosaics
isomerizationsVernier = theHexMosaic.compute(oi,'currentFlag',false);

fprintf('\nVisualizing responses ... ');
theHexMosaic.visualizeActivationMaps(...
     isomerizationsVernier, ...                                      % the signal matrix
       'mapType', 'modulated hexagons', ...                          % how to display cones: choose between 'density plot', 'modulated disks' and 'modulated hexagons'
    'signalName', 'isomerizations (R*/cone/integration time)', ...   % colormap title (signal name and units)
      'colorMap', bone(1024), ...                                    % colormap to use for displaying activation level
    'figureSize', [1550 950] ...                                     % figure size in pixels
    );
fprintf('Isomerization visualization took %2.1f seconds\n', toc);
