function setOde(dm, name, arg3)
%SETODE Set the ODE of a state in a DynamicModel object
% Sets dm.x.<name>.def according to arg3:
%   If arg3 is a string or a function handle:
%       dm.a.<name>.def will be arg3
%   If arg3 is a DynamicElement:
%       dm.a.<name>.def will be arg3.label
% Inputs:
%   dm - A DynamicModel object
%   def - The name of the parameter to be change
%   arg3 - A DynamicElement, string, or a function handle, see above

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com

    if ~isfield(dm.x,name)
        error('The given model has no state named %s.', name);
    end
    
    if ~exist('arg3','var') || ...
            ( ~isa(arg3, 'string') && ~isa(arg3, 'char') ...
            && ~isa(arg3, 'function_handle') && ~isa(arg3, 'DynamicElement'))
        error('Third argument must be a string, function handle, or DynamicElement');
    end
    
    if isa(arg3, 'DynamicElement')
        def = arg3.label;
    elseif isa(arg3, 'function_handle')
        def = arg3;
    elseif isa(arg3, 'char') || isa(arg3,'string')
        def = str2func(['@(x,a,u,d,p)' arg3]);
    end
    
    setDef(dm.x.(name), def);
end

