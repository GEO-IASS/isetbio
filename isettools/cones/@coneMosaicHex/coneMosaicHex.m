classdef coneMosaicHex < coneMosaic
    %CONEMOSAICHEX Create a hexagonal cone mosaic class
    %
    %   cMosaicHex =  CONEMOSAICHEX(resamplingFactor, varyingDensity, customLambda, varargin);
    %
    % The cone mosaic HEX is a subclass of coneMosaic. It differs because
    % the array of cones is placed on a hexagonal, rather than rectangular,
    % grid. 
    %
    % The hex mosaic is sampled according to the resamplingFactor. The cone
    % density can be spatially-varying if varyingDensity is set to true.
    %
    % The customLambda argument is empty to obtain default performance, but
    % may be set to set the spacing for regularly spaced hexagonal mosaics.
    % The units of customLambda are microns
    %
    % Name-Value parameter pairs used with coneMosaic also can be used with
    % coneMosaicHex 
    %
    % Example:
    %      resamplingFactor = 8;
    %      varyingDensity = false;
    %      customLambda = [];       % If set to empty, @coneMosaiHex chooses
    %                                 the cone spacing based on the eccentricity 
    %                                 of the mosaic as determined by the 
    %                                 coneSize(eccentricityInMeters,ang) function.
    %                                 If set to a value (specified in microns), 
    %                                 cone spacing is set to that value. Note that
    %                                 if the 'varyingDensity' param is  set to true, 
    %                                 the 'customLambda' param is ignored.
    % cMosaicHex = coneMosaicHex(resamplingFactor, varyingDensity, customLambda, ...
    %                          'name', 'the hex mosaic', ...
    %                          'size', [48 32], ...
    %                     'noiseFlag', 0,  ...
    %                'spatialDensity', [0 0.6 0.3 0.1] ...
    %       );
    %   cMosaicHex.window;
    %
    % See also: CONEMOSAIC, t_coneMosaicHex1
    
    % NPC ISETBIO Team, 2016
    
    properties (SetAccess=private)
        lambdaMin                               % min cone separation in the mosaic
        lambdaMid                               % the cone separation at the middle of the mosaic
        customLambda                            % user-supplied lambda (cone spacing) for regularly spaced mosaics (in microns)
        varyingDensity                          % whether to have an eccentricity-based spatially-varying density (boolean)
        resamplingFactor                        % resamplingFactor
        coneLocsHexGrid                         % computed coneLocs (hex grid)
        coneLocsOriginatingRectGrid             % coneLocs of the originating rect grid
        patternOriginatingRectGrid              % cone pattern of the originating rect grid
        patternSampleSizeOriginatingRectGrid    % pattern sample size of the originating rect grid
        fovOriginatingRectGrid                  % FOV of the originating rect grid
        rotationDegs                            % rotation in degrees
    end
    
    % Public methods
    methods
        
        % Constructor
        function obj = coneMosaicHex(upSampleFactor, varyingDensity, customLambda, varargin)
            % Initialize the hex cone mosaic class
            %   cMosaic =  coneMosaicHex(upSampleFactor, varyingDensity, customLambda, ['cone',cone,'os','os]);
            
            % Call the super-class constructor.
            vararginForConeMosaic = {};
            vararginForConeHexMosaic = {};
            for k = 1:2:numel(varargin)
                if (strcmp(varargin{k}, 'rotationDegs'))
                    vararginForConeHexMosaic{numel(vararginForConeHexMosaic)+1} = varargin{k};
                    vararginForConeHexMosaic{numel(vararginForConeHexMosaic)+1} = varargin{k+1};
                else
                    vararginForConeMosaic{numel(vararginForConeMosaic)+1} = varargin{k};
                    vararginForConeMosaic{numel(vararginForConeMosaic)+1} = varargin{k+1};
                end
            end
            obj = obj@coneMosaic(vararginForConeMosaic{:});
            
            % Get a copy of the original coneLocs
            obj.saveOriginalResState();
            
            % parse input
            p = inputParser;
            p.addRequired('resamplingFactor', @isnumeric);
            p.addRequired('varyingDensity', @islogical);
            p.addRequired('customLambda', @isnumeric);
            p.addParameter('rotationDegs', 0, @isnumeric);
            p.parse(upSampleFactor, varyingDensity, customLambda, vararginForConeHexMosaic{:});
            obj.resamplingFactor = p.Results.resamplingFactor;
            obj.varyingDensity = p.Results.varyingDensity;
            obj.customLambda = p.Results.customLambda;
            obj.rotationDegs = p.Results.rotationDegs;
            
            % Generate sampled hex grid
            obj.resampleGrid(obj.resamplingFactor);
        end
        
        % Change the FOV of the mosaic
        setSizeToFOVForHexMosaic(obj,fov);
        
        % Change the cone identities according to arguments passed in varargin
        reassignConeIdentities(obj, varargin)
        
        % Sample the original rectangular mosaic using a hex grid sampled at the passed resamplingFactor
        resampleGrid(obj, resamplingFactor);
        
        % Visualize different aspects of the hex grid
        hFig = visualizeGrid(obj, varargin);
        
        % Method to compute the cone density of @coneMosaicHex
        [densityMap, densityMapSupportX, densityMapSupportY] = computeDensityMap(obj, computeConeDensityMap)
        
        % Reshape a full 3D hex activation map (coneRows x coneCols x time] to a 2D map (non-null cones x time)
        hex2Dmap = reshapeHex3DmapToHex2Dmap(obj, hex3Dmap);
        
        % Reshape a 2D map (non-null cones x time) to the full 3D hex activation map (coneRows x coneCols x time)
        hex3Dmap = reshapeHex2DmapToHex3Dmap(obj, hex2Dmap);
        
        % Compute activation images for the hex mosaic (all cones +  LMS submosaics)
        [activationImage, activationImageLMScone, imageXaxis, imageYaxis] = computeActivationDensityMap(obj, activation);
        
        % Visualize activation maps images for the hex mosaic (all cones +  LMS submosaics)
        hFig = visualizeActivationMaps(obj, activation, varargin);
        
        % Print various infos about the cone mosaic
        displayInfo(obj);
        
    end % Public methods
    
    methods (Access = private)
        % Private methods
        %
        % These are templated here. The actual code is in the
        % @coneMosaicHex directory.
        saveOriginalResState(obj);
        restoreOriginalResState(obj);
    end 
    
end

