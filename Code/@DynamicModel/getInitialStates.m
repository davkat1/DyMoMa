function x = getInitialStates(obj)
%GETINITIALSTATES Get a vector with the initial valus of the states
% x is a column vector, with each row representing a state
% the order of x come from getFieldNames(dm)

    % Get names of states from obj
    [stateNames, ~, ~, ...
    ~, ~] = getFieldNames(obj);

    x = nan(length(stateNames),1);

    % convert the column x to a struct
    for n=1:length(stateNames)
        if isscalar(obj.x.(stateNames{n}).val)
            x(n) = obj.x.(stateNames{n}).val;
        else
            x(n) = obj.x.(stateNames{n}).val(1,2);
        end
    end
end