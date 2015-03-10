function fullname = ieReadMultipleFileNames(imgDir, prompt)
% Read the names of multiple NEF files acquired with a single color filter.
%
%  fullname = ieReadMultipleFileNames(imgDir,[prompt])
%
%   Read the names of NEF files acquired with a single color filter.  The
%   routine finds all of the files in a subdirectory, displays them in a
%   listbox, and lets the user select the ones for reading.
%
%   The selected file names are returned as full path files in a cell
%   array, fullname{}. Used with the multicapture (mc) toolbox.
%
% Copyright ImagEval Consultants, LLC, 2003.

if notDefined('prompt'), prompt = ''; end

if notDefined('imgDir')
    imgDir = uigetdir('', 'Directory of NEF files');
    if isequal(imgDir,0), fullname = []; return; end
end

d = dir(imgDir);
str = {d.name};
[s, ~] = listdlg('PromptString', prompt, ...
                 'Name', 'Select files', ...
                 'ListString', str, ...
                 'ListSize',[240,600]);
if isempty(s), 
    fullname = [];
else
    fullname = cell(length(s), 1);
    for ii=1:length(s)
        fullname{ii} = fullfile(imgDir,str{s(ii)}); 
    end
end

end

