function plot(dm, de)
%PLOT Plot a DynamicModel or a DynamicElement belonging to a DynamicModel
%
% Usage:
%   plot(dm)
%   plot(dm, de)
%
% If only dm is given, creates 4 different figures:
%   Figure 1: plots all state trajectories
%   Figure 2: plots all control trajectories
%   Figure 3: plots all input trajectories
%   Figure 4: plots all auxiliary state trajectories
%
% If de is also given, creates a plot of the DynamicElement de.
% In this case this function is useful if de has no val field calculated,
% but a def field that depends on other elements in dm, that do have a val
% field calculated

% David Katzin, Wageningen University
% david.katzin@wur.nl

    if ~exist('de', 'var') % plot the whole DynamicModel
        inputNames = fieldnames(dm.d);
        stateNames = fieldnames(dm.x);
        auxNames = fieldnames(dm.a);
        if isempty(dm.u)
            ctrlNames = [];
        else
            ctrlNames = fieldnames(dm.u);
        end

        inputNum = length(inputNames);
        stateNum = length(stateNames);
        ctrlNum = length(ctrlNames);
        auxNum = length(auxNames);

        figure;
        for n=1:stateNum
            subplot(stateNum,1,n);
            plot(dm.x.(stateNames{n}));
            title(['x.' stateNames{n}]);
            axis tight;
        end

        if ctrlNum>0
            figure;
            for n=1:ctrlNum
                subplot(ctrlNum,1,n);
                plot(dm.u.(ctrlNames{n}));
                title(['u.' ctrlNames{n}]);
                axis tight;
            end
        end

        figure;
        for n=1:inputNum
            subplot(inputNum,1,n);
            plot(dm.d.(inputNames{n}));
            title(['d.' inputNames{n}]);
            axis tight;
        end

        figure;
        for n=1:auxNum
            subplot(auxNum,1,n);
            plot(dm.a.(auxNames{n}));
            title(['a.' auxNames{n}]);
            axis tight;
        end
        
    else % plot a dynamic element belonging to this dm
        stateNames = fieldnames(dm.x);
        for k=1:length(stateNames)
            x.(stateNames{k}) = dm.x.(stateNames{k});
            x.(stateNames{k}).def = ['x.' (stateNames{k})];
        end
        u = dm.u; d = dm.d; a = dm.a; p = dm.p;
        plot(eval(de.def));
    end
end

