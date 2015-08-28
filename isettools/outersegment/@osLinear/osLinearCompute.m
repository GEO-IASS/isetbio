function obj = osLinearCompute(obj, sensor, varargin)
% osLinearCompute: a method of @osLinear that computes the linear filter
% response of the L, M and S cone outer segments. This converts
% isomerizations (R*) to outer segment current (pA). If the noiseFlag
% property of the osLinear object is set to 1, this method will add noise
% to the current output signal.
%
% adaptedOS = osLinearCompute(adaptedOS, sensor);
%
% Inputs: the osLinear object, the sensor object and an optional parameters
% field. params.offest determines the current offset.
% 
% Outputs: 
% 8/2015 JRG NC DHB


% Remake filters incorporating the sensor to make them the 
% correct sampling rate.
obj.filterKernel(sensor);

% Find coordinates of L, M and S cones, get voltage signals.
cone_mosaic = sensorGet(sensor,'cone type');

% Get isomerization array to convert to current (pA).
isomerizations = sensorGet(sensor, 'photon rate');

% Get number of time steps.
nSteps = size(sensor.data.volts,3);

% The next step is to convolve the 1D filters with the 1D isomerization
% data at each point in the cone mosaic. This code was adapted from the
% riekeLinearCone.m file by FR and NC.

initialState = riekeInit;
initialState.timeInterval = sensorGet(sensor, 'time interval');
initialState.Compress = 0; % ALLOW ADJUST - FIX THIS

% Place limits on the maxCur and prescribe the meanCur.
maxCur = initialState.k * initialState.gdark^initialState.h/2;
meanCur = maxCur * (1 - 1 / (1 + 45000 / mean(isomerizations(:))));
[sz1, sz2, sz3] = size(isomerizations);
isomerizationsRS = reshape(isomerizations(:,:,1:sz3),[sz1*sz2],nSteps);

adaptedDataRS = zeros(size(isomerizationsRS));

% Do convolutions by cone type.
for cone_type = 2:4
    % Pull out the appropriate 1D filter for the cone type.
    % Filter_cone_type = newIRFs(:,cone_type-1);
    switch cone_type
        case 2
            FilterConeType = obj.sConeFilter;
        case 3
            FilterConeType = obj.mConeFilter;
        case 4
            FilterConeType = obj.lConeFilter;
    end
    
    % Only place the output signals corresponding to pixels in the mosaic
    % into the final output matrix.
    cone_locations = find(cone_mosaic==cone_type);
    
    
    isomerizationsSingleType = isomerizationsRS(cone_locations,:);
    
    if (ndims(isomerizations) == 3)
        
        % pre-allocate memory
        adaptedDataSingleType = zeros(size(isomerizationsSingleType));
        
        for y = 1:size(isomerizationsSingleType, 1)
            
            tempData = conv(isomerizationsSingleType(y, :), FilterConeType);
            %        tempData = real(ifft(conj(fft(squeeze(isomerizations(x, y, :))) .* FilterFFT)));
            if (initialState.Compress)
                tempData = tempData / maxCur;
                tempData = meanCur * (tempData ./ (1 + 1 ./ tempData)-1);
            else
                tempData = tempData - meanCur;
            end
            adaptedDataSingleType(y, :) = tempData(1:nSteps);
            
        end
        
        %     elseif (ndims(isomerizations) == 2)
        %
        %         % pre-allocate memory
        %         adaptedData = zeros(size(isomerizations,1),timeBins);
        %
        %         for xy = 1:size(isomerizations, 1)
        %             tempData = conv(squeeze(isomerizations(xy, :)), Filter);
        %             if (initialState.Compress)
        %                 tempData = tempData / maxCur;
        %                 tempData = meanCur * (tempData ./ (1 + 1 ./ tempData)-1);
        %             else
        %                 tempData = tempData - meanCur;
        %             end
        %             adaptedData(xy, :) = tempData(1:timeBins);
        %         end
        %     end
        
        adaptedDataRS(cone_locations,:) = adaptedDataSingleType;
        
    end
    
    
end

% Reshape the output signal matrix.
adaptedData = reshape(adaptedDataRS,[sz1,sz2,sz3]);
obj.ConeCurrentSignal = adaptedData;

if size(varargin) ~= 0
    if isfield(varargin{1,1},'offset')
        obj.ConeCurrentSignal = obj.ConeCurrentSignal - obj.ConeCurrentSignal(:, :, nSteps) - varargin{1,1}.offset;
    end
end

% Add noise if the flag is set.
if obj.noiseFlag == 1
    params.sampTime = sensorGet(sensor, 'time interval');
    ConeSignalPlusNoiseRS = riekeAddNoise(adaptedDataRS, params); close;
    obj.ConeCurrentSignalPlusNoise = reshape(ConeSignalPlusNoiseRS,[sz1,sz2,nSteps]);
    
    if size(varargin) ~= 0
        if isfield(varargin{1,1},'offset')
            obj.ConeCurrentSignalPlusNoise = obj.ConeCurrentSignalPlusNoise - obj.ConeCurrentSignalPlusNoise(:, :, nSteps) - varargin{1,1}.offset;
        end
    end
    
end


