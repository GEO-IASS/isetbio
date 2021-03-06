function optics = opticsCreate(opticsType,varargin)
%OPTICSCREATE  Create an optics structure
%   optics = OPTICSCREATE(opticsType,varargin)
%
% This function is typically called through oiCreate.  The optics structure
% is attached to the oi and manipulated by oiSet and oiGet.
%
% The optics structure contains a variety of parameters, such as f-number
% and focal length.  There are two types of optics models:  diffraction
% limited and shift-invariant.  See the discussion in opticsGet for more
% detail.
%
% Optics structures do not start out with a wavelength spectrum structure.
% This information is stored in the optical image.
%
% For diffraction-limited optics, the key parameter is the f-number.
%         
% Specifying human optics  creates a shift-invariant optics structure with
% human OTF data.
%
%      {'human'}     - Uses Marimont and Wandell (Hopkins) method (DEFAULT)
%      {'wvf human'} - Uses Wavefront toolbox and Thibos data
%         opticsCreate('wvf human',[wave=400:10:700],
%                                  [pupilMM=3],
%                                  [zCoefs=wvfLoadThibosVirtualEyes]);
%      {'diffraction'} - Typically f/4 optics
%
% Human and general shift-invariant models can also be created by
% specifying wavefront aberrations using Zernike polynomials.  There is a
% collection of wavefront methods to help with this (see wvfCreate,
% wvf<TAB>).  That is the method used here for 'wvf human'.
%
% Example:
%   optics = opticsCreate('diffraction');
%   optics = opticsCreate('human');     % Marimont and Wandell
%   optics = opticsCreate('wvf human'); % Thibos Zernike
%
% See also: oiCreate, opticsSet, opticsGet
%
% Copyright ImagEval Consultants, LLC, 2003.

if notDefined('opticsType'), opticsType = 'default'; end

opticsType = ieParamFormat(opticsType);

switch lower(opticsType)
    case {'diffraction','diffractionlimited'}
        % Standard camera (cell phone) optics
        optics = opticsDiffraction;
        
        % For diffraction case, set lens transmittance to 1
        % Perhaps we should allow the transmittance to be set freely as in
        % ISET?  Or ...
        optics.lens = Lens;  % Human lens object
        optics.lens.density = 0;   % Pigment density set to 0 
        
    case {'default','human','humanmw'}
        % Optics for the Marimont and Wandell human eye
        % Pupil radius in meters.  Default is 3 mm
        pupilRadius = 0.0015; % 3mm diameter default
        if ~isempty(varargin), pupilRadius = varargin{1}; end
        
        % This creates a shift-invariant optics. The other standard forms
        % are diffraction limited.
        optics = opticsHuman(pupilRadius);
        optics = opticsSet(optics, 'model', 'shift invariant');
        optics = opticsSet(optics, 'name', 'human-MW');
        optics.lens = Lens;  % Default human lens object

    case {'wvfhuman'}
        % Optics based on Zernike polynomial wavefront model estimated by
        % Thibos.
        % 
        % opticsCreate('wvf human',pupilMM,zCoefs,wave);
        
        % Defaults
        pupilMM = 3;
        zCoefs = wvfLoadThibosVirtualEyes(pupilMM);
        wave = 400:10:700; wave = wave(:);

        if ~isempty(varargin), pupilMM = varargin{1}; end
        if length(varargin)>1, zCoefs = varargin{2};  end
        if length(varargin)>2, wave = varargin{3}; wave = wave(:); end 
        
        % Create wavefront parameters
        wvfP = wvfCreate('wave',wave,'zcoeffs',zCoefs,'name',sprintf('human-%d',pupilMM));
        wvfP = wvfSet(wvfP,'calc pupil size',pupilMM);
        wvfP = wvfComputePSF(wvfP);
        % [u,p,f] = wvfPlot(wvfP,'2d psf space','um',550);
        % set(gca,'xlim',[-20 20],'ylim',[-20 20]);
        
        optics = oiGet(wvf2oi(wvfP),'optics');        
        optics = opticsSet(optics, 'model', 'shiftInvariant');
        optics = opticsSet(optics, 'name', 'human-wvf');        
        
        % Add Lens by default, now.
        optics.lens = Lens;

    case 'mouse'
        % Pupil radius in meters.  
        % Dilated pupil : 1.009mm = 0.001009m
        % Contracted pupil : 0.178 mm
        % (Source : From candelas to photoisomerizations in the mouse eye by 
        % rhodopsin bleaching in situ and the light-rearing dependence of 
        % the major components of the mouse ERG, Pugh, 2004)
        % We use a default value, in between : 0.59 mm.
        %         if ~isempty(varargin)
        %             pupilRadius = varargin{1};
        %             if pupilRadius > 0.001009 || pupilRadius < 0.000178
        %                 warning('Poor pupil size for the  mouse eye.')
        %             end
        %         else
        %             pupilRadius = 0.00059;   % default : 0.59 mm
        %         end
        %         % This creates a shift-invariant optics.  The other standard forms
        %         % are diffraction limited.
        %         optics = opticsMouse(pupilRadius);
        %         optics = opticsSet(optics,'model','shiftInvariant');
        %
        %     case {'standard(1/3-inch)','thirdinch'}
        %         optics = opticsThirdInch;
        %     case {'standard(1/2-inch)','halfinch'}
        %         optics = opticsHalfInch;
        %     case {'standard(2/3-inch)','twothirdinch'}
        %         optics = opticsTwoThirdInch;
        %     case {'standard(1-inch)','oneinch'}
        %         optics = opticsOneInch;
    otherwise
        error('Unknown optics type.');
