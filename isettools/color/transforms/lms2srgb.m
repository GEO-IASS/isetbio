function srgb = lms2srgb(lms)
% Convert LMS data to sRGB format for visualization
%
%  srgb = lms2srgb(lms)
%
% See Also: s_HumanColorBlind
%
% Example:
%  scene    = sceneCreate; imgXYZ   = sceneGet(scene,'xyz');
%  whiteXYZ = sceneGet(scene,'illuminant xyz');
%
%  lms = xyz2lms(imgXYZ, 1, 'Brettel', whiteXYZ);  % Protan view
%  imagesc(lms2srgb(lms))
%
%  lms = xyz2lms(imgXYZ, 0);  % Normal view
%  imagesc(lms2srgb(lms))
%
% (c) ImagEval copyright 2012

srgb = xyz2srgb(imageLinearTransform(lms, colorTransformMatrix('lms2xyz')));

end