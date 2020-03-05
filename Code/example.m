% Example for creating and using a DynamicModel, based on 
% Van Straten et al, Optimal Control of Greenhouse Cultivation (2010), Chapter 2 [1]. 
% It is recommended to run this example section by section by using
% 'Run and Advance', and at each step to view what happened.

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com

%% Create a new DynamicModel object
m = DynamicModel();

%% Define the time span
% The label for the time is '01/01/2001 00:00:00'
% and the time span is 0 to 48 (hours)
setTime(m, '01/01/2001 00:00:00', [0 48]);


%% Define parameters
addParam(m, 'lue', 7.5e-8);
addParam(m, 'heatLoss', 1);
addParam(m, 'heatEff', 0.1);
addParam(m, 'gasPrice', 4.55e-4);
addParam(m, 'lettucePrice', 136.4);
addParam(m, 'heatMin', 0);
addParam(m, 'heatMax', 100);

%% Define inputs 
addInput(m, 'rad');
addInput(m, 'tempOut');

%% Define states and controls
addState(m, 'dryWeight');
addState(m, 'tempIn');
addControl(m, 'heating');

%% Define auxiliary states
% Photosynthesis [kg m^{-2} h^{-1}], equation 2.1 [1] 
addAux(m, 'phot', m.p.lue.*m.d.rad.*m.x.tempIn.*m.x.dryWeight); 

% Heat loss to the outside [degC h^{-1}], equation 2.2 [1] 
addAux(m, 'heatOut', m.p.heatLoss.*(m.d.tempOut - m.x.tempIn)); 

% Heat gain from the pipes [degC h^{-1}], equation 2.2 [1] 
addAux(m, 'heatIn', m.p.heatEff.*m.u.heating);

%% Set the ODESs
% Photosynthesis [kg m^{-2} h^{-1}], equation 2.1 [1] 
setOde(m, 'dryWeight', m.a.phot); 

% Heat gain in the greenhouse [degC h^{-1}], equation 2.2 [1] 
setOde(m, 'tempIn', m.a.heatOut + m.a.heatIn);

%% Set controls (as predefined inputs)
time = (0:48)';
setVal(m.u.heating, [time zeros(size(time))]);

%% Set the values of the inputs
setVal(m.d.rad, [time max(0, 800*sin(4*pi*time/48-0.65*pi))]);
setVal(m.d.tempOut, [time 15+10*sin(4*pi*time/48-0.65*pi)]);

%% Set initial values for the states
setVal(m.x.dryWeight, 1); % kg m^{-2} 
setVal(m.x.tempIn, 10); % degC

%% Make some plots
figure; plot(m.d.rad);
figure; plot(m.d.tempOut);
figure; plot(m.u.heating);
plot(m);

%% Print out information to the console
show(m, 'x');
show(m, 'a');
show(m, 'p');

%% Create several copies of m and simulate each in a different way

mEuler = DynamicModel(m);
solveEuler(mEuler,1);
% plot(mEuler);

% Uncomment to try other solvers:
% % ode45 using solveOde
% mOde45 = DynamicModel(m);
% solveOde(mOde45, 'ode45');
% plot(mOde45)
% 
% % ode15s using solveOde
% mOde15s = DynamicModel(m);
% solveOde(mOde15s, 'ode15s');
% plot(mOde15s)
% 
% % ode45 using solveFromFile
% mFromFile = DynamicModel(m);
% solveFromFile(mFromFile, 'ode45');
% plot(mFromFile)

%% Rule based control

% make a copy of m
ruleBased = DynamicModel(m);

% bang-bang cotrol
ruleBased.u.heating = ifElse('x.tempIn < 15', ruleBased.p.heatMax.val, ruleBased.p.heatMin.val); 
solveEuler(ruleBased,1);


figure;
subplot(2,1,1);
plot(mEuler.x.tempIn); grid; hold on;
plot(ruleBased.x.tempIn);
legend('tempIn no heating','tempIn bang bang heating');

subplot(2,1,2);
plot(ruleBased.u.heating); hold on
legend('bang bang heating');

