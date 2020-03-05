function strOut = invertUnits(strIn)
%INVERTUNITS Inverts units in a unit definition string.
% e.g., 'kg^{2} m^{-2}' becomes 'kg^{-2} m^{2}'

    words = split(strIn);
    newWords = cell(size(words));
    
    for k=1:length(words)
        curWord = words{k};
        lBrack = find(curWord=='{');
        rBrack = find(curWord=='}');
        if length(lBrack)>=2 || length(rBrack)>=2 || ...
                length(lBrack)~= length(rBrack) || ...
                (length(lBrack)==1 && length(rBrack)==1 && rBrack<=lBrack)
            error('Mismatching parentheses');
        elseif isempty(lBrack) % no brackets
            newWords{k} = [curWord '^{-1}'];
        else % there are brackets
            if curWord(lBrack-1) ~= '^'
                error('Expected ''^'' sign before ''{''');
            end
            if curWord(lBrack+1) == '-'
                newWords{k}=[curWord(1:lBrack) curWord(lBrack+2:end)];
            else
                newWords{k}=[curWord(1:lBrack) '-' curWord(lBrack+1:end)];
            end
        end
    end
    
    strOut = join(newWords);
    strOut = strOut{1};
end