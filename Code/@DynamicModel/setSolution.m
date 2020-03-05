function setSolution(obj, t, x)
% Once a model has been solved using an ODE solver, set the model's components with the solution
% t and x here are the returned values of the ODE solver
    
    [stateNames, auxNames, ctrlNames, ...
        paramNames, inputNames] = getFieldNames(obj);

    
    % parameters 
    for n=1:length(paramNames)
        p.(paramNames{n}) = obj.p.(paramNames{n}).val;
    end
    
    % Set the results in the corresponding states
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
                    err.message, ctrlNames{n}, n, getDefStr(obj.u.(ctrlNames{n})));
                id = 'MATLAB:DynamicModel:eval';
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
            id = 'MATLAB:DynamicModel:eval';
            error(id,msg);
        end
    end