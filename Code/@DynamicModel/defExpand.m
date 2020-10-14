function defExpand(dm, de)
%DEFEXPAND Expand the def of a DynamicElement de in DynamicModel dm so it does not contain aux states
% The function repeatedly searches for aux states in the def of de and
% replaces their names with the definition of the aux states. This is done
% until no aux states appear in the def of de

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com

    de.def = func2str(de.def);
    ind = strfind(de.def, 'a.'); 
    % indexes of places in def where an aux state appears
    
    while ~isempty(ind)
        % collect all names of aux appearing in de.def
        for k=1:length(ind)
            kEnd = ind(k)+find(~isstrprop(de.def(ind(k)+2:end),'alphanum'),1);
            if isempty(kEnd) % name of aux is at end of definition
                kEnd = length(de.def);
            end
            auxNames{k} = de.def(ind(k):kEnd);
        end
        auxNames = unique(auxNames); % remove repetitions

        % collect lengths of found auxNames
        for k=1:length(auxNames)
            nameLengths(k) = length(auxNames{k});
        end

        % replace auxName by auxName.def, from the longest to shortest auxNames
        % (to avoid cases where a.foo and a.foobar both exist, and a.foobbar
        % becomes a.fooDefinitionbar)
        while sum(nameLengths) > 0
            biggestNameInd = find(nameLengths==max(nameLengths),1);

            aux = auxNames{biggestNameInd}; % name of aux state being replaced
            auxNoA = aux(3:end); % name of the same state without the 'a.' prefix

            de.def = strrep(de.def, aux, getDefStr(dm.a.(auxNoA)));
            nameLengths(biggestNameInd) = 0;
        end

        auxNames = [];
        ind = strfind(de.def, 'a.'); 
    end
    de.def = str2func(de.def);
end

