function de = ifElse(condition, ifTrue, ifFalse)
%IFELSE Create a DynamicElement with an if/else condition
% Inputs:
%   condition       String containing a logical expression
%   ifTrue          DynamicElement or scalar with values to be assigned if true
%   ifFalse         DynamicElement or scalar with values to be assigned if false
%
% The new DynamicElement will have a def such that whenever <condition> is true, 
% the value of <ifTrue> will be taken. If <condition> is false, the value of <ifFalse>
% is taken. More specifically, the new elemenet will have a def of the form:
%  <condition>*<defTrue> + <1-condition>*<defFalse>

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com


    %% Set definition
    if isa(ifTrue, 'DynamicElement')
        defTrue = ifTrue.label;
    elseif isscalar(ifTrue)
        defTrue = num2str(ifTrue);
    else
        error('ifTrue is not a DynamicElement or a scalar');
    end
    
    if isa(ifFalse, 'DynamicElement')
        defFalse = ifFalse.label;
    elseif isscalar(ifFalse)
        defFalse = num2str(ifFalse);
    else
        error('ifFalse is not a DynamicElement or a scalar');
    end
    
    if isa(condition, 'DynamicElement')
        condition = getDefStr(condition);
    end
        
    def = ['(' condition ').*(' defTrue ') + (1-(' condition ')).*(' defFalse ')'];

    de = DynamicElement(def);
    
end

