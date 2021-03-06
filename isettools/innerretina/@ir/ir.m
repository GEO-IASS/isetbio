classdef ir < handle
    %IR - Create an innerRetina object
    % The inner retina class stores general properties of the retinal patch 
    % and stores the rgcMosaic objects in its mosaic property field.
    %
    %   obj = ir(inputObj, params);    [usually called internally from irCreate]
    %
    % An ir object takes as input a bipolar object or an outerSegment object.
    % The ir (inner retina) object stores basic properties about the inner
    % retina such as the position of the simulated retinal patch.
    %
    % See Pillow, Jonathan W., et al. "Spatio-temporal correlations and visual
    % signalling in a complete neuronal population." Nature 454.7207 (2008)
    % and Chichilnisky, E. J., and Rachel S. Kalmar. "Functional asymmetries
    % in ON and OFF ganglion cells of primate retina." The Journal of
    % Neuroscience 22.7 (2002).
    %
    % Properties:
    %
    %  Established by constructor parameters
    %     name:      animal, ir; example: 'macaque ir'
    %     eyeSide:   Left or right eye
    %     eyeRadius: Position of patch in radius
    %     eyeAngle:  Angle (degrees)
    %     temporalEquivEcc: calculated from retinal position, see
    %           retinalLocationToTEE 
    %     numberTrials: number of trials for spike generation
    %
    %   Inherited from bipolar input
    %     row:       N Stimulus row samples
    %     col:       N Stimulus col samples
    %     size:   Stimulus input spacing (m)
    %     timing:    Stimulus input time step (sec)
    %
    %  Established by the mosaicCreate method
    %     mosaic: cell array of rgc mosaics 
    %
    % Methods: 
    %   set, get, compute, plot
    %
    % Examples:
    %   bp = bipolar(coneMosaic);
    %   innerRetina1 = irCreate(bp,'name','myRGC');
    %
    %   params.name = 'Macaque inner retina 1';
    %   params.eyeSide = 'left'; params.eyeRadius = 2;
    %   innerRetina2 = ir(bp, params);
    %
    %  ISETBIO wiki: <a href="matlab:
    %  web('https://github.com/isetbio/isetbio/wiki/Retinal-ganglion-cells','-browser')">RGCS</a>.
    %
    % (c) isetbio team
    %
    % 9/2015 JRG
    % 7/2016 JRG updated
    
    %%
    % Public read/write properties
    properties
    end
    
    % Public, read-only properties.
    properties (SetAccess = public, GetAccess = public)
        %NUMBERTRIALS Number of trials when computing
        numberTrials;  
        
        %MOSAIC Cell array containing ganglion cell mosaics
        mosaic;        % The spatial sampling differs for each mosaic
                       
    end
    
    % Protected properties; Methods of the parent class and all of its
    % subclasses can set these.
    properties (SetAccess = protected)
        %NAME Name of this innerRetina
        name;       % Note: The computation is specified by the ir subclass
                    % Is the spatial sampling is determined by the bipolar
                    % input?
                    
        %ROW N Stimulus row samples (from bipolar)
        row;        
        
        %COL N Stimulus col samples (from bipolar)
        col;         
        
        %SIZE Patch size (m) measured at the cone mosaic
        size;        
        
        %TIMESTEP Stimulus temporal sampling (sec) from bipolar
        timeStep;   % This is the same for all mosaics
        
        %EYESIDE Left or right eye
        eyeSide;           
        
        %EYERADIUS Position of patch in radius
        eyeRadius;         
        
        %EYEANGLE and angle (degrees)
        eyeAngle;         
        
        %TEMPORALEQUIVECC Temporal equivalent eccentricity (mm)
        temporalEquivEcc; 
        
    end
    
    % Private properties. Only methods of the parent class can set these
    properties(Access = private)
    end
    
    % Public methods
    methods
        function obj = ir(bp, varargin)
            % Constructor
            %
            % We require an inner retina to receive its inputs from a
            % bipolar object.  To skip the bipolar model use a bpIdentity
            % object.
            
            % parse input
            p = inputParser;
            p.addRequired('inputObj',@(x)(isa(bp,'bipolar')));
            
            p.addParameter('name','ir1',@ischar);
            p.addParameter('eyeSide','left',@ischar);
            p.addParameter('eyeRadius',0,@isnumeric);
            p.addParameter('eyeAngle',0,@isnumeric);
            p.addParameter('species','macaque',@ischar);
            p.addParameter('nTrials',1,@isscalar);
            
            p.KeepUnmatched = true;
            
            p.parse(bp,varargin{:});
            
            obj.eyeSide   = p.Results.eyeSide;
            obj.eyeRadius = p.Results.eyeRadius;
            obj.eyeAngle  = p.Results.eyeAngle;
            obj.name      = p.Results.name;
            
            obj.numberTrials = p.Results.nTrials;

            obj.size      = bp.get('patch size'); % Bipolar patch
            obj.timeStep  = bp.get('time step');  % Temporal sampling
            
            bpC = bp.get('bipolarResponseCenter');
            obj.row = size(bpC,1);  obj.col = size(bpC,2);

            obj.mosaic = cell(1); % Cells are added by mosaicCreate method
            
            % Temporal equivalent eccentricity in deg
            obj.temporalEquivEcc = retinalLocationToTEE(obj.eyeAngle, obj.eyeRadius, obj.eyeSide);
            
        end
        
        function obj = mosaicCreate(varargin)
            obj = rgcMosaicCreate(varargin{:});
        end
        
        % set function, see irSet
        function obj = set(obj, varargin)
            obj = irSet(obj, varargin{:});
        end
        
        % get function, see irGet
        function val = get(obj, varargin)
            val = irGet(obj, varargin{:});
        end
        
        % IR Compute functions, that loop over the rgc mosaics
        function [obj, nTrialsSpikes] = compute(obj, inputObj, varargin)
            [obj, nTrialsSpikes] = irCompute(obj,  inputObj, varargin{:});
        end
        
        function obj = computeLinearSTSeparable(obj,varargin)
            obj = irComputeLinearSTSeparable(obj,varargin{:});
        end
        
        function obj = computeSpikes(obj, varargin)
            obj = irComputeSpikes(obj,  varargin{:});
        end
        
        % plot function, see irPlot
        function plot(obj, varargin)
            irPlot(obj, varargin{:});
        end
        
        % normalize function, see irNormalize
        function obj = normalize(obj,varargin)
            obj = irNormalize(obj, varargin{:});
        end      
        
    end
    
    % Methods that must only be implemented in the subclasses. 
    methods (Abstract, Access=public)
    end
    
    % Methods may be called by the subclasses, but are otherwise private
    methods (Access = protected)
        spConvolve(obj);
        timeConvolve(obj);
    end
    
    % Methods that are totally private (subclasses cannot call these)
    methods (Access = private)
    end
    
end


