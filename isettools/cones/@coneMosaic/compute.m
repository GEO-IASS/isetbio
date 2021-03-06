function [absorptions, current, interpFilters, meanCur] = compute(obj, oi, varargin)
%COMPUTE Compute the cone absorptions, possibly for multiple trials (repeats)
%   Compute the temporal sequence of cone absorptions, which we treat as
%   isomerizations, R*.  The computation can executed on
%   * a single optical image (snapshot)
%   * a single optical image with a series of eye movements, or
%   * an optical image sequence with a series of eye movements.
%
%   [absorptions, current, interpFilters, meanCur] = COMPUTE(obj,oi,varargin);
%   [absorptions, current, interpFilters, meanCur] = COMPUTE(obj,oiSequence,varargin);
%
%   Inputs:
%   obj - a coneMosaic object
%   oi  - optical image, or oiSequence.  See oiCreate for more details
%
%   Outputs:
%   absorptions   - cone photon absorptions
%   current       - cone photocurrent
%   interpFilters - photon to photocurrent impulse response functions
%   meanCur       - mean current level
%
%   Optional parameter name/value pairs chosen from the following:
%
%   'currentFlag'        Also compute photocurrent (default false). 
%   'seed' -             Seed to use when obj.noiseFlag is 'frozen (default 1). 
%   'emPath'             Eye movement path (see below), Nx2 matrix (default obj.emPositions).  
%   'theExpandedMosaic'  [NICOLAS TO FILL IN]
%
%   Note that additional name/value pairs will be passed on to routine
%   COMPUTEFOROISEQUENCE if the input argumment oi is in fact an oiSequence
%   object.  See COMPUTEFOROISEQUENCE for more information.
%
%   An eye movement path (emPath) can be generated using
%   coneMosaic.emGenSequence or it can be sent in as the 'emPath' variable.
%   For a single trial, the emPath is a series of (row,col) positions with
%   respect to the cone mosaic. For the single trial case, we recommend
%   setting the coneMosaic.emPositions or using coneMosaic.emGenSequence.
% 
%   You can execute a multiple trial calculation by setting the eye
%   movement variable to a 3D array
%          emPath: (nTrials , row , col)
%   In that case, we return the absorptions and possibly photocurrent for
%   nTrials in a 2D matrix of dimension (nTrials x nTime, nPixels).  If you
%   set the currentFlag to true, then the current is also returned in a
%   matrix of the same size.
%
%   The cone photon absorptions are computed according to obj.noiseFlag,
%   which can be 'random','frozen', or 'none'.  If 'frozen', then you can
%   set the 'seed' parameter.  The default when a mosaic is created is
%   'random'.
%
%   The cone photocurrent is computed according to obj.os.noiseFlag, which
%   can also be set to 'random','frozen', or 'none', as above. The default
%   when an os object is created is 'random'.
%
%   See also CONEMOSAIC, COMPUTEFOROISEQUENCE.

% HJ ISETBIO Team 2016

%% If an oi sequence, head that way
%
% Send to the specialized compute in that case.
if isequal(class(oi),'oiSequence')
    [absorptions, current, interpFilters, meanCur] = obj.computeForOISequence(oi,varargin{:});
    return;
end

%% Parse inputs
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('oi', @isstruct);
p.addParameter('currentFlag', false, @islogical);
p.addParameter('seed', 1, @isnumeric);
p.addParameter('emPath', obj.emPositions, @isnumeric);
p.addParameter('theExpandedMosaic', []);
p.parse(oi,varargin{:});
currentFlag = p.Results.currentFlag;
seed        = p.Results.seed;
emPath      = p.Results.emPath;
theExpandedMosaic = p.Results.theExpandedMosaic;

obj.absorptions = [];
obj.current = [];

%% Set eye movement path
%
% I would prefer to delete this parameter altogether and force people to
% set the emPositions prior to calling this compute.  But when we have
% multiple trials, emPath is (nTrials x row x col), and emGenSequence
% doesn't have an nTrials parameter.  
%
% So, perhaps we can modify to be
%    emGenSequence(nPositions,'nTrials',nTrials);
obj.emPositions = emPath;

% This code efficiently calculates the effects of eye movements by enabling
% us to calculate the cone absorptions once, and then to account for the
% effect of eye movements. The logic is this:
%
% We make a full LMS calculation so that we know the LMS absorptions at
% every cone mosaic position.  We need to do this only once.
%
% We then move the eye to a position and pull out the LMS values that match
% the spatial pattern of the cones in the grid, but centered at the next
% eye movement location.
%
% We base this calculation on a copy for the cone mosaic.

% We need a copy of the object because of eye movements.
if (isempty(theExpandedMosaic))
    % We are not passed theExpandedMosaic. 
    % Generate it here.
    padRows = max(abs(emPath(:, 2)));
    padCols = max(abs(emPath(:, 1)));
    theExpandedMosaic = obj.copy();
    theExpandedMosaic.pattern = zeros(obj.rows+2*padRows, obj.cols+2*padCols);
elseif isa(theExpandedMosaic, 'coneMosaic')
    % OK, we are passed theExpandedMosaic. 
    % Set the current path and integrationTime and use it.
    theExpandedMosaic.emPositions = obj.emPositions;
    theExpandedMosaic.integrationTime = obj.integrationTime;
    theExpandedMosaic.absorptions = [];
    padRows = round((theExpandedMosaic.rows-obj.rows)/2);
    padCols = round((theExpandedMosaic.cols-obj.cols)/2);
else
    error('theExpandedMosaic passed is not a @coneMosaic');
end

% Compute full LMS noise free absorptions
absorptions = theExpandedMosaic.computeSingleFrame(oi, 'fullLMS', true);
    
% Deal with eye movements
absorptions = obj.applyEMPath(absorptions, 'emPath', emPath, 'padRows', padRows, 'padCols', padCols);

% dbstop in compute.m at 138 if sum(absorptions(:))<1

% Add photon noise to the whole volume
switch obj.noiseFlag
    case {'frozen','random'}
        if (isa(obj, 'coneMosaicHex'))
            % Only call photonNoise on the non-null cones for a hex mosaic.
            nonNullConeIndices = find(obj.pattern > 1);
            timeSamples = size(absorptions,3);
            absorptions = reshape(permute(absorptions, [3 1 2]), [timeSamples size(obj.pattern,1)*size(obj.pattern,2)]);
            absorptionsCopy = absorptions;
            absorptions = absorptions(:, nonNullConeIndices);
            
            % Add noise
            absorptionsCopy(:, nonNullConeIndices) = obj.photonNoise(absorptions, 'noiseFlag',obj.noiseFlag,'seed',seed);
            absorptions = permute(reshape(absorptionsCopy, [timeSamples size(obj.pattern,1) size(obj.pattern,2)]), [2 3 1]);
            clear 'absorptionsCopy'
        else % Rectangular mosaic
            % Add noise
            absorptions = obj.photonNoise(absorptions,'noiseFlag',obj.noiseFlag,'seed',seed);
        end
    case {'none'}
        % No noise
    otherwise
        error('Invalid noise flag passed');
end

% Set the absorptions in the object.
obj.absorptions = absorptions;

%% Compute photocurrent if requested
current       = [];
interpFilters = [];
meanCur       = [];
if currentFlag
    warning('Suggest using coneMosaic.computeCurrent');
    if size(obj.absorptions,3) == 1
        disp('Absorptions are a single frame.  No current to calculate.')        
        return;
    else
        [obj.current, interpFilters, meanCur] = obj.os.osCompute(cMosaic);
    end
end

end

