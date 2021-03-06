classdef rgcGLM < rgcMosaic
%RGCGLM - rgcMosaic using a GLM (coupled-nonlinear) computational model
% rgcGLM is a subclass of rgcMosaic. It is called when creating a new GLM
% model rgcMosaic for an inner retina object.  Typically we get here from
% the inner retina object with the call:
%
%   ir.mosaicCreate('model','GLM','type','your type goes here')
% 
% The coupled GLM model is published in Pillow, Shlens, Paninski, Sher,
% Litke, Chichilnisky & Simoncelli, Nature (2008). 
% 
% The computational model implemented here relies on code by
%  the: <a href="matlab:
%  web(http://pillowlab.princeton.edu/code_GLM.html','-browser')">Pillow Lab</a>.
% , which is
% distributed under the GNU General Public License.
%
% See also: rgcMosaic.m, rgcLNP.m
%
% Example:
% 
%   ir.mosaicCreate('model','GLM','type','on midget'); 
%
%  ISETBIO wiki: <a href="matlab:
%  web('https://github.com/isetbio/isetbio/wiki/Retinal-ganglion-cells','-browser')">RGCS</a>.
%  
% 9/2015 JRG (c) isetbio team
% 7/2016 JRG updated

%% Properties 
    % Public, read-only properties.
    
    properties (SetAccess = public, GetAccess = public)
        % DT Parameter to specify the time bins Pillow uses for coupling and
        % post spike filters (.01 = 100 bins per linear time sample)
        dt = 0.1;
    end
    
    properties (SetAccess = private, GetAccess = public)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % rgcGLM is a subclass of rgcMosaic.
        % See the rgcMosaic superclass for many more properties
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                       
        % GENERATORFUNCTION Pillow promotes the linear input voltage using a nonlinear
        % function that he calls the generator function.  By default this
        % is an exponential.
        generatorFunction;
        
        % RESPONSEVOLTAGE The nonlinear voltage response after application of the generator
        % function and the spike coupling responses is represented here
        responseVoltage;
        
        % POSTSPIKEFILTER These hold the parameters used in the computation.
        % This is the response after a spike
        postSpikeFilter;
        
        % COUPLINGFILTER This is the time course of the voltage responses generated by a
        % spike and propagated to nearby neurons
        couplingFilter;
        
        % COUPLINGMATRIX This is the matrix of connections between nearby neurons
        couplingMatrix;
        
    end
    
    % Private properties. Only methods of the parent class can set these
    properties(Access = private)
    end
  
%% Methods
    % Public methods
    methods
        
        % Constructor
        function obj = rgcGLM(ir, mosaicType)
            
            % Initialize the mosaic parent class
            obj = obj@rgcMosaic(ir, mosaicType);
            
            % The Pillow generator function
            obj.generatorFunction = @exp;

            % Effect of a spike on output voltages
            obj.postSpikeFilter = buildPostSpikeFilter(obj.dt);
            
            % Coupling filters between nearby ganglion cells
            [obj.couplingFilter, obj.couplingMatrix] = buildCouplingFilters(obj, obj.dt);
            
        end
        
        % set function, see @rgcGLM/mosaicSet.m for details
        function obj = set(obj, varargin)
            mosaicSet(obj, varargin{:});
        end
        
        % get function, see @rgcGLM/mosaicGet.m for details
        function val = get(obj, varargin)
           val = mosaicGet(obj, varargin{:});
        end
      
    end
    
    methods (Access = public)
        
    end
    
    % Methods may be called by the subclasses, but are otherwise private 
    methods (Access = protected)
    end
    
    % Methods that are totally private (subclasses cannot call these)
    methods (Access = private)
    end
    
end
