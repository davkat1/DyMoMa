function solveEuler(obj, stepSize)
%solveEuler Simulate a DynamicModel using the Euler method with a given step size
% Usage: 
%   solveEuler(obj, stepSize)
%   obj.solveEuler(stepSize)
%
% Inputs:
%	stepSize - the step size in the solver iteration
%
% See also https://en.wikipedia.org/wiki/Euler_method
%
% The model to simulate is defined by the properties of the DynamicModel object:
%   obj.x.<>.def        ODEs for the states (function handles)
%   obj.x.<>.val        Initial values for the states (scalars)
%   obj.d.<>.val        Values for inputs (two column matrix)
%       obj.d.<>.val(:,1)   time
%       obj.d.<>.val(:,2)   values
%   obj.u.<>.val        Values for the controls 
%                           (if the controls are predefined, 
%                           has the same format as obj.d).
%                           The controls may also have empty vals, then
%                           they are treated like auxiliary states
%   obj.a.<>.def        Auxiliary states used for defining the ODEs
%
% After simulating the solution is stored in:
%   obj.x.<>.val (states)
%   obj.a.<>.val (auxiliary states)
%   obj.u.<>.val (controls)

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com

	tStart = obj.t.val(1);
	tEnd = obj.t.val(2);
    
    [stateNames, auxNames, ctrlNames, paramNames, inputNames] = getFieldNames(obj);
    
	timePhase = tStart:stepSize:(tEnd-stepSize);
    
    if defIsLabel(obj.u.(ctrlNames{1})) 
        % the def for the first control is the control name
        % in this case the controls are treated like inputs
        ruleBased = false;
    else
        % there is some rule defining the control
        % in this case the controls are treated like aux states
        ruleBased = true;
    end
    
    [xTraj, aTraj, uTraj] = createBlankTrajectories(obj, length(timePhase));
    
    %% load inital values
    [x0, u0, a0, p, d0, ~]  = getInitialValues(obj,timePhase, xTraj, aTraj, uTraj);
    
    % place initial values in trajectories
    xTraj = insertValue(xTraj,x0,1);
    aTraj = insertValue(aTraj,a0,1);   
    uTraj = insertValue(uTraj,u0,1);
    
    pb = CmdLineProgressBar('Progress: ', datetime('now')); % progress bar
    
    %% Calculate trajectories
    for n = 2:length(timePhase)
        
        pb.print(100*n/length(timePhase),100);
        
        t0 = timePhase(n);      
        
        % get d1 = d(t)
        for k=1:length(inputNames)
            if t0 < obj.d.(inputNames{k}).val(1,1)
                d1.(inputNames{k}) = obj.d.(inputNames{k}).val(1,2);
            elseif t0 > obj.d.(inputNames{k}).val(end,1)
                d1.(inputNames{k}) = obj.d.(inputNames{k}).val(end,2);
            else
                d1.(inputNames{k}) = interp1(obj.d.(inputNames{k}).val(:,1),...
                        obj.d.(inputNames{k}).val(:,2),t0); 
            end
        end
       
        % get u1 = u(t)
        if ruleBased % get from rules
            u1 = getControls(obj, x0, a0, u0, d0, p);
        else % get from trajectory
            for k=1:length(ctrlNames)
                u1.(ctrlNames{k}) = interp1(obj.u.(ctrlNames{k}).val(:,1),...
                        obj.u.(ctrlNames{k}).val(:,2),t0); 
            end
        end
        %% Calculate x1 = x(t), a1 = a(t)
        [x1, a1]  = getNextStep(obj, stepSize, x0, a0, u0, u1, d0, d1, p, t0, timePhase, xTraj, aTraj, uTraj, n);
        
        % store new values
        xTraj = insertValue(xTraj,x1,n);
        aTraj = insertValue(aTraj,a1,n);
        uTraj = insertValue(uTraj,u1,n);
        
        % prepare next round
        x0 = x1;
        u0 = u1;
        a0 = a1;
        d0 = d1;
    end

    if ~ruleBased
        uTraj = []; % can throw this away
    end
    copyValues(obj, xTraj, aTraj, uTraj, timePhase); % if isempty(u), u will not be copied
    
end


