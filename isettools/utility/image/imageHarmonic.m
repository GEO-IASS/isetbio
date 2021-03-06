function [img, parms] = imageHarmonic(parms)
% Creates a sum of harmonic images, potentially windowed by a Gaussian
%
%   [img,parms]  = imageHarmonic(parms)
%
% Creates a sum of windowed, oriented, spatial harmonics.  The basic
% function for each of the harmonics is this:
%
%    contrast*window.*cos(2*pi*f*([cos(ang)*X + sin(ang)*Y] + ph)) + 1
%
% When key fields are vectors (freq, contrast, ang, ph) then the return
% produces the sum of these harmonics.  The sum always has a mean of 1.
%
% The harmonic parameters are in the structure parms. The fields are
% defined below. 
%
% The Gabor Flag is used to set the window values (a Gaussian).
% When the flag is non-zero, the value specifies the standard deviation
% of the Gaussian as a fraction of the image size.  For example, if the
% image size is 128 and GaborFlag = 0.25, the standard deviation is 32.
% For non-square images, image size is taken as the minimum of the row
% and column image size.  
%
% To really keep you on your toes, if the flag is negative, the window is 
% a circular half-cosine, and the parameter is the length of the
% half-cosine (that is, like the radius).
%
% Default parameters are applied if parms is not sent in.  You can see the
% defaults by requesting them on return as below.
%
% Example:
%   [img,p] = imageHarmonic;
%   vcNewGraphWin; imagesc(img), colormap(gray); axis image
%
%   parms.row = 32; parms.col = 32; parms.contrast = 1; 
%   parms.ph = pi/2; parms.freq = 2; parms.ang = pi/6;
%   parms.GaborFlag = 0.2;
%   [img,p] = imageHarmonic(parms);
%   vcNewGraphWin; imagesc(img), colormap(gray); axis image
%
% Now, for a sum of two harmonics
%   parms.freq = [1,3]; parms.ang = [0, pi/2];
%   parms.contrast = [0.5 0.5]; parms.ph = [ 0 0];
%   [img,p] = imageHarmonic(parms);
%   vcNewGraphWin; imagesc(img), colormap(gray); axis image
%   plot(img(16,:))
%
%   parms.GaborFlag = 0; [img,p] = imageHarmonic(parms);
%   vcNewGraphWin; imagesc(img), colormap(gray); axis image
%
% Copyright ImagEval Consultants, LLC, 2003.

% If no parameters sent, use the default.
% Otherwise over-write the default with user specified parameters
if ~exist('parms','var'), parms = harmonicP;
else
    
    % Set up the default parameters
    dparms = harmonicP;
    
    % Check the user structure and over-write any of the parameters with the
    % user parameters
    if isfield(parms,'ang'), dparms.ang = parms.ang; end
    if isfield(parms,'contrast'), dparms.contrast = parms.contrast; end
    if isfield(parms,'freq'), dparms.freq = parms.freq; end
    if isfield(parms,'ph'), dparms.ph = parms.ph; end
    if isfield(parms,'row'), dparms.row = parms.row; end
    if isfield(parms,'col'), dparms.col = parms.col; end
    if isfield(parms,'GaborFlag'), dparms.GaborFlag = parms.GaborFlag; end
    parms = dparms;
end

%% Calculate the harmonic
x = (0:(parms.col-1))/parms.col; x = x - x(end)/2;
y = (0:(parms.row-1))/parms.row; y = y - y(end)/2;
[X,Y] = meshgrid(x,y);

% Calculate the gabor window, or the half-cosine if the
% space parameter is negative
if parms.GaborFlag
    sigmaParam = parms.GaborFlag*min(parms.row,parms.col);
    if (parms.GaborFlag > 0)
        g = fspecial('gauss',size(X),sigmaParam);
    else
        xArg = pi*parms.col*X/(-2*sigmaParam);
        yArg = pi*parms.row*Y/(-2*sigmaParam);
        g = cos(xArg).*cos(yArg);
        index = find(xArg < -pi/2 | xArg > pi/2 | yArg < -pi/2 | yArg > pi/2);
        g(index) = 0;
    end
    g = g/max(g(:));
else
    g = ones(size(X));
end

% Harmonics are (1 + sum(cos(2*pi*f*x + ph))
% with the additional possibility that X and Y can be oriented at some angle.
img = zeros(size(X));
for ii=1:length(parms.freq)
    img = img + ...
        parms.contrast(ii)*g.*cos( 2*pi*parms.freq(ii)* ...
        (cos(parms.ang(ii))*X + sin(parms.ang(ii))*Y) + parms.ph(ii)) ...
        + 1;
end
img = img / length(parms.freq);

if min(img(:) < 0)
    warning('Harmonics have negative sum, not realizable');
end

end


