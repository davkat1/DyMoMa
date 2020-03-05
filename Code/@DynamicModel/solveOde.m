function [t, x] = solveOde(obj, solver, options)
%solveEuler Simulate a DynamicModel using one of MATLAB's ODE solvers
% Usage: 
%   solveEuler(obj, solver, options)
%   obj.solveEuler(solver, options)
%
% Inputs:
%	obj - a DynamicModel with a model already defined
%   solver - the name of the ODE solver you want to use (string)
%       e.g. 'ode45', 'ode15s', etc. 
%       See https://nl.mathworks.com/help/matlab/math/choose-an-ode-solver.html
%       for more information
%   options - a struct with options sent to the ODE solver. 
%       See https://nl.mathworks.com/help/matlab/ref/odeset.html
%       for more information
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

    if ~exist('options','var')
        options = [];
    end

    %% collect arguments to send to getOdes
    [stateNames, auxNames, ctrlNames, ...
    paramNames, inputNames] = getFieldNames(obj);

    % auxStates
    for n=1:length(auxNames)
        a.(auxNames{n}) = obj.a.(auxNames{n}).def;
    end
    
    % controls   
    for n=1:length(ctrlNames)
        if defIsLabel(obj.u.(ctrlNames{n})) 
        % the def for the control is the control name
        % in this case the control is treated like an input
            u.(ctrlNames{n}) = obj.u.(ctrlNames{n}).val;
        else % control is rule based, acts as an auxiliary state
            defExpand(obj, obj.u.(ctrlNames{n}));
            u.(ctrlNames{n}) = obj.u.(ctrlNames{n}).def;
        end
    end

    % inputs
    for n=1:length(inputNames)
        d.(inputNames{n}) = obj.d.(inputNames{n}).val;
    end
    
    % parameters 
    for n=1:length(paramNames)
		if defIsLabel(obj.p.(paramNames{n})) % Parameter has no definition
			p.(paramNames{n}) = obj.p.(paramNames{n}).val;
		else % Parameter is based on other parameters
			p.(paramNames{n}) = obj.p.(paramNames{n}).def([],[],[],[],p);
            obj.p.(paramNames{n}).val = p.(paramNames{n}); 
                % also update the value in the model object
		end
    end
    
    % ODEs
    for n=1:length(stateNames)
        xOde.(stateNames{n}) = obj.x.(stateNames{n}).def;
    end
    
    %% Run the ODE solver
    [t,x] = feval(solver, @(t,x) getOdes(t, x, a, u, d, p, xOde, stateNames), obj.t.val,getInitialStates(obj), options);

    %% Set the results in the corresponding states
    for n=1:length(stateNames)
        obj.x.(stateNames{n}).val = [t x(:,n)];
        xStruct.(stateNames{n}) = x(:,n);
    end
    
    x = xStruct;
    
    % get inputs d
    % the inputs will be a vector of the inputs at given times,
    % corresponding to the output t of ode15s
    for n=1:length(inputNames)
            d.(inputNames{n}) = interp1(obj.d.(inputNames{n}).val(:,1),...
                obj.d.(inputNames{n}).val(:,2),t);    
    end
    
    % Set the resulting controls
    for n=1:length(ctrlNames)
        if isscalar(obj.u.(ctrlNames{n}).val) || isempty(obj.u.(ctrlNames{n}).val)
            % control was not predefined, need to calculate
            try
                % remove auxStates ('a.<...>') from definition and function handles of u.(ctrlNames{n})
                defExpand(obj,obj.u.(ctrlNames{n}));
                if ~exist('a','var')
                    a = [];
                end
                if ~exist('u','var')
                    u = [];
                end
                u.(ctrlNames{n}) =  obj.u.(ctrlNames{n}).def(x,a,u,d,p);
                if isscalar(u.(ctrlNames{n})) % the definition does not depend on t, it's constant
                    u.(ctrlNames{n}) = u.(ctrlNames{n})*ones(size(t));
                end
                obj.u.(ctrlNames{n}).val = [t u.(ctrlNames{n})];
            catch err
                msg = sprintf('%s \n\nFailed to evaluate the definition of DynamicElement u.%s (k=%d): \n\t''%s''',...
                    err.message, ctrlNames{n}, n, obj.u.(ctrlNames{n}).label);
                id = 'MATLAB:DynamicModel:evalDef';
                error(id,msg);
            end
        else % interpolate u in timepoints t
            u.(ctrlNames{n}) = interp1(obj.u.(ctrlNames{n}).val(:,1),...
                obj.u.(ctrlNames{n}).val(:,2),t); 
        end
    end
    
    % Set the resulting auxiliary states
    for n=1:length(auxNames)
        try
            if ~exist('a','var')
                    a = [];
            end
            if ~exist('u','var')
                u = [];
            end
            a.(auxNames{n}) = obj.a.(auxNames{n}).def(x,a,u,d,p);
            if isscalar(a.(auxNames{n})) % the definition does not depend on t, it's constant
                    a.(auxNames{n}) = a.(auxNames{n})*ones(size(t));
            end
            obj.a.(auxNames{n}).val = [t a.(auxNames{n})];
        catch err
            msg = sprintf('%s \n\nFailed to evaluate the definition of DynamicElement a.%s (n=%d): \n\t''%s''',...
                err.message, auxNames{n}, n, obj.a.(auxNames{n}).label);
            id = 'MATLAB:DynamicModel:evalDef';
            error(id,msg);
        end
    end
end