end

% Default computational settings for the optical image
optics = opticsSet(optics,'offAxisMethod','cos4th');
optics.vignetting =    0;   % Pixel vignetting is off

end

%---------------------------------------
function optics = opticsDiffraction
% Standard diffraction limited optics with a 46-deg field of view and
% fnumber of 4.  Simple digital camera optics are like this.

optics.type = 'optics';
optics = opticsSet(optics,'name','ideal (small)');
optics = opticsSet(optics,'model','diffractionLimited');

% Standard 1/4-inch sensor parameters
sensorDiagonal = 0.004;
FOV = 46;
fLength = inv(tan(FOV/180*pi)/2/sensorDiagonal)/2;

optics = opticsSet(optics,'fnumber',4);  % focal length / diameter
optics = opticsSet(optics,'focalLength', fLength);  
optics = opticsSet(optics,'otfMethod','dlmtf');

end

%---------------------------------------
function optics = opticsHuman(pupilRadius)
% We use the shift-invariant method for the human and place the estimated
% human OTF, using humanOTF from Marimont and Wandell, in the OTF fields.
% 
% The frequency support is calculated in cyc/deg but stored in units of
% cyc/mm. (Sorry for that).  Elsewhere we use 300 microns/deg as the
% conversion factor. This value corresponds to a distance of 17mm (human
% focal length).  (Where? BW).

% We place fnumber and focal length values that are approximate for
% diffraction-limited in those fields, too.  But they are not a good
% description, just the diffraction limit bounds for this type of a system.
%
% The pupilRadius should is specified in meters.

if notDefined('pupilRadius'), pupilRadius = 0.0015; end
fLength = 0.017;  %Human focal length is 17 mm

optics.type = 'optics';
optics.name = 'human';
optics      = opticsSet(optics, 'model', 'shiftInvariant');

% Ratio of focal length to diameter.  
optics = opticsSet(optics, 'fnumber', fLength/(2*pupilRadius));  
optics = opticsSet(optics, 'focalLength', fLength);  

optics = opticsSet(optics, 'otfMethod', 'humanOTF');

% Compute the OTF and store it.  We use a default pupil radius, dioptric
% power, and so forth.

dioptricPower = 1/fLength;      % About 60 diopters

% We used to assign the same wave as in the current scene to optics, if the
% wave was not yet assigned.  
wave = opticsGet(optics, 'wave');

% The human optics are an SI case, and we store the OTF at this point.  
[OTF2D, fSupport] = humanOTF(pupilRadius, dioptricPower, [], wave);
optics = opticsSet(optics, 'otfData', OTF2D);

% Support is returned in cyc/deg. At the human retina, 1 deg is about 300
% microns, so there are about 3 cyc/mm.  To convert from cyc/deg to cyc/mm
% we divide by 0.3. That is:
%  (cyc/deg * (1/mm/deg)) cyc/mm.  1/mm/deg = 1/.3
fSupport = fSupport * (1/0.3);  % Convert to cyc/mm

fx     = fSupport(1, :, 1);
fy     = fSupport(:, 1, 2);
optics = opticsSet(optics, 'otffx', fx(:)');
optics = opticsSet(optics, 'otffy', fy(:)');

optics = opticsSet(optics, 'otfWave', wave);

end