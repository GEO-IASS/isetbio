function p = osInit(varargin)
% Initialize parameters in Rieke adaptation model
%
%    p = osInit
% 
% The difference equation model implemented in the computation of the
% osBioPhys outer segment current takes a number of parameters in order to
% initialize the current response. 
% 
% This function allows the user to choose between two sets of parameters,
% one for peripheral patches and one for foveal patches. The foveal cone
% response is slightly slower than the peripheral, as shown by their
% impulse responses.%
% 
% Reference:
%   http://isetbio.org/cones/adaptation%20model%20-%20rieke.pdf
%   https://github.com/isetbio/isetbio/wiki/Cone-Adaptation
% 
% See also:  osAdaptSteadyState, osAdaptTemporal, coneAdapt
%
% HJ, ISETBIO Team Copyright 2014


p = inputParser;
addParameter(p,'osType',0,@islogical);
p.parse(varargin{:});

osType = p.Results.osType;

switch osType
    case 0 % peripheral
        % Init parameters
        sigma = 22;  % rhodopsin activity decay rate (1/sec) - default 22
        phi = 22;     % phosphodiesterase activity decay rate (1/sec) - default 22
        eta = 2000;	  % phosphodiesterase activation rate constant (1/sec) - default 2000
        gdark = 20.5; % concentration of cGMP in darkness - default 20.5
        k = 0.02;     % constant relating cGMP to current - default 0.02
        h = 3;       % cooperativity for cGMP->current - default 3
        cdark = 1;  % dark calcium concentration - default 1
        beta = 9;	  % rate constant for calcium removal in 1/sec - default 9
        betaSlow = 0.4; % rate constant for slow calcium modulation of channels - default 0.4
        n = 4;  	  % cooperativity for cyclase, hill coef - default 4
        kGc = 0.5;   % hill affinity for cyclase - default 0.5
        OpsinGain = 10; % so stimulus can be in R*/sec (this is rate of increase in opsin activity per R*/sec) - default 10
        
    case 1 % foveal - slower than peripheral
        % Init parameters
        sigma = 10;  % rhodopsin activity decay rate (1/sec) - default 22
        phi = 22;     % phosphodiesterase activity decay rate (1/sec) - default 22
        eta = 700;      % phosphodiesterase activation rate constant (1/sec) - default 2000
        gdark = 20.5; % concentration of cGMP in darkness - default 20.5
        k = 0.02;     % constant relating cGMP to current - default 0.02
        h = 3;       % cooperativity for cGMP->current - default 3
        cdark = 1;  % dark calcium concentration - default 1
        beta = 5;      % rate constant for calcium removal in 1/sec - default 9
        betaSlow = 0.4; % rate constant for slow calcium modulation of channels - default 0.4
        n = 4;        % cooperativity for cyclase, hill coef - default 4
        kGc = 0.5;   % hill affinity for cyclase - default 0.5
        OpsinGain = 12; % so stimulus can be in R*/sec (this is rate of increase in opsin activity per R*/sec) - default 10
        
        
end

% Compute more parameters - steady state constraints among parameters
q    = 2 * beta * cdark / (k * gdark^h);
smax = eta/phi * gdark * (1 + (cdark / kGc)^n);

% Used for finding the steady-state current
p = struct('sigma',sigma, 'phi',phi, 'eta',eta, 'gdark',gdark,...
    'k',k,'cdark',cdark,'beta',beta,'betaSlow',betaSlow,  ...
    'n',n,'kGc',kGc,'h',h,'q',q,'smax',smax','OpsinGain',OpsinGain);

end