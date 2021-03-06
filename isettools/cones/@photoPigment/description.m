function str = description(obj, varargin)
% Photopigment text description
%
% generate description string for this object
%

str = sprintf('Cone aperture:\t %.2f (w) x %.2f (h) um\n', ...
    obj.pdWidth*1e6, obj.pdHeight*1e6);
str = addText(str, sprintf('Gap:\t %.2f(w) x %.2f (h) um\n', ...
    obj.gapWidth*1e6, obj.gapHeight*1e6));
str = addText(str, ...
    sprintf('Photopigment density: %.2f (L), %.2f (M), %.2f (S)\n', obj.opticalDensity(1), ...
    obj.opticalDensity(2), obj.opticalDensity(3)));
str = addText(str, ...
    sprintf('Peak efficiency: %.2f (L), %.2f (M), %.2f (S)\n', obj.peakEfficiency(1), ...
    obj.peakEfficiency(2), obj.peakEfficiency(3)));

end