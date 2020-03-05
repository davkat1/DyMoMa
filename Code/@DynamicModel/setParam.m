function setParam(dm, name, val)
%SETPARAM Change a value of a parameter in a DynamicModel object
% If a DynamicElement of 'dm.p.<name>' exists, its value will change to
% the given val. Otherwise an error will be thrown.
% Inputs:
%   dm - A DynamicModel object
%   def - The name of the parameter to be change
%   val - The new value that the parameter recieves

% David Katzin, Wageningen University
% david.katzin@wur.nl

    if ~isfield(dm.p,name)
        error('The given model has no parameter named %s.', name);
    end
    
    if ~isnumeric(val)
        error('The given value must be numeric.');
    end

    dm.p.(name).val = val;
end

