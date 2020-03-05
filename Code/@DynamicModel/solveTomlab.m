function result = solveTomlab(obj, nColl, options)
%SOLVETOMLAB Solve an optimal control problem based on the properties of a DynamicModel object
% Usage: 
%   solveTomlab(obj, nColl, options)
%   obj.solveTomlab(nColl, options)
%
% Inputs:
%   nColl - number of collocation points, can be an array for iterative solving
%   options - a struct to send to ezsolve. See help ezsolve
%
% The solution is stored in the following ControlProblem properties:
%   obj.x.<>.val (states)
%   obj.a.<>.val (auxiliary states)
%   obj.u.<>.val (controls)
%
% Output:
%   result - the result variable returned from ezsolve. See help ezsolve

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com

    
    if ~exist('options', 'var')
        options = [];
    end

    %% solve the problem
    for n = nColl
        fprintf([datestr(datetime('now')) '\n']);
        fprintf('%d / %d: %d collocation points \n', ...
            find(n==nColl),length(nColl),n);

        
        % Create tomSym timephase based on obj.t
        tTom = tom('tTom'); % tomlab time variable
        setPhase(tomPhase('pTom',tTom,obj.t.val(1),obj.t.val(end),n,[],'gauss'));

        
        % Convert problem to Tomlab
        [x, u, a, init, odes, cons]  = convertToTomlab(obj, tTom);
            % x, u, a are TomSym objects, reflecting
            % obj.x, obj.u, obj.a that are DynamicElements

        % Convert objective to Tomlab
        objective = eval(convertObjectiveToTomlab(obj, x, u, a));
            
        % initial guess based on values already in obj
        guess = getGuess(obj, x, u, tTom);


        % solve problem
        [solution, result] = ezsolve(objective,{odes,cons,init},guess,options);
        % collect solution into vals of each element
        storeSolution(obj, x, u, a, tTom, solution);
    end
end

function [x, u, a, init, odes, cons]  = convertToTomlab(obj, tTom)

    % time variable (currently a dummy, variable, not implemented for tomlab)
    t = tTom;

    %% Get names of variables from obj
    [stateNames, auxNames, ctrlNames, paramNames, inputNames] = getFieldNames(obj);
    conNames = fieldnames(obj.c);

    %% Define parameters as numeric variables
    for n=1:length(paramNames)
        if defIsLabel(obj.p.(paramNames{n})) % Parameter has no definition
			p.(paramNames{n}) = obj.p.(paramNames{n}).val;
        else % Parameter is based on other parameters
			p.(paramNames{n}) = obj.p.(paramNames{n}).def([],[],[],[],p);
            obj.p.(paramNames{n}).val = p.(paramNames{n}); 
                % also update the value in the model object
        end
    end   
    
    %% Create tomStates 
    xTom = [];
    for n=1:length(stateNames)
        x.(stateNames{n}) = tomState(stateNames{n});
        xTom = [xTom x.(stateNames{n})];
    end
    
    % set initial values
    for n=1:length(stateNames)
        val = obj.x.(stateNames{n}).val;
        if isempty(val) || isequal(size(val),[1,1])
            initStates(n) = val;
        else
            initStates(n) = val(1,2);
        end
    end
    
    %% Create tomControls with labels as in ctrlNames
    uTom = [];
    for n=1:length(ctrlNames)
        u.(ctrlNames{n}) = tomControl(ctrlNames{n});
        uTom = [uTom u.(ctrlNames{n})];
    end
    
    %% Create tomSym objects for inputs
    for n=1:length(inputNames)
       d.(inputNames{n}) = pchip(obj.d.(inputNames{n}).val(:,1),obj.d.(inputNames{n}).val(:,2), tTom);
    end

    %% Create tomSym objects for auxiliary states
    a = [];
    for n=1:length(auxNames) 
        a.(auxNames{n}) = obj.a.(auxNames{n}).def(x,a,u,d,p);
    end


    %% Define ODEs for tomlab
    
    odeString = 'collocate({';
    for n=1:length(stateNames)
        odeStruct.(stateNames{n}) = obj.x.(stateNames{n}).def(x,a,u,d,p);
        odeString = [odeString ...
            ' dot(x.' stateNames{n} ') == odeStruct.' stateNames{n} ';'];
    end

    odes=[];
    eval(['odes = ' odeString '});']);
    
    %% Define initial values
    init = initial(xTom) == initStates;
    
    %% Define constraints for tomlab
    conString = '{';
    for n=1:length(conNames)
        conStruct.(conNames{n}) = eval(obj.c.(conNames{n}));
        conString = [conString ...
            ' conStruct.' conNames{n} ';'];
    end
    cons=[];
    eval(['cons = ' conString '};']);
end

function objective = convertObjectiveToTomlab(obj, x, u, a)

    objective = obj.g;

%% Replace the string "p.paramName" to "obj.p.paramName.val"
    paramNames = fieldnames(obj.p);
    for n=1:length(paramNames)
       objective = strrep(objective, ['p.' paramNames{n}], ...
           ['obj.p.' paramNames{n} '.val']);
    end    
end

function guess = getGuess(obj, x, u, tTom)
    % Use the trajectories in obj.x.<>.val and obj.u.<>.val
    % as an initial guess for the next run
    
    stateNames = fieldnames(obj.x);
    ctrlNames = fieldnames(obj.u);
    stateNum = length(stateNames);
    ctrlNum = length(ctrlNames);
    
    guess = cell(1,stateNum+ctrlNum);
    
    for n=1:stateNum
        if isscalar(obj.x.(stateNames{n}).val) % only initial value - not yet solved
            guess{n} = icollocate(x.(stateNames{n}) == obj.x.(stateNames{n}).val);
        else
        guess{n} = icollocate(x.(stateNames{n}) == ...
            interp1(obj.x.(stateNames{n}).val(:,1), obj.x.(stateNames{n}).val(:,2), tTom));
        end
    end
    for n=1:ctrlNum
        if isempty(obj.u.(ctrlNames{n}).val) % problem not yet solved
            guess{n+stateNum} = icollocate(u.(ctrlNames{n}) == 0);
        else
        guess{n+stateNum} = icollocate(u.(ctrlNames{n}) == ...
            interp1(obj.u.(ctrlNames{n}).val(:,1), obj.u.(ctrlNames{n}).val(:,2), tTom));
        end
    end
end

function storeSolution(obj, x, u, a, tTom, solution)
    
    stateNames = fieldnames(obj.x);
    ctrlNames = fieldnames(obj.u);
    auxNames = fieldnames(obj.a);

    time = subs(mcollocate(tTom),solution);
    for n=1:length(stateNames)
        obj.x.(stateNames{n}).val = ...
            [time subs(mcollocate(x.(stateNames{n})),solution)];
    end
    for n=1:length(ctrlNames)
        obj.u.(ctrlNames{n}).val = ...
            [time subs(mcollocate(u.(ctrlNames{n})),solution)];
    end
    for n=1:length(auxNames)
        obj.a.(auxNames{n}).val = ...
            [time subs(mcollocate(a.(auxNames{n})),solution)];
    end
end
