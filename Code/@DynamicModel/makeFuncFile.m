function makeFuncFile(obj, filename, funcName)
% MAKEFUNCFILE Convert a DynamicModel to a MATLAB function file for fast solving
% This function converts the entire model into one single MATLAB function
% file that can then be solved without making use of DynamicModel
% objects, DynamicElements, etc. An extremely cumbersome way of using the
% DynamicModel framework, but is sometimes a lot faster than all other methods
% 
% Inputs:
%   obj         A DynamicModel object with a defined model
%   filename    The filename where the function file will be saved,
%               including path if neccessary. Should have the suffix '.m'.
%   funcName    The name of the function, should typically be equivalent to
%               the filename, except for the path
%
% Result
%   Creates a MATLAB function file in filename, with a function named
%   funcName, defining the DynamicModel problem

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com

    [stateNames, auxNames, ctrlNames, ...
        paramNames, inputNames] = getFieldNames(obj);

    fid = fopen(filename, 'w');

    fprintf(fid, ['function ' funcName '(obj, solver, options)\n\n']);
    
    fprintf(fid, ['if ~exist(''options'',''var'')\n' ...
        '\t options = [];\n' ...
        'end\n\n']);
    
    fprintf(fid, ['[stateNames, auxNames, ctrlNames, ...\n'...
        '\t paramNames, inputNames] = getFieldNames(obj);\n']);

    %% Set time variable
    fprintf(fid, ['\n%% Set time variable\n' ...
    'time = obj.t.val;\n']);

    %% Convert inputs to matrix
    fprintf(fid, '\n%% Convert inputs to matrix\n');
    fprintf(fid, 'd = obj.d.(inputNames{1}).val(:,1);\n');
    fprintf(fid, 'for k=1:length(inputNames)\n');
    fprintf(fid, '\t d = [d obj.d.(inputNames{k}).val(:,2)];\n');
    fprintf(fid, 'end\n');
    
    %% Convert predefined controls to matrix
    fprintf(fid, '\n%% Convert predefined controls to matrix\n');
    fprintf(fid, 'u = [];\n');
    fprintf(fid, 'uTime = [];\n');
    fprintf(fid, 'for k=1:length(ctrlNames)\n');
    fprintf(fid, ['\t if isnumeric(obj.u.(ctrlNames{k}).val) && ~isscalar(obj.u.(ctrlNames{k}).val) && ~isempty(obj.u.(ctrlNames{k}).val)\n' ...
        '\t\t uTime = obj.u.(ctrlNames{k}).val(:,1);\n' ...
        '\t\t if sum(isnan(u(:))) == size(u,1)*size(u,2) \n' ...
               '\t\t\t u = nan(length(obj.u.(ctrlNames{k}).val(:,2)), length(u));\n' ...
         '\t\t end\n' ...
        '\t\t u = [u obj.u.(ctrlNames{k}).val(:,2)];\n' ...
        '\t else\n' ...
            '\t\t if isempty(u)\n'...
                '\t\t\t u = nan(1,1);\n' ...
            '\t\t else\n' ...
                '\t\t\t u = [u nan(length(u(:,1)),1)];\n' ...
            '\t\t end\n' ...
        '\t end\n']);
    fprintf(fid, 'end\n');
    fprintf(fid, ['if ~isempty(uTime)\n' ...
        '\t u = [uTime u];\n' ...
        'end\n']);

    % create array of parameters
    fprintf(fid, '\n%% Create array of parameters\n');
    for k=1:length(paramNames)
        if defIsLabel(obj.p.(paramNames{k})) % Parameter has no definition
			val = obj.p.(paramNames{k}).val;
		else % Parameter is based on other parameters
			val = obj.p.(paramNames{k}).def([],[],[],[],p);
            obj.p.(paramNames{k}).val = val; 
                % also update the value in the model object
        end
        p.(paramNames{k}) = val;
        fprintf(fid, ['p(' num2str(k) ') = ' ...
            num2str(val) ';\n']);
    end

    
    %% Run simulation
    fprintf(fid, '\n%% Run simulation\n');
    
    if isempty(obj.e) % no events defined
        fprintf(fid, '[t,x] = feval(solver, @(t,x) ode(x, t, d, u, p), time, getInitialStates(obj), options);\n');

        fprintf(fid, 'setSolution(obj, t, x);\n\n');

        fprintf(fid, 'end\n');
    else % include an event listener in the ODE solver
        fprintf(fid, 'options = odeset(options, ''Events'', @events);\n');
        fprintf(fid, 'tOut = [];\n');
        fprintf(fid, 'xOut = [];\n');
        fprintf(fid, 'tStart = time(1);\n');
        fprintf(fid, 'tFinal = time(2);\n');
        fprintf(fid, 'xInit =  getInitialStates(obj);\n');
        fprintf(fid, 'refine = odeget(options,''Refine'');\n');
        fprintf(fid, 'if isempty(refine)\n'); 
            fprintf(fid, '\trefine = 1;\n');
        fprintf(fid, 'end\n\n');
        
        % Default for MaxStep is 0.1*abs(tFinal-tStart)
        fprintf(fid, '%% Default for MaxStep is 0.1*abs(tFinal-tStart)\n');
        fprintf(fid, 'if isempty(odeget(options,''MaxStep'')) %% no MaxStep has been defined\n');
            fprintf(fid, '\t options = odeset(options, ''MaxStep'', 0.1*abs(tFinal-tStart));\n');
        fprintf(fid, 'end\n\n'); % function
        
        for k=1:length(obj.e)
            varString = '';
            valString = '';
            for n=1:length(obj.e(k).resetVars)
                label = obj.e(k).resetVars(n).label;
                label = label(3:end);
                varString = [varString ' ' num2str(find(strcmp(stateNames,label)))];
                valString = [valString ' ' num2str(obj.e(k).resetVals(n))];
            end
            fprintf(fid, ['eventVars{%d} = [' varString '];\n'], k);
            fprintf(fid, ['eventVals{%d} = [' valString '];\n'], k);
        end
            
        % Iteratively solve until event is reached. Then reset values
        % according to event definitions
        fprintf(fid, '\n\n%% Iteratively solve until event is reached. Then reset values\n');
        fprintf(fid, '%% according to event definitions\n');
        
        fprintf(fid, 'while tStart < tFinal\n');
            fprintf(fid, '\t [t,x,~,~,eventNum] = feval(solver, @(t,x) ode(x, t, d, u, p), [tStart tFinal], xInit, options);\n\n');

            % Accumulate output
            fprintf(fid, '\t %% Accumulate output\n');
            fprintf(fid, '\t nt = length(t);\n');
            fprintf(fid, '\t tOut = [tOut; t(2:nt)];\n');
            fprintf(fid, '\t xOut = [xOut; x(2:nt,:)];\n\n');
            fprintf(fid, '\t tStart = t(nt);\n');

            fprintf(fid, '\t if ~isempty(eventNum) %% simulation not finished\n');
                % Set the new initial conditions
                fprintf(fid, '\t\t %% Set the new initial conditions\n');
                fprintf(fid, '\t\t xInit = x(nt,:);\n');
                fprintf(fid, '\t\t xInit(eventVars{eventNum(1)}) = eventVals{eventNum(1)};\n\n');

                % Guess of a first timestep is length of the last valid timestep
                fprintf(fid, '\t\t %% Guess of a first timestep is length of the last valid timestep\n');
                fprintf(fid, '\t\t options = odeset(options, ''InitialStep'', t(nt)-t(nt-refine));\n');
            fprintf(fid, '\t end\n'); % if ~isempty(eventNum)
        fprintf(fid, 'end\n\n'); % while
        fprintf(fid, 'setSolution(obj, tOut, xOut);\n\n');

        fprintf(fid, 'end\n\n'); % function

        % Events for ODE solver
        fprintf(fid, '%% Events for ODE solver\n');
        fprintf(fid, 'function [value,isterminal,direction] = events(~,x)\n');
        
            valString = '';
            dirString = '';
                for k=1:length(obj.e)
                    label = obj.e(k).condition.label;
                    label = label(3:end);
                    valString = [valString ' x(' num2str(find(strcmp(stateNames,label))) ')'];
                    dirString = [dirString ' ' num2str(obj.e(k).direction)];
                end
            fprintf(fid, ['\t value = [' valString '];\n']);
            fprintf(fid, ['\t direction = [' dirString '];\n']);
            fprintf(fid, '\t isterminal = ones(1,%d);\n', length(obj.e));
        fprintf(fid, 'end\n'); % events
        
    end
    
    %% Function for the ODE solver
    fprintf(fid, '\n%% Function for the ODE solver\n');
    fprintf(fid, 'function dx = ode(x, t, d, u, p)\n\n');
    
    % sample inputs at time t
    fprintf(fid, ['\t %% sample inputs at time t\n' ...
    '\t if t < d(1,1)\n' ...
        '\t\t dSample = d(1,2:end);\n' ...
    '\t elseif t > d(end,1)\n' ...
        '\t\t dSample = d(end,2:end);\n' ...
    '\t else \n' ...
    '\t\t dSample = nan(size(d,2)-1,1);\n' ...
    '\t\t for k=1:(size(d,2)-1)\n' ...
        '\t\t\t dSample(k) = interp1(d(:,1),d(:,k+1),t);\n'...
    '\t\t end\n' ...
    '\t end\n' ...
    '\t d = dSample;\n']);

    % sample predefined controls at time t
    if ~isempty(ctrlNames)
        fprintf(fid, ['\n\t %% sample predefined controls at time t\n' ...
        '\t if t < u(1,1)\n' ...
            '\t\t uSample = u(1,2:end);\n' ...
        '\t elseif t > u(end,1)\n' ...
            '\t\t uSample = u(end,2:end);\n' ...
        '\t else \n' ...
        '\t\t uSample = nan(size(u,2)-1,1);\n' ...
        '\t\t for k=1:(size(u,2)-1)\n' ...
            '\t\t\t if ~isnan(u(1,k+1))\n' ...
                '\t\t\t\t uSample(k) = interp1(u(:,1),u(:,k+1),t);\n'...
            '\t\t\t end\n' ...
        '\t\t end\n' ...
        '\t end\n' ...
        '\t u = uSample;\n']);

        % calculate values of rule based controls
        fprintf(fid, '\n\t%% Calculate values of rule based controls\n');
        for k=1:length(ctrlNames)
            if ~(isnumeric(obj.u.(ctrlNames{k}).val) && ~isscalar(obj.u.(ctrlNames{k}).val) && ~isempty(obj.u.(ctrlNames{k}).val))
                defExpand(obj, obj.u.(ctrlNames{k}));
                ctrlDef = remStructs(obj, obj.u.(ctrlNames{k}).def);       
                fprintf(fid, ['\t u(' num2str(k) ') = ' ...
                    ctrlDef ';\n']);
            end
        end
    end

    % create struct of auxilary states
    fprintf(fid, '\n\t%% Create struct of auxiliary states\n');
    for k=1:length(auxNames)
        auxDef = remStructs(obj, obj.a.(auxNames{k}).def);       
        fprintf(fid, ['\t a.' auxNames{k} ' = ' ...
            auxDef ';\n']);
    end
    
    % create array of derivatives of states
    fprintf(fid, '\n\t%% Create array of derivatives \n');
    for k=1:length(stateNames)
        odeDef = remStructs(obj, obj.x.(stateNames{k}).def);       
        fprintf(fid, ['\t dx(' num2str(k) ') = ' ...
            odeDef ';\n']);
    end
    
    fprintf(fid, '\n\t dx = dx'';\n');
    
    fprintf(fid, 'end\n');
    
    fclose(fid);
