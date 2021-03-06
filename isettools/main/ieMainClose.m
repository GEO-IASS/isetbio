function ieMainClose
% Close the all the ISET windows and the ieMainwindow
%
%     ieMainClose
%
% The routine checks for various fields, closes all the main windows
% properly. 
%
% Copyright ImagEval Consultants, LLC, 2005.

global vcSESSION

if ~checkfields(vcSESSION,'GUI'); closereq; return; end

if checkfields(vcSESSION.GUI,'vcSceneWindow','hObject')
    sceneWindow;
    sceneClose;
end

if checkfields(vcSESSION.GUI,'vcOptImgWindow','hObject')
    oiWindow;
    oiClose;
end

if checkfields(vcSESSION.GUI,'vcSensImgWindow','hObject')
    sensorImageWindow;
    sensorClose;
end

if checkfields(vcSESSION.GUI,'vcConeImgWindow','hObject')
    try
        delete(vcSESSION.GUI.vcConeImgWindow.hObject);
    catch
    end
    vcSESSION.GUI = rmfield(vcSESSION.GUI,'vcConeImgWindow');
end

vcSESSION.GUI = [];
closereq;

return;