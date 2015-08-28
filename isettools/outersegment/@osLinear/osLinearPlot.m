function osLinearPlot(obj, sensor)
% osLinearPlot: a method to plot the input, filters and computed results of 
% the outsergment object.
% 
% 
% 8/2015 JRG NC DHB

dt = sensorGet(sensor, 'time interval');

% fprintf('<strong>\n%s:\n\t%s()\n</strong>', class(obj), mfilename());

% Plot input signal (isomerizations) at a particular (x, y) over time.
figNum = 1; 
h = figure();
set(h, 'Name', sprintf('Output of %s', class(obj)));
set(h, 'Position', [10+50*figNum 10+50*figNum, 1024 256]);
subplot(1,3,1);
% since data is in (x, y, t) format, choose an (x, y) value to observe over
% time
isomerizations1 = sensor.data.volts;
[sz1 sz2 sz3] = size(isomerizations1); 
inputSignal = squeeze(isomerizations1(round(sz1/2),round(sz2/2),:));
plot((0:numel(inputSignal)-1)*dt, inputSignal, 'k-');
title('input signal');
xlabel('Time (sec)');
ylabel('R*');

% Plot linear temporal filters for L, M and S cones.
subplot(1,3,2);
hold on;
plot((0:numel(obj.sConeFilter)-1)*dt, obj.sConeFilter,'b'); 
plot((0:numel(obj.mConeFilter)-1)*dt,obj.mConeFilter,'g'); 
plot((0:numel(obj.lConeFilter)-1)*dt,obj.lConeFilter,'r');
title('L, M, S cone filter kernels');
xlabel('Time (sec)');
ylabel('pA');

% Plot output signal at a particular (x, y) over time.
subplot(1,3,3);
outputSignal(1,:) = obj.ConeCurrentSignal(round(sz1/2),round(sz2/2),:);
plot((0:numel(outputSignal)-1)*dt, outputSignal, 'k-');
title('output signal');
xlabel('Time (sec)');
ylabel('pA');

drawnow;