end

function newStr = remStructs(obj, str)
% Replace parameter, input, and control names with their array value

    if isa(str, 'function_handle')
        str = func2str(str);
        str = str(13:end);
    end

    [stateNames, auxNames, ctrlNames, ...
        paramNames, inputNames] = getFieldNames(obj);

    newStr = str;
    % replace all parameter names with their array value
    for n=1:length(paramNames)
        paramLengths(n) = length(paramNames{n});
    end
    [~, paramByLength] = sort(paramLengths,'descend');
    for n=paramByLength
        newStr = strrep(newStr, ['p.' paramNames{n}], ['p(' num2str(n) ')']);
    end

    % replace all input names with their array value
    for n=1:length(inputNames)
        inputLengths(n) = length(inputNames{n});
    end
    [~, inputByLength] = sort(inputLengths,'descend');
    for n=inputByLength
        newStr = strrep(newStr, ['d.' inputNames{n}], ['d(' num2str(n) ')']);
    end

    % replace all predefined control names with their array value
    if ~isempty(ctrlNames)
        for n=1:length(ctrlNames)
            ctrlLengths(n) = length(ctrlNames{n});
        end
        [~, ctrlByLength] = sort(ctrlLengths,'descend');
        for n=ctrlByLength
            newStr = strrep(newStr, ['u.' ctrlNames{n}], ['u(' num2str(n) ')']);
        end
    end
    
    % replace all states names with their array value
    for n=1:length(stateNames)
        stateLengths(n) = length(stateNames{n});
    end
    [~, stateByLength] = sort(stateLengths,'descend');
    for n=stateByLength
        newStr = strrep(newStr, ['x.' stateNames{n}], ['x(' num2str(n) ')']);
    end
end