function addState(dm, name, arg3)
%ADDSTATE Add a state to a DynamicModel object
% A DynamicElement with a def and label of 'x.<name>' and val as given will be added to dm.x. 
% The variable name will be dm.x.<name>
% Inputs:
%   dm - A DynamicModel object
%   name - The name of the state to be added
%   arg3 - If a scalar number, the value of the state to be added
% 		   If a dynamic element, its val will be the new state's val, and its
%		   label will be the new state's def
%
% Example:
%   addstate(dm,'state1',0)
%   creates m.x.state1 as a DynamicElement with properties:
%     def: @(x,a,u,d,p)x.state1
%     val: 0
%     label: 'x.state1'

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
        def = ['x.' name];
    elseif isa(arg3, 'DynamicElement')
        val = arg3.val;
        def = arg3.label;
    else
        error('The third argument must be numeric or a DynamicElement');
    end
    
    dm.x.(name) = DynamicElement(['x.' name], val, def);
end

