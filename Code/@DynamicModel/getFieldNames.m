function [stateNames, auxNames, ctrlNames, paramNames, inputNames] = getFieldNames(obj)
% GETFIELDNAMES Get the field names of a DynamicModel object
% Usage: 
%   [stateNames, auxNames, ctrlNames, paramNames, inputNames] = getFieldNames(obj)
% Returns:
%   stateNames      cell array containing strings with the state names
%   auxNames        cell array containing strings with the aux state names
%   ctrlNames       cell array containing strings with the control names
%   paramNames      cell array containing strings with the parameter names
%   inputNames      cell array containing strings with the input names

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com
    
    if isempty(obj.x)
        stateNames = [];
    else
        stateNames = fieldnames(obj.x);
    end
    if isempty(obj.a)
        auxNames = [];
    else
        auxNames = fieldnames(obj.a);
    end    
    if isempty(obj.u)
        ctrlNames = [];
    else
        ctrlNames = fieldnames(obj.u);
    end
    if isempty(obj.p)
        paramNames = [];
    else
        paramNames = fieldnames(obj.p);
    end
    if isempty(obj.d)
        inputNames = [];
    else
        inputNames = fieldnames(obj.d);
    end
end

