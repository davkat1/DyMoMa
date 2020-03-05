classdef DynamicElement < matlab.mixin.Copyable 
% DYNAMICELEMENT An element that evolves dynamically over time
%
% Properties:
%   label       The name of the element (string), e.g., 'x.state1'
% 	def 		A definition of the element, for example an ODE (function handle)
% 	val 		The dynamic values of the array (double).
%               This can be in one of three forms:
%                   - Empty, for DynamicElement whose values have not yet
%                     been defined.
%                   - A single number (scalar), for parameters or as
%                     initial values of states, controls, etc.
%                   - A two-column matrix representing a trajectory, 
%                     where the first column represents time, and the 
%                     second column represents values throughout this time

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com
    
    properties 
        label
        def
        val
    end

    methods
        function obj = DynamicElement(varargin)
        % DYNAMICELEMENT constructor for DynamicElement
        % Usage:
        %   DynamicElement()
        %       Creates an empty DynamicElement
        %   DynamicElement(de)
        %       When de is a DynamicElement, creates a copy of the DynamicElement de
        %   DynamicElement(lab)
        %       When lab is a string, creates a Dynamic with label and def
        %       as the given argument
        %   DynamicElement(lab, val)
        %       If val is numeric or logical, sets label and def as the given lab, val as the given val
        %   DynamicElement(lab, def)
        %       If def is a string, char or function handle, sets def as the given def
        %   DynamicElement(lab, def, val), DynamicElement(lab, val, def) 
        %       Creates a DynamicElement with the given properties.
        
            if nargin >= 1 
                if isempty(varargin{1}) % DynamicElement([])
                    obj = DynamicElement();
                elseif isa(varargin{1}, 'DynamicElement') % DynamicElement(de)
                    if nargin > 1
                        error('Only one argument allowed in DynamicElement(de) when copying a DynamicElement');
                    end
                    deIn = varargin{1};
                    setLabel(obj, deIn.label);
                    setDef(obj, deIn.def);
                    setVal(obj, deIn.val);
                else % DynamicElement(lab)
                    setLabel(obj, varargin{1});
                    setDef(obj, varargin{1});
                end
            end
            if nargin >= 2 && ~isempty(varargin{2}) % DynamicElement(lab, val) or DynamicElement(lab, def)
                if isa(varargin{2}, 'string') || isa(varargin{2}, 'char') ...
                        || isa(varargin{2}, 'function_handle') % DynamicElement(lab, def)
                    setDef(obj,  varargin{2});
                elseif isnumeric(varargin{2}) || islogical(varargin{2}) % DynamicElement(lab, val)
                    setVal(obj, varargin{2});
                else
                    error('Second argument for DynamicElement constructor must be char, string, function handle, or numeric');
                end
            end
            if nargin >= 3 && ~isempty(varargin{3}) % DynamicElement(lab, val, def) or DynamicElement(lab, def, val)
                if isnumeric(varargin{2}) || islogical(varargin{2}) % DynamicElement(lab, val, def)
                    setDef(obj, varargin{3});
                else % DynamicElement(lab, def, val)
                    setVal(obj, varargin{3});
                end
            end
        end
        
        %% set methods 
        
        function setLabel(obj, label)
        % Receives a string or character as label and sets that as obj.label
            if isa(label, 'string')
                label = char(label);
            end
            if isa(label, 'char')
                obj.label = label;
            else
                error('Argument for DynamicElement label must be string or char');
            end
        end
        
        function setDef(obj, def)
        % Receives a string, character, or function handle as def, and sets
        % that as obj.def
            if isa(def, 'string')
                def = char(def);
            end
            if isa(def, 'char')
                try
                    obj.def = str2func(['@(x,a,u,d,p)' def]);
                catch
                    error('Could not define function %s', def);
                end
            elseif isa(def, 'function_handle') || isempty(def)
                obj.def = def;
            else
                error('Argument for DynamicElement definition must be string, char, empty, or function handle');
            end
        end
        
        function setVal(obj, val)
        % Recieves a numeric value as val and sets that as obj.val
            if islogical(val)
                val = 1*val;
            end
            if isnumeric(val)
                if isempty(val) || isscalar(val) || size(val,2) == 2
                    obj.val = val;
                else
                    error('Argument for DynamicElement value must be empty, a scalar, or a matrix with 2 columns');
                end
            else
                error('Argument for DynamicElement value must be numeric');
            end
        end
        
        %% Get methods
        function defStr = getDefStr(obj)
            if isempty(obj.def)
                defStr = [];
            else
                defStr = func2str(obj.def);
                defStr = defStr(13:end);
            end
        end
		
        %% Other methods 
        function plot(obj, varargin)
           s = size(obj.val);
           if s(2) == 2
              plot(obj.val(:,1),obj.val(:,2),varargin{:}); 
           else % nothing to plot
              plot(0);
           end
        end
        
        function scatter(obj)
           s = size(obj.val);
           if s(2) == 2
              scatter(obj.val(:,1),obj.val(:,2)); 
           end
        end
        
        function sum = trapz(obj)
        % integral of the values of obj
            sum = trapz(obj.val(:,1), obj.val(:,2));
        end
        
        function r = rmse(obj1, obj2)
        % RMSE between two objects
            if ~isequal(obj1.val(:,1), obj2.val(:,1))
                warning('Timelines of objects not equal');
                r = [];
            else
                r = sqrt(mean((obj1.val(:,2)-obj2.val(:,2)).^2));
            end
        end
        
        function r = rrmse(obj1, obj2)
        % relative RMSE between two objects [%] (relative to the first
        % object)
            if ~isequal(obj1.val(:,1), obj2.val(:,1))
                warning('Timelines of objects not equal');
                r = [];
            else
                r = 100*rmse(obj1,obj2)/mean(obj1);
            end
        end
        
        function avg = mean(obj)
            if isscalar(obj.val)
                avg = obj.val;
            else
                avg = mean(obj.val(:,2));
            end
        end
        
        function eq = defIsLabel(obj)
        % Returns true if def field is equivalent to label field
            if isempty(obj.def) && isempty(obj.label)
            % both fields are empty
                eq = true;
            elseif xor(isempty(obj.def), isempty(obj.label)) 
            % one field is empty but the other isn't
                eq = false;
            else
            % both fields are not empty
            definition = func2str(obj.def);
            eq = strcmp(definition(13:end),obj.label);
            end
        end
        
		%% Arithmetic operations
		% Methods for arithmetic operations between DynamicElements      
        function de = lt(obj1, obj2)
            de = binaryArithmetic(obj1, obj2, '<');
        end
        function de = gt(obj1, obj2)
            de = binaryArithmetic(obj1, obj2, '>');
        end
        function de = le(obj1, obj2)
            de = binaryArithmetic(obj1, obj2, '<=');
        end
        function de = ge(obj1, obj2)
            de = binaryArithmetic(obj1, obj2, '>=');
        end
        function de = ne(obj1, obj2)
            de = binaryArithmetic(obj1, obj2, '~=');
        end
        function de = eq(obj1, obj2)
            de = binaryArithmetic(obj1, obj2, '==');
        end
        function de = and(obj1, obj2)
            de = binaryArithmetic(obj1, obj2, '&');
        end
        function de = or(obj1, obj2)
            de = binaryArithmetic(obj1, obj2, '|');
        end
        function de = plus(obj1, obj2)
            de = binaryArithmetic(obj1, obj2, '+');
        end
        function de = minus(obj1, obj2)
            de = binaryArithmetic(obj1, obj2, '-');
        end
        function de = times(obj1, obj2)
            de = binaryArithmetic(obj1, obj2, '.*');
        end
		function de = mtimes(obj1, obj2)
            de = binaryArithmetic(obj1, obj2, '*');
        end
        function de = rdivide(obj1, obj2)
            de = binaryArithmetic(obj1, obj2, './');
        end
		function de = mrdivide(obj1, obj2)
            de = binaryArithmetic(obj1, obj2, '/');
        end
        function de = power(obj1, obj2)
            de = binaryArithmetic(obj1, obj2, '.^');
        end
		function de = mpower(obj1, obj2)
            de = binaryArithmetic(obj1, obj2, '^');
        end
        function de = max(obj1, obj2)
            de = binaryFunction(obj1, obj2, 'max');
        end
        function de = min(obj1, obj2)
            de = binaryFunction(obj1, obj2, 'min');
        end
        function de = not(obj)
			de = unaryFunction(obj,'~');
        end
		function de = abs(obj)
			de = unaryFunction(obj,'abs');
        end
        function de = exp(obj)
			de = unaryFunction(obj,'exp');
        end
        function de = sqrt(obj)
			de = unaryFunction(obj,'sqrt');
        end
        function de = floor(obj)
            de = unaryFunction(obj,'floor');
        end
		function de = ceil(obj)
            de = unaryFunction(obj,'ceil');
        end
        function de = sign(obj)
            de = unaryFunction(obj,'sign');
        end
        function de = uminus(obj)
			de = -1*obj;
        end
        function de = cos(obj)
            de = unaryFunction(obj,'cos');
        end
        function de = sin(obj)
            de = unaryFunction(obj,'sin');
        end
		function de = cosd(obj)
            de = unaryFunction(obj,'cosd');
        end
        function de = sind(obj)
            de = unaryFunction(obj,'sind');
        end
        function de = cumsum(obj)
            de = unaryFunction(obj,'cumsum');
        end
        function de = nthroot(obj, num)
            de = binaryFunction(obj, num, 'nthroot');
        end
        function de = smooth(obj, num)
            de = binaryFunction(obj, num, 'smooth');
        end
        function de = mod(obj, num)
            de = binaryFunction(obj, num, 'mod');
        end
        function de = log(obj)
            de = unaryFunction(obj, 'log');
        end
        
        % divide without brackets
		function de = divNoBracks(obj1, obj2)
			de = binaryArithmetic(obj1, obj2, './', false);
		end
		
		% multiply without brackets
		function de = mulNoBracks(obj1, obj2)
			de = binaryArithmetic(obj1, obj2, '.*', false);
		end

        
        function de = binaryArithmetic(obj1, obj2, operator, bracks)
		% Create a new dynamic element of the form <obj1> <operator> <obj2>
        % the definition will be (<def1>) <operator> (<def2>)
        % if bracks==false, the definition will be <def1> <operator> <def2>
        % (risky to do, but helps shorten new defs)
        % the label will be constructed similarly
        % at least one of the two objects must be a DynamicElement. One of
        % them may be a scalar number.
        %
        % the val will be a result of the binary operation:
        %   if both DynamicElements have a scalar val, a new scalar val
        %       will be calculated
        %   if both DynamicElements have a time trajectory val, with the same
        %       time values, a new trajectory will be (elementwise) calculated
        %   if one val is scalar and one val is a trajectory, a new
        %       trajectory will be calculated
        
			if ~exist('bracks', 'var')
				bracks = true; % default is use brackets
			end
			
			[def1, def2, val1, val2, lab1, lab2] = getProperties(obj1,obj2);
			
            % add brackets
            if isa(obj1, 'DynamicElement') && ~strcmp(operator, '+') && ~strcmp(operator, '-') && bracks
                def1 = ['(' def1 ')'];
                lab1 = ['(' lab1 ')'];
            end
            if isa(obj2, 'DynamicElement') && ~strcmp(operator, '+') && bracks
                def2 = ['(' def2 ')'];
                lab2 = ['(' lab2 ')'];
            end
            
            % set definition
            definition = [def1 operator def2];
            lab = [lab1 operator lab2];
			
            % set value
            size1 = size(val1);
            size2 = size(val2);
            
            if size1(1)==0 || size2(1)==0
            % empty values
            	value = [];
            elseif isequal(size1,[1 1]) && isequal(size2,[1 1])
            % scalar artihmetic    
            	eval(['value = val1' operator 'val2;']);
            elseif size1(2) == 2 && isequal(size2,[1 1])
            % 2-column matrix and scalar
                eval(['value = [val1(:,1) val1(:,2)' operator 'val2];']);
            elseif isequal(size1,[1 1]) && size2(2) == 2
            % scalar and 2-column matrix
                eval(['value = [val2(:,1) val1' operator 'val2(:,2)];']);
            elseif size1(2)==2 && size2(2) == 2
            % two 2-column matrices
                if ~isequal(val1(:,1),val2(:,1))
                    value = [];
                    warning('Timelines of values not equal, assigned empty value');
                else
                    eval(['value = [val1(:,1) val1(:,2)' operator 'val2(:,2)];']);
                end
            else
                value = [];
                warning('Could not perform arithmetic operation, assigned empty value');
            end
			
			de = DynamicElement(lab, value, definition);
        end
        
        function de = binaryFunction(obj1, obj2, func)
        % Create a new dynamic element of the form func(<obj1>, <obj2>)
        % Besides the format, works the same as binaryArithmetic
			
			% get definitions and values based on dataype of obj1, obj2
			[def1, def2, val1, val2, lab1, lab2] = getProperties(obj1,obj2);
            
            % set definition
            definition = [func '(' def1 ',' def2 ')'];
			lab = [func '(' lab1 ',' lab2 ')'];
            
            % set value
            size1 = size(val1);
            size2 = size(val2);
            
            if size1(1)==0 || size2(1)==0
            % empty values
            	value = [];
            elseif isequal(size1,[1 1]) && isequal(size2,[1 1])
            % scalar artihmetic    
                eval(['value = ' func '(val1,val2);']);
            elseif size1(2) == 2 && isequal(size2,[1 1])
            % 2-column matrix and scalar
                eval(['value = [val1(:,1) ' func '(val1(:,2),val2)];']);
            elseif isequal(size1,[1 1]) && size2(2) == 2
            % scalar and 2-column matrix
                eval(['value = [val2(:,1) ' func '(val1,val2(:,2))];']);
            elseif size1(2)==2 && size2(2) == 2
            % two 2-column matrices
                if ~isequal(val1(:,1),val2(:,1))
                    value = [];
                    warning('Timelines of values not equal, assigned empty value');
                else
                    eval(['value = [val1(:,1) ' func '(val1(:,2),val2(:,2))];']);
                end
            else
                value = [];
                warning('Could not perform binary function, assigned empty value');
            end
			
			de = DynamicElement(lab, value, definition);
        end
        
        function de = unaryFunction(obj, func)
        % Create a new dynamic element of the form func(<obj>)
        % Besides this, works the same as binaryFunction
        
            definition = func2str(obj.def);
            definition = [func '(' definition(13:end) ')'];
            lab = [func '(' obj.label ')'];
            
            % set value
            valSize = size(obj.val);
            if valSize(1)==0
            % empty value
            	value = [];
            elseif isequal(valSize,[1 1])
            % scalar 
                value = eval([func '(obj.val);']);
            elseif valSize(2) == 2
            % 2-column matrix 
                eval(['value = [obj.val(:,1) ' func '(obj.val(:,2))];']);
            else
                value = [];
                warning('Could not perform unary function, assigned empty value');
            end
            
            de = DynamicElement(lab, value, definition);
        end
        
        function [def1, def2, val1, val2, lab1, lab2] = getProperties(obj1,obj2)
        % Get the properties of obj1 and obj2
        % If the object is a DynamicElement simply get the corresponding
        % fields, where def is converted from function handle to string
        % If the object is numeric the val will be the value, the def and lab
        % will be a string representing that value
        
            if isa(obj1, 'DynamicElement') && isa(obj2, 'DynamicElement')
                def1 = func2str(obj1.def);
                def1 = def1(13:end); % remove '@(x,a,u,d,p)' prefix
				val1 = obj1.val;
				def2 = func2str(obj2.def);
                def2 = def2(13:end); % remove '@(x,a,u,d,p)' prefix
				val2 = obj2.val;
                lab1 = obj1.label;
                lab2 = obj2.label;
			elseif isnumeric(obj1)
				def1 = num2str(obj1);
				val1 = obj1;
                lab1 = num2str(obj1);
				def2 = func2str(obj2.def);
                def2 = def2(13:end); % remove '@(x,a,u,d,p)' prefix
				val2 = obj2.val;
                lab2 = obj2.label;
			elseif isnumeric(obj2)
                def1 = func2str(obj1.def);
                def1 = def1(13:end); % remove '@(x,a,u,d,p)' prefix
				val1 = obj1.val;
                lab1 = obj1.label;
				def2 = num2str(obj2);
				val2 = obj2;
                lab2 = num2str(obj2);
            else
                error('Wrong datatype for binary operation');
            end
        end
    end
end