mProfit = mEuler.p.lettucePrice.val*mEuler.x.dryWeight.val(end,2)-mEuler.p.gasPrice.val*trapz(mEuler.u.heating);
rbProfit = ruleBased.p.lettucePrice.val*ruleBased.x.dryWeight.val(end,2)-ruleBased.p.gasPrice.val*trapz(ruleBased.u.heating);
fprintf('\nProfit with no heating: %.3f\n',mProfit);
fprintf('Profit with bang bang control: %.3f\n',rbProfit);
%% higher resolution

% make a copy of ruleBased
hiRes = DynamicModel(ruleBased);

solveEuler(hiRes,0.1);
subplot(2,1,1); 
plot(hiRes.x.tempIn);
legend('tempIn no heating','tempIn bang bang heating','tempIn bang bang hi res');

subplot(2,1,2); 
plot(hiRes.u.heating);
legend('bang bang heating', 'bang bang heating hi res');

hrProfit = hiRes.p.lettucePrice.val*hiRes.x.dryWeight.val(end,2)-hiRes.p.gasPrice.val*trapz(hiRes.u.heating);
fprintf('\nProfit with no heating: %.3f\n',mProfit);
fprintf('Profit with bang bang control: %.3f\n',rbProfit);
fprintf('Profit with hi-res bang bang control: %.3f\n',hrProfit);

%% proportional control

propCont = DynamicModel(hiRes);

% return x.tempIn to original status (the label is the same as the def)
setOde(propCont, 'tempIn', 'x.tempIn'); 

propCont.u.heating = proportionalControl(propCont.x.tempIn, 17, -4, propCont.p.heatMin, propCont.p.heatMax);

setOde(propCont, 'tempIn', m.a.heatOut + m.a.heatIn); % redefine tempIn's ODE

solveEuler(propCont,0.1);

subplot(2,1,1); 
plot(propCont.x.tempIn);
legend('tempIn no heating','tempIn bang bang heating',...
    'tempIn bang bang hi res', 'tempIn proportional heating');
subplot(2,1,2); 
plot(propCont.u.heating);
legend('bang bang heating', 'bang bang heating hi res',...
    'proportional heating');

pcProfit = propCont.p.lettucePrice.val*propCont.x.dryWeight.val(end,2)-propCont.p.gasPrice.val*trapz(propCont.u.heating);
fprintf('\nProfit with no heating: %.3f\n',mProfit);
fprintf('Profit with bang bang control: %.3f\n',rbProfit);
fprintf('Profit with hi-res bang bang control: %.3f\n',hrProfit);
fprintf('Profit with proportional control: %.3f\n',pcProfit);

%% Optimal control using Tomlab

% define constraints, using Tomlab syntax
mTom = DynamicModel(m);

mTom.c.heating = 'p.heatMin <= icollocate(u.heating) <= p.heatMax';
    
% define goal, using Tomlab syntax
mTom.g = '-p.lettucePrice*final(x.dryWeight)+integrate(p.gasPrice*u.heating)';
    
% solve using Tomalb
solveTomlab(mTom, 600);

subplot(2,1,1); 
plot(mTom.x.tempIn);
legend('tempIn no heating','tempIn bang bang heating',...
    'tempIn bang bang hi res', 'tempIn proportional heating','tempIn Tomlab');

subplot(2,1,2); 
plot(mTom.u.heating);

legend('bang bang heating', 'bang bang heating hi res',...
    'proportional heating', 'tomLab heating');

tlProfit = mTom.p.lettucePrice.val*mTom.x.dryWeight.val(end,2)-mTom.p.gasPrice.val*trapz(mTom.u.heating);
fprintf('\nProfit with no heating: %.3f\n',mProfit);
fprintf('Profit with bang bang control: %.3f\n',rbProfit);
fprintf('Profit with hi-res bang bang control: %.3f\n',hrProfit);
fprintf('Profit with proportional control: %.3f\n',pcProfit);
fprintf('Profit with optimal control: %.3f\n',tlProfit);

%% Adjust plot
axis([0 50 0 100]);