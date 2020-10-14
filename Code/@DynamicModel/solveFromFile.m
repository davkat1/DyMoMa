function solveFromFile(obj, solver, options, path, label)
% SOLVEFROMFILE Convert a DynamicModel to a MATLAB function file and solve
% The entire model is converted into one single MATLAB function using
% makeFuncFile. The model is then run with the generated file, and the
% generated file is deleted. This is an extremely cumbersome way of using the
% DynamicModel framework, but is sometimes a lot faster than all other methods
% 
% Inputs:
%   obj    - A DynamicModel object with a defined model
%   solver - the name of the ODE solver you want to use (string)
%       e.g. 'ode45', 'ode15s', etc. 
%       See https://nl.mathworks.com/help/matlab/math/choose-an-ode-solver.html
%       for more information
%   options - a struct with options sent to the ODE solver. 
%       See https://nl.mathworks.com/help/matlab/ref/odeset.html
%       for more information
%   path - a chosen directory where the temporary file will be stored. 
%       This directory must be on MATLAB's search path. If empty, 
%       the current working directory will be used. 
%   label - a chosen label that will appear in the temporary file's name.
% Result
%   The given DynamicModel obj will contain the solved trajectories

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com

    if ~exist('options', 'var')
        options = [];
    end
    
    if ~exist('path', 'var')
        path = [];
    end
    
    if ~exist('label', 'var')
        label = [];
    end
    
    if ~isempty(path) && path(end) ~= '\'
        path = [path '\'];
    end

    %% Generate random name for the file and function
    % Prevents problems if for instance, several instances of MATLAB are
    % used at the same time to generate files
    s = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

    % Randomize length of random string to generate, between 10 and 30
    rng shuffle;
    sLength = 10+ceil(20*rand());

    %% Generate random string
    rng shuffle;
    randString = s( ceil(rand(1,sLength)*length(s)) );
    
    funcName = ['tempFileDynamicModel_' label randString];
    if length(funcName) > 63
        funcName = funcName(1:63);
    end
    
    % Remove dots from file name
    funcName = strrep(funcName,'.','');
    
    path = [path funcName '.m'];     
    
    %% Create temporary file
    makeFuncFile(obj, path, funcName);
    
    %% Solve using temporary file - in case of error file will not be deleted
    eval([funcName '(obj, solver, options);']);

    %% Alternatively comment out previous section and uncomment this section if you want file deleted in case of error
%     try
%         eval([funcName '(obj, solver, options);']);
%     catch err % running the temporary threw an error 
%         delete(path); % still want to delete that file
%         error('MATLAB:DynamicModel:solveFromFile',...
%             ['Error encountered while running solveFromFile. Try running solveOde instead\n' err.message]);
%     end

    %% Delete temporary file
    delete(path);
    
end
