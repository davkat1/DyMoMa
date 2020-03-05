function outString = compareParams(dm1,dm2)
%COMPAREPARAMS Create a table detailing the difference in parameters between two DynamicModels
%   The output format is:
%
%   paramName           value in dm1           value in dm2
%   ---------------------------------------------------------
%   <param1>            <val11>                 <val12>
%   <param2>            <val21>                 <val22>
%   ...                 ...                     ...
%
% Where param1, param2, ... are the parameters that have different values
% between the two DynamicModels. Parameters that only exist in one model
% and not in the other will also appear here.

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com

    [~, ~, ~, paramNames1, ~] = getFieldNames(dm1);
    [~, ~, ~, paramNames2, ~] = getFieldNames(dm2);
    
    paramNames1 = sort(paramNames1);
    paramNames2 = sort(paramNames2);
    
    len1 = length(paramNames1);
    len2 = length(paramNames2);
    
    outString = sprintf('paramName \t\t\t  value in dm1 \t\t\t  value in dm2 \t \n');
    outString = sprintf('%s----------------------------------------------------------------\n', outString);
    outTop = outString;
    
    i1 = 1; % index for paramNames1
    i2 = 1; % index for paramNames2
    
    while i1<=len1 || i2<=len2
        if i1 > len1 % i2<=len2
           % dm2 has a parameter that doesn't exist in dm1
            outString = sprintf('%s%s \t\t\t\t  Doesnt exist \t\t\t  %2.2d  \t\t \n',...
            outString, paramNames2{i1}, dm2.p.(paramNames2{i2}).val);
            i2 = i2+1;
        elseif i2 > len2 % n1<=len1
            % dm1 has a parameter that doesn't exist in dm2
            outString = sprintf('%s%s \t\t\t\t  %2.2d \t\t\t  %2.2d  \t\t  Doesnt exist \t \n',...
            outString, paramNames1{i1}, dm1.p.(paramNames1{i1}).val);
            i1 = i1+1;
        elseif strcmp(paramNames1{i1}, paramNames2{i2}) ...
                && dm1.p.(paramNames1{i1}).val ~= dm2.p.(paramNames2{i2}).val
            % next param on the list is equal for both lists, 
            % but values are not equal
            outString = sprintf('%s%s \t\t\t\t  %2.2d \t\t\t  %2.2d  \t\t \n',...
            outString, paramNames1{i1}, dm1.p.(paramNames1{i1}).val, dm2.p.(paramNames2{i2}).val);
            i1=i1+1;
            i2=i2+1;
        elseif string(paramNames1{i1}) < string(paramNames2{i2})
            % dm1 has a parameter that doesn't exist in dm2
            outString = sprintf('%s%s \t\t\t\t  %2.2d \t\t\t  %2.2d  \t\t  Doesnt exist \t \n',...
            outString, paramNames1{i1}, dm1.p.(paramNames1{i1}).val);
            i1 = i1+1;
        elseif string(paramNames1{i1}) > string(paramNames2{i2})
            % dm2 has a parameter that doesn't exist in dm1
            outString = sprintf('%s%s \t\t\t\t  Doesnt exist \t\t\t  %2.2d  \t\t \n',...
            outString, paramNames2{i2}, dm2.p.(paramNames2{i2}).val);
            i2 = i2+1;
        else
            % paramNames are the same and their values are equal
            i1 = i1+1;
            i2 = i2+1;
        end
    end
    
    if strcmp(outString, outTop) % no different params found
        outString = 'All parameters are equal';
    end
end

