function strOut = joinUnits(strIn)
%JOINUNITS Joins together similar units in a unit definition string.
% e.g., 'kg^{2} m^{-2} m kg^{-1}' would become 'kg m^{-1}'

    words = split(strIn);
    units = cell(size(words));
    exponents = zeros(size(words));

    for k=1:length(words)
        curWord = words{k};
        lBrack = find(curWord=='{');
        rBrack = find(curWord=='}');
        if length(lBrack)>=2 || length(rBrack)>=2 || ...
                length(lBrack)~= length(rBrack) || ...
                (length(lBrack)==1 && length(rBrack)==1 && rBrack<=lBrack)
            error('Mismatching parentheses');
        elseif isempty(lBrack) % no brackets
            exponents(k) = 1;
        else % there are brackets
            if curWord(lBrack-1) ~= '^'
                error('Expected ''^'' sign before ''{''');
            end
            curExpStr = curWord(lBrack+1:rBrack-1);
            sign = 1;
            if curExpStr(1) == '-'
                sign = -1;
                curExpStr = curExpStr(2:end);
            end
            if isempty(curExpStr) || ...
                    (sum(isstrprop(curExpStr,'digit')) < length(curExpStr))
                error('Non-numeric exponent');
            else
                exponents(k) = sign*str2double(curExpStr);
            end
            curWord = curWord(1:lBrack-2);
        end
        units{k} = curWord;
    end

    [uniqueUnits, ~, ic] = unique(units);
    uniqueExp = zeros(size(uniqueUnits));

    strOut = [];
    for k=1:length(uniqueUnits)
        uniqueExp(k) = sum(exponents(ic==k));

        if uniqueExp(k) == 1
            strOut = [strOut ' ' uniqueUnits{k}];
        elseif uniqueExp(k) ~= 0
            strOut = [strOut  ' ' uniqueUnits{k} '^{' num2str(uniqueExp(k)) '}'];
        end
    end

    if isempty(strOut)
       strOut = '-';
    else
        strOut = strOut(2:end);
    end
end

