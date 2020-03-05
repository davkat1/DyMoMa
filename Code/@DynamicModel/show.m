function show(obj, field)
%SHOW Prints out a list of DynamicElements in a specific field of a DynamicModel
% Inputs:
%   obj     - a DynamicModel
%   field   - 'x', 'a', 'd', 'p', 'u', 'c', 'g', 't', representing
%             respectively the states, auxiliary states, inputs,
%             parameters, controls, constraints, goal, and time fields of
%             the DynamicModel

    if ~exist('field','var')
        outStr = [];

        fieldNames = fields(obj);
        for k = 1:length(fieldNames)
            fieldName = fieldNames{k};
            field = obj.(fieldName);
            if isempty(field)
                fieldStr = '[]';
            elseif isa(field, 'DynamicElement')
                fieldStr = sprintf('DynamicElement with label ''%s''',field.label);
            elseif ~isstruct(field)
                fieldStr = evalc('disp(field)');
                fieldStr = fieldStr(3:end-2);
            else
                subFieldNames = fields(field);
                fieldStr = [];
                for n = 1:length(subFieldNames)
                    fieldStr = [fieldStr subFieldNames{n} ', '];
                end
                fieldStr = fieldStr(1:end-2);
            end
            outStr = sprintf('%s\t%s: %s\n', outStr, fieldName, fieldStr);
        end
    else
        if isempty(obj.(field))
            outStr = '[]';
        elseif ~isstruct(obj.(field))
            outStr = evalc('disp(obj.(field))');
            outStr = outStr(1:end-1);
        else
            outStr = [];
            fieldNames = fields(obj.(field));
            for k=1:length(fieldNames)
                if field == 'p' % parameters
                    fieldStr = num2str(obj.p.(fieldNames{k}).val);
                    outStr = sprintf('%s\t%s: %s\n', ...
                        outStr, fieldNames{k}, fieldStr);
                else
                fieldStr = evalc('disp(obj.(field).(fieldNames{k}))');
                colon = strfind(fieldStr, ':');
                fieldStr = fieldStr(colon(3)+3:end-2);
                outStr = sprintf(['%s  ' ...
                    '<a href = "matlab:helpPopup DynamicElement" style="font-weight:bold">%s</a>' ...
                    '\n%s\n'],outStr, fieldNames{k}, fieldStr);
                end
            end
        end         
    end
    fprintf(outStr);
end

