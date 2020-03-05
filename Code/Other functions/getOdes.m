function dxdt = getOdes(t, x, a, u, d, p, xOde, stateNames)
%GETODES get ODEs for the DynamicModel in a format suitable for MATLAB's ODE solvers 
% 
% Inputs: 
%   t           Point in time where the model is evaluated
%   x           States. Column vector, with each row representing a state.
%               The size (height) of x comes from getFieldNames(dm).
%               In order to allow 'Vectorized' solving,
%               x may also be a matrix, where each row represents a state
%               and each column represents a possible set of values for the
%               states.
%   a           Auxiliary states. A struct with function handles, each
%               representing an aux state.
%   u           Controls. A struct with a field for each control, if the control
%               is predefined, it is represented by a two-column matrix, if it
%               needs to be calculated, it is represented by a function
%               handle.
%   d           Inputs. A struct with a field for each input, represented by a
%               two-column matrix.
%   p           Parameters. A struct with a field for each parameters, 
%               represented by a scalar value.
%   xOde        The ODEs for the states. A struct with function handles, each
%               representing an ODE
%   stateNames  Names of the states. A cell array, helping relate the
%               matrix x to the fields in xOde

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com

    aFunc = a; % The functional definitions of a

    % convert the column x to a struct
    for k=size(x,2):-1:1 % start with the last to preallocate memory
        for n=1:length(stateNames)
            xStruct(k).(stateNames{n}) = x(n,k);
        end
    end

    % get inputs d at time t
    inputNames = fields(d);
    for n=1:length(inputNames)
        if t < d.(inputNames{n})(1,1)
            d.(inputNames{n}) = d.(inputNames{n})(1,2);
        elseif t > d.(inputNames{n})(end,1)
            d.(inputNames{n}) = d.(inputNames{n})(end,2);
        else
            d.(inputNames{n}) = interp1(d.(inputNames{n})(:,1),...
                d.(inputNames{n})(:,2),t); 
        end                
    end

    % get controls u 
    ctrlNames = fields(u);
    for k=length(xStruct):-1:1
        x = xStruct(k);
        for n=1:length(ctrlNames)
            if isnumeric(u.(ctrlNames{n}))
                % control acts as input
                if isscalar(u.(ctrlNames{n}))
                    % this control is constant
                    uMat(k).(ctrlNames{n}) = u.(ctrlNames{n});
                else
                    if t < u.(ctrlNames{n})(1,1)
                        uMat(k).(ctrlNames{n}) = u.(ctrlNames{n})(1,2);
                    elseif t > u.(ctrlNames{n})(end,1)
                        uMat(k).(ctrlNames{n}) = u.(ctrlNames{n})(end,2);
                    else
                        uMat(k).(ctrlNames{n}) = interp1(u.(ctrlNames{n})(:,1),...
                            u.(ctrlNames{n})(:,2),t); 
                    end
                end
            else % control is rule based, acts as an auxiliary state
                % need to calculate for each column of x separately
                try
                    if ~exist('a','var')
                        a = [];
                    end
                    if ~exist('u','var')
                        u = [];
                    end
                    uMat(k).(ctrlNames{n}) = u.(ctrlNames{n})(x,a,u,d,p);
                    % uMat is like u but in matrix form
                catch err
                    msg = sprintf('%s \n\nFailed to evaluate the definition of DynamicElement u.%s (n=%d): \n\t''%s''',...
                        err.message, ctrlNames{n}, n, func2str(u.(ctrlNames{n}.def)));
                    id = 'MATLAB:DynamicModel:evalDef';
                    error(id,msg);
                end
            end
        end
    end
    
    % get auxiliary states a
    auxNames = fields(a);
    for k=length(xStruct):-1:1
        x = xStruct(k);
        u = uMat(k); % u is now all scalar values
        for n=1:length(auxNames)
            try
                if ~exist('a','var')
                    a = [];
                end
                aMat(k).(auxNames{n}) = aFunc.(auxNames{n})(x,a,u,d,p);
                a = aMat(k);
            catch err
                msg = sprintf('%s \n\nFailed to evaluate the definition of DynamicElement a.%s (n=%d): \n\t''%s''',...
                    err.message, auxNames{n}, n, func2str(a.(auxNames{n})));
                id = 'MATLAB:DynamicModel:evalDef';
                error(id,msg);
            end
        end
    end
    
    % get the derivative of x
    dxdt = nan(length(stateNames),length(xStruct));
    for k=1:length(xStruct)
        x = xStruct(k);
        u = uMat(k);
        a = aMat(k);
        for n=1:length(stateNames)
            try
                dxdt(n,k) = xOde.(stateNames{n})(x,a,u,d,p);
            catch err
                msg = sprintf('%s \n\nFailed to evaluate the definition of %s (n=%d): \n\t''%s''',...
                    err.message, stateNames{n}, n, func2str(xOde.(stateNames{n})));
                id = 'MATLAB:DynamicModel:evalDef';
                error(id,msg);
            end
        end
    end 
    
end