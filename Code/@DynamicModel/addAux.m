function addAux(dm, name, arg3)
%ADDAUX Add an auxiliary state to a DynamicModel object
% A DynamicElement will be created as dm.a.<name>.
% The label of the new DynamicElement will be 'a.<name>'
% The def and val of the new DynamicElement is based on arg3:
%   If arg3 is a string:
%       dm.a.<name>.def will be arg3
%       sss.a.<name>.val will be []
%   If arg3 is a DynamicElement:
%       dm.a.<name>.def will be arg3.label
%       dm.a.<name>.val will be arg3.val

% David Katzin, Wageningen University
% david.katzin@wur.nl

    if ~exist('arg3','var')
        def = [];
        val = [];
    elseif isa(arg3, 'DynamicElement')
        def = arg3.label;
        val = arg3.val;
    else
        def = arg3;
        val = [];
    end 
        
    if ~isa(name,'char')
        error('name must be a character vector');
    end

    dm.a.(name) = DynamicElement(['a.' name], val, def);
end

