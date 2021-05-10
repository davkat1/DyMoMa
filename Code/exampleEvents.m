% Example for creating and using events

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com

%% Create and define a DynamicModel object - see DyMoMa/example.m for more info
m = DynamicModel();
setTime(m, '01/01/2001 00:00:00', [0 48]);

addParam(m, 'lue', 7.5e-8);
addParam(m, 'heatLoss', 1);
addParam(m, 'heatEff', 0.1);
addParam(m, 'gasPrice', 4.55e-4);
addParam(m, 'lettucePrice', 136.4);
addParam(m, 'heatMin', 0);
addParam(m, 'heatMax', 100);

addInput(m, 'rad');
addInput(m, 'tempOut');
time = (0:48)';
setVal(m.d.rad, [time max(0, 800*sin(4*pi*time/48-0.65*pi))]);
setVal(m.d.tempOut, [time 15+10*sin(4*pi*time/48-0.65*pi)]);

addState(m, 'dryWeight');
addState(m, 'tempIn');

% Control for heating
addControl(m, 'heating');
m.u.heating = proportionalControl(m.x.tempIn, 17, -4, m.p.heatMin, m.p.heatMax);
m.u.heating.val = 0;

% Photosynthesis [kg m^{-2} h^{-1}], equation 2.1 [1] 
addAux(m, 'phot', m.p.lue.*m.d.rad.*m.x.tempIn.*m.x.dryWeight); 

% Heat loss to the outside [degC h^{-1}], equation 2.2 [1] 
addAux(m, 'heatOut', m.p.heatLoss.*(m.d.tempOut - m.x.tempIn)); 

% Heat gain from the pipes [degC h^{-1}], equation 2.2 [1] 
addAux(m, 'heatIn', m.p.heatEff.*m.u.heating);

% Photosynthesis [kg m^{-2} h^{-1}], equation 2.1 [1] 
setOde(m, 'dryWeight', m.a.phot); 

% Heat gain in the greenhouse [degC h^{-1}], equation 2.2 [1] 
setOde(m, 'tempIn', m.a.heatOut + m.a.heatIn);

% Set initial values for the states
setVal(m.x.dryWeight, 1); % kg m^{-2} 
setVal(m.x.tempIn, 10); % degC

% make a copy of m
mEvents = DynamicModel(m);

% Solve m
solveFromFile(m, 'ode15s')
figure;
subplot(3,1,1)
plot(m.x.tempIn);
yyaxis right
plot(m.x.dryWeight);
legend('m.x.tempIn','m.x.dryWeight','Location','nw');
title('Simulation without events')
%% Define events
% Events are an attribute e of a DynamicModel, 
% defined as an array of structs with the following properties:
%   e.condition: a state of the DynamicModel.
%   e.direction: a numerical value of -1, 0, or 1.
%   e.resetVars: an array of states of the DynamicModel.
%   e.resetVals: an array of numerical values corresponding to e.resetVars
%
% Events are treated by DyMoMa in the following way: 
% an event occurs when the state e.condition reaches the value 0 with a 
% certain direction depending on e.direction. 
% If e.direction is 0, the event occurs regardless of direction. 
% If e.direction is 1, the event occurs only when e.condition reached 0 while increasing 
%   (i.e., it was negative before)
% and if e.direction is -1, the event occurs only when e.condition reached 0 while decreasing 
%   (i.e., it was positive before). 
% Once the event occurs, the states listed in the array e.resetVars 
% are reset to the values in e.resetVals, and the simulation conitnues.

% Add states that will trigger events
addState(mEvents, 'tempSum');
setOde(mEvents, 'tempSum', mEvents.x.tempIn); % tempSum is the number of degree hours, with baseline temperature 0°C
setVal(mEvents.x.tempSum, -500); % tempSum starts at -1000

addState(mEvents, 'lightSum');
setOde(mEvents, 'lightSum', mEvents.d.rad); % lightSum is the cumulative sum of sunlight
setVal(mEvents.x.lightSum, -10000); % lightSum starts at -10000

% first event
mEvents.e(1).condition = mEvents.x.tempSum; % event is trigerred when tempSum==0
mEvents.e(1).direction = 1; % tempSum needs to be rising to trigger event

% when the event is triggered set tempSum back to -500
mEvents.e(1).resetVars = mEvents.x.tempSum; 
mEvents.e(1).resetVals = -500;

% second event
mEvents.e(2).condition = mEvents.x.lightSum; % event is trigerred when lightSum==0
mEvents.e(2).direction = 0; % direction of lightSum doesn't matter

% when the event is triggered set all states to their initial values
mEvents.e(2).resetVars = [mEvents.x.lightSum mEvents.x.tempSum mEvents.x.dryWeight mEvents.x.tempIn]; 
mEvents.e(2).resetVals = [-10000            -500               1                   10              ];

solveFromFile(mEvents, 'ode15s')

subplot(3,1,2)
plot(mEvents.x.tempIn);
text(39, 24.5, '<- Second event');
yyaxis right
plot(mEvents.x.dryWeight);
legend('mEvents.x.tempIn','mEvents.x.dryWeight','Location','nw');
text(39, 1.017, '<- Second event');
title('Simulation with events (1)')


subplot(3,1,3)
plot(mEvents.x.tempSum);
text(29, 0, '<- First event');
text(39, -300, '<- Second event');
yyaxis right
plot(mEvents.x.lightSum);
legend('mEvents.x.tempSum','mEvents.x.lightSum','Location','nw');
text(39, 0, '<- Second event');
title('Simulation with events (2)')