function copyValues(obj, x, a, u, timePhase)
    % Copy the calculated trajectories x,a,u to their appropriate place in obj
    [stateNames, auxNames, ctrlNames, ~, ~] = getFieldNames(obj);
    
     for n=1:length(stateNames)
        obj.x.(stateNames{n}).val = [];
        obj.x.(stateNames{n}).val(:,1) = timePhase;
        obj.x.(stateNames{n}).val(:,2) = x.(stateNames{n});
    end
    
    for n=1:length(auxNames)
        obj.a.(auxNames{n}).val = [];
        obj.a.(auxNames{n}).val(:,1) = timePhase;
        obj.a.(auxNames{n}).val(:,2) = a.(auxNames{n});
    end
    
    if ~isempty(u)
        for n=1:length(ctrlNames)
            obj.u.(ctrlNames{n}).val = [];
            obj.u.(ctrlNames{n}).val(:,1) = timePhase;
           obj.u.(ctrlNames{n}).val(:,2) = u.(ctrlNames{n});
        end
    end
end

function [x, a, u] = createBlankTrajectories(obj, trajSize)
% Create long vectors representing the trajectories for x, a, u. At this
% point they will be full of NaN
    [stateNames, auxNames, ctrlNames, ~, ~] = getFieldNames(obj);
    
    for n=1:length(stateNames)
        x.(stateNames{n}) = NaN(trajSize,1);
    end

    for n=1:length(auxNames)
        a.(auxNames{n}) = NaN(trajSize,1);
    end
    
    for n=1:length(ctrlNames)
        u.(ctrlNames{n}) = NaN(trajSize,1);
    end
end

function z = insertValue(z,z0,n)
    % z - a struct with fields as vectors, all at the same length
    % z0 - a struct with the same fields, but all scalar values
    % for every field in z, the following will happen:
    %   z.<field>(n) = z0.field

    names = fieldnames(z0);
    
    for k=1:length(names)
        z.(names{k})(n) = z0.(names{k});
    end
end

function [x, u, a, p, d, t]  = getInitialValues(obj,timePhase, xTraj, aTraj, uTraj)
    % Get the initial values for all elements in the model

    % by default return empty variables
    x = [];
    u = [];
    a = [];
    p = [];
    d = [];

    t = obj.t.val(1); % initial time value
    
	%% Get names of states from obj
    [stateNames, auxNames, ctrlNames, ...
    paramNames, inputNames] = getFieldNames(obj);
        
    for n=1:length(paramNames)
        if defIsLabel(obj.p.(paramNames{n})) % Parameter has no definition
			p.(paramNames{n}) = obj.p.(paramNames{n}).val;
		else % Parameter is based on other parameters
			p.(paramNames{n}) = obj.p.(paramNames{n}).def([],[],[],[],p);
            obj.p.(paramNames{n}).val = p.(paramNames{n}); 
                % also update the value in the model object
        end
    end

    for n=1:length(stateNames)
        if isscalar(obj.x.(stateNames{n}).val) % only initial value defined
            x.(stateNames{n}) = obj.x.(stateNames{n}).val; 
        else % trajectory of state defined
            x.(stateNames{n}) = obj.x.(stateNames{n}).val(1,2); 
        end
        xTraj.(stateNames{n})(1) = x.(stateNames{n});
    end

    for n=1:length(inputNames)
        d.(inputNames{n}) = obj.d.(inputNames{n}).val(1,2); % inital input value
    end
    
    for n=1:length(ctrlNames)
        if isscalar(obj.u.(ctrlNames{n}).val) % only initial value defined
            u.(ctrlNames{n}) = obj.u.(ctrlNames{n}).val; 
        elseif isempty(obj.u.(ctrlNames{n}).val)
            try
                u.(ctrlNames{n}) = obj.u.(ctrlNames{n}).def(x,a,u,d,p);
            catch err
                msg = sprintf('%s \n\nFailed to evaluate the definition of DynamicElement u.%s (n=%d): \n\t''%s''',...
                    err.message, ctrlNames{n}, n, obj.u.(ctrlNames{n}).label);
                id = 'MATLAB:DynamicModel:evalDef';
                error(id,msg);
            end
        else % trajectory of control defined
            u.(ctrlNames{n}) = obj.u.(ctrlNames{n}).val(1,2); 
                % get first value
        end
        uTraj.(ctrlNames{n})(1) = u.(ctrlNames{n});
    end
    
    for n=1:length(auxNames)
        try
            a.(auxNames{n}) = obj.a.(auxNames{n}).def(x,a,u,d,p);
        catch err
            msg = sprintf('%s \n\nFailed to evaluate the definition of DynamicElement a.%s (n=%d): \n\t''%s''',...
                err.message, auxNames{n}, n, obj.a.(auxNames{n}).label);
            id = 'MATLAB:DynamicModel:evalDef';
            error(id,msg);
        end
        aTraj.(auxNames{n})(1) = a.(auxNames{n});
    end
    
