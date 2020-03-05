function cor = corrcoef(obj, input)
%CORRCOEF Calculates the Pearson correlation coefficient between all elements of obj and an input.
% The output cor is a struct with the same structure as obj, only with the
% correlation coefficients between obj and the input.
% It is assumed that all DynamicElements in obj that have a trajectory as
% their val field (a two-column matrix) all have the same size. input
% should be a vector with the same length as those matrices.

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com

    cor = struct;

    % Get correlation with states, auxStates, controls, and inputs
    cor.x = corElement(obj, 'x', input);
    cor.a = corElement(obj, 'a', input);
    cor.u = corElement(obj, 'u', input);
    cor.d = corElement(obj, 'd', input);
 
    % get correlation with time
    inputName = fields(obj.d);
    corMatrix = corrcoef(obj.d.(inputName{1}).val(:,1), input);
    cor.t = corMatrix(1,2);
end

function cor = corElement(obj, element, input)
% calculate the correlation coefficients for one of the elements of obj
% element: 'x', 'a', 'c', or 'd', i.e.,
%           states, auxStates, controls, or inputs
    names = fields(obj.(element));

    for k=1:length(names)
        corMatrix = corrcoef(obj.(element).(names{k}).val(:,2), input);
        cor.(names{k}) = corMatrix(1,2);
    end
end

