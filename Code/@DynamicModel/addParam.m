function addParam(dm, name, arg3)
%ADDPARAM Add a parameter to a DynamicModel object
% A DynamicElement with a def and label of 'p.<name>' and val as given will be added to dm.p. 
% The variable name will be dm.p.<name>
% Inputs:
%   dm - A DynamicModel object
%   name - The name of the parameter to be added
%   arg3 - If a scalar number, the value of the parameter to be added
% 		   If a dynamic element, its val will be the new param's val, and its
%		   label will be the new parameter's def
%
% Example:
%   addParam(dm,'param1',0)
%   creates m.p.param1 as a DynamicElement with properties:
%     def: @(x,a,u,d,p)p.param1
%     val: 0
%     label: 'p.param1'

% David Katzin, Wageningen University
% david.katzin@wur.nl

    if ~exist('arg3','var')
        arg3 = [];
    end
    
    if ~isa(name,'char')
        error('label must be a character vector');
    end
	
    if isnumeric(arg3)
		val = arg3;
        def = ['p.' name];
    elseif isa(arg3, 'DynamicElement')
        val = arg3.val;
        def = arg3.label;
    else
        error('The third argument must be numeric or a DynamicElement');
    end
    
    dm.p.(name) = DynamicElement(['p.' name], val, def);
end