end

function u1 = getControls(obj, x, a, u0, d, p)
    % calculate u1 as a function of x0, d0, a0, u0
    % u1 = f(x0,d0,a0,u0)
    
    [~, ~, ctrlNames, ~, ~] = getFieldNames(obj);
    
    % calculate next step for controls 
    u = u0;
    for n=1:length(ctrlNames)
        try           
            u1.(ctrlNames{n}) = obj.u.(ctrlNames{n}).def(x,a,u,d,p);
        catch err
            msg = sprintf('%s \n\nFailed to evaluate the definition of DynamicElement u.%s (n=%d): \n\t''%s''',...
                err.message, ctrlNames{n}, n, obj.u.(ctrlNames{n}).label);
            id = 'MATLAB:DynamicModel:evalDef';
            error(id,msg);
        end
    end
end

function [x1, a1]  = getNextStep(obj, stepSize, x0, a0, u0, u1, d0, d1, p, t0, timePhase, xTraj, aTraj, uTraj, trajInd)
    % calculate values of x1, a1, based on values of x0, a0, u0, u1, d0, d1
    % and odes given in obj.x.<>.def
    %
    % x1 = x0+stepSize*f(x0,d0,u0,a0)
    % a1 = f(x1,d1,u1)
    
    [stateNames, auxNames, ~, ~, ~] = getFieldNames(obj);
    
    % values to use in calculation of x1
    x = x0;
    u = u0;
    d = d0;
    a = a0;
    t = t0;
    
    for n=1:length(stateNames)
        try
            x1.(stateNames{n}) = x0.(stateNames{n}) + stepSize*obj.x.(stateNames{n}).def(x,a,u,d,p);
        catch err
            msg = sprintf('%s \n\nFailed to evaluate the definition of DynamicElement x.%s (n=%d): \n\t''%s''',...
                err.message, stateNames{n}, n, obj.x.(stateNames{n}).label);
            id = 'MATLAB:DynamicModel:evalDef';
            error(id,msg);
        end
        xTraj.(stateNames{n})(trajInd) = x1.(stateNames{n});
		
		if ~isreal(x1.(stateNames{n}))
            warning('x.%s is complex',stateNames{n});
        elseif isnan(x1.(stateNames{n}))
            warning('x.%s is NaN',stateNames{n});
        end
    end
    
    % calculate next step for aux 
    x = x1;
    d = d1;
    u = u1;
    for n=1:length(auxNames)
        try
            a1.(auxNames{n}) = obj.a.(auxNames{n}).def(x,a,u,d,p);
            
            % update a according to the newly calculated value
            % note: this creates the case that, as much as possible, 
            % a1 = f(x1,d1,u1,a1)
            % however this means that the simulation results may depend on
            % the order in which the auxiliary states are defined. Consider
            % if this is what you want
            a.(auxNames{n}) = a1.(auxNames{n}); 
        catch err
            msg = sprintf('%s \n\nFailed to evaluate the definition of DynamicElement a.%s (n=%d): \n\t''%s''',...
                err.message, auxNames{n}, n, obj.a.(auxNames{n}).label);
            id = 'MATLAB:DynamicModel:evalDef';
            error(id,msg);
        end
        aTraj.(auxNames{n})(trajInd) = a1.(auxNames{n});
        
		if ~isreal(a1.(auxNames{n}))
            warning('a.%s is complex',auxNames{n});
        elseif isnan(a1.(auxNames{n}))
            warning('a.%s is NaN',auxNames{n});
        end
    end
end