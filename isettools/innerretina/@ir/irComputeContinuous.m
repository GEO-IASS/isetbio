function ir = irComputeContinuous(ir, outerSegment, varargin)
% Computes the rgc mosaic spikes to an arbitrary stimulus.
%
% The responses for each mosaic are computed one at a time. For a given
% mosaic, first the spatial convolution of the center and surround RFs are
% calculated for each RGB channel, followed by the temporal responses for
% the center and surround and each RGB channel. This results in the linear
% response.
%
% Next, the linear response is put through the generator function. The
% nonlinear response is the input to a function that computes spikes with
% Poisson statistics. For the rgcGLM object, the spikes are computed using
% the recursive influence of the post-spike and coupling filters between
% the nonlinear responses of other cells. These computations are carried
% out using code from Pillow, Shlens, Paninski, Sher, Litke, Chichilnisky,
% Simoncelli, Nature, 2008, licensed for modification, which can be found
% at
%
% http://pillowlab.princeton.edu/code_GLM.html
%
% Outline:
%  * Normalize stimulus
%  * Compute linear response
%     - spatial convolution
%     - temporal convolution
%  * Compute nonlinear response
% [spiking responses are calculated by subclass versions of rgcCompute]
%
% Inputs: inner retina object, outersegment object.
%
% Outputs: the inner object with fixed linear and noisy spiking responses.
%
% Example:
%   ir.compute(identityOS);
%   irCompute(ir,identityOS);
%
% See also: rgcGLM/rgcCompute
%
% JRG (c) isetbio team

%%
p = inputParser;
p.CaseSensitive = false;

p.addRequired('ir',@(x) isequal(class(x),'ir'));
% validatestring(class(outerSegment),{'osIdentity','osLinear','osBioPhys'})
p.addRequired('outerSegment',@(x) ~isempty(validatestring(class(x),{'osIdentity','osLinear','osBioPhys'})));
% p.parse(ir,outerSegment,varargin{:});
osType = class(outerSegment);
%% Get the input data

% Possible osTypes are osIdentity, osLinear, and osBiophys
% Only osIdentity is implemented now.
osType = class(outerSegment);
switch osType
    case 'osIdentity'
        %% Identity means straight from the frame buffer to brain
        % Find properties that haven't been set and set them
        if isempty(osGet(outerSegment,'rgbData'))
            outerSegment = osSet(outerSegment, 'rgbData', rand(64,64,5));
        end
        if isempty(osGet(outerSegment,'coneSpacing'))
            outerSegment = osSet(outerSegment, 'coneSpacing', 180);
        end
        if isempty(osGet(outerSegment,'coneSampling'))
            outerSegment = osSet(outerSegment,'coneSampling',.01);
        end
        
        
        %% Linear computation       
        
        % Determine the range of the rgb input data
        spTempStim = osGet(outerSegment, 'rgbData');
        range = max(spTempStim(:)) - min(spTempStim(:));
        
        % Special case. If the ir class is rgcPhys, which we use for
        % validation. But in general, this is not the case. There is a
        % scientific question about this 10.  We need JRG and EJ to resolve
        % the spiking rate.
        % James needs to change the spatial RF and temporal weights in order to
        % make these models have the right spike rate, and the 10 is a hack to
        % approximate that.
        if isequal(class(ir),'irPhys'),   spTempStim = spTempStim./range;
        else                    spTempStim = 10*spTempStim./range;
        end
        
        % Looping over the rgc mosaics
        for rgcType = 1:length(ir.mosaic)
            
            % We use a separable space-time receptive field.  This allows
            % us to compute for space first and then time. Space.
            [spResponseCenter, spResponseSurround] = spConvolve(ir.mosaic{rgcType,1}, spTempStim);
            
            % For the subunit model, put each pixel "subunit" of spatial RF
            % through nonlinearity at this point
            if isa(ir.mosaic{rgcType},'rgcSubunit')
                % Change this to get generator function
                spResponseCenter = cellfun(@exp,spResponseCenter,'uniformoutput',false);
                spResponseSurround = cellfun(@exp,spResponseSurround,'uniformoutput',false);
            end
            
            % Convolve with the temporal impulse response
            responseLinear = ...
                fullConvolve(ir.mosaic{rgcType,1}, spResponseCenter, spResponseSurround);
            
            % Store the linear response
            ir.mosaic{rgcType} = mosaicSet(ir.mosaic{rgcType},'responseLinear', responseLinear);
            
        end
        
    case {'osLinear','osBioPhys'}
        %% Linear OS
        
        % Programming TODO: Connect L, M and S cones to RGC centers and
        % surrounds appropriately
               
        % Determine the range of the cone current
        spTempStim = osGet(outerSegment, 'coneCurrentSignal');
        
        % Probably need to do this by cone type
        range = max(spTempStim(:)) - min(spTempStim(:));
        
        % Special case. If the ir class is rgcPhys, which we use for
        % validation. But in general, this is not the case. There is a
        % scientific question about this 10.  We need JRG and EJ to resolve
        % the spiking rate.
        % James needs to change the spatial RF and temporal weights in order to
        % make these models have the right spike rate, and the 10 is a hack to
        % approximate that.
        spTempStim = spTempStim./range;
        
        % Looping over the rgc mosaics
        for rgcType = 1:length(ir.mosaic)
            
            % We use a separable space-time receptive field.  This allows
            % us to compute for space first and then time. Space.
            [spResponseCenter, spResponseSurround] = spConvolve(ir.mosaic{rgcType,1}, spTempStim);
            
            % For the subunit model, put each pixel "subunit" of spatial RF
            % through nonlinearity at this point
            if isa(ir.mosaic{rgcType},'rgcSubunit')
                % Change this to get generator function
                spResponseCenter = cellfun(@exp,spResponseCenter,'uniformoutput',false);
                spResponseSurround = cellfun(@exp,spResponseSurround,'uniformoutput',false);
            end
            
            % Convolve with the temporal impulse response
            % responseLinear = ...
            %    fullConvolve(ir.mosaic{rgcType,1}, spResponseCenter, spResponseSurround);
            
            % spResponseSum = cellfun(@plus,spResponseCenter ,spResponseSurround,'uniformoutput',false);
            % spResponseVecRS = cellfun(@sum,(cellfun(@sum,spResponseSum,'uniformoutput',false)),'uniformoutput',false);
            % spResponseVec=cellfun(@squeeze,spResponseVecRS,'uniformoutput',false);
            
            cellCtr = 0;
            nCells = size(ir.mosaic{rgcType}.cellLocation);
            for xc = 1:nCells(1)
                for yc = 1:nCells(2)
                    spResponseFull = spResponseCenter{xc,yc} + spResponseSurround{xc,yc};
                    spResponseVec{xc,yc} = squeeze(mean(mean(spResponseFull,1),2))';
                end
            end
            
            % Store the linear response
            ir.mosaic{rgcType} = mosaicSet(ir.mosaic{rgcType},'responseLinear', spResponseVec);
            
        end
%     case {'osBioPhys'}
%         %% Full biophysical os
%         error('Not yet implemented');
    otherwise
        error('Unknown os type %s\n',osType);
end




