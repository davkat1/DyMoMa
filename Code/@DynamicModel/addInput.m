function addInput(dm, name, arg3)
%ADDINPUT Add an input to a DynamicModel object
% A DynamicElement with a def and label of 'd.<name>' and val as given will be added to dm.d. 
% The variable name will be dm.d.<name>
% Inputs:
%   dm - A DynamicModel object
%   name - The name of the input to be added
%   arg3 - If a scalar number, the value of the input to be added
% 		   If a dynamic element, its val will be the new input's val, and its
%		   label will be the new input's def
%
% Example:
%   addInput(dm,'input1',0)
%   creates m.d.input1 as a DynamicElement with properties:
%     def: @(x,a,u,d,p)d.input1
%     val: 0
%     label: 'd.input1'

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
        def = ['d.' name];
    elseif isa(arg3, 'DynamicElement')
        val = arg3.val;
        def = arg3.label;
    else
        error('The third argument must be numeric or a DynamicElement');
    end
    
    dm.d.(name) = DynamicElement(['d.' name], val, def);
end

