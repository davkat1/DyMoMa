classdef DynamicModel < matlab.mixin.Copyable 
% STATESPACEMODEL A class for state space models defined by ODEs.
%
% Properties:
%    x      states                             DynamicElement struct
%    a      auxiliary states                   DynamicElement struct
%    d      disturbances (uncontrolled inputs) DynamicElement struct
%    p      parameters                         DynamicElement struct
%    u      controls                           DynamicElement struct
%    c      constraints                        DynamicElement struct
%    g      goal                               string
%    t 		timespan                           DynamicElement
%    e      events                             struct array (currently in development).
%                                              The idea is to be able to
%                                              send events to the ODE
%                                              solver, see https://nl.mathworks.com/help/matlab/math/ode-event-location.html
%
% See readme for full details.

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com
    
    properties
        x           % states                             DynamicElement struct
        a           % auxiliary states                   DynamicElement struct
        d           % disturbances (uncontrolled inputs) DynamicElement struct
        p           % parameters                         DynamicElement struct
        u           % controls                           DynamicElement struct
		c           % constraints                        DynamicElement struct
        g           % goal                               string
        t 			% timespan                           DynamicElement
        e           % events                             struct array (currently in development)

    end

    methods
        function m = DynamicModel(dm)
        %STATESPACEMODEL constructor for DynamicModel
        % If no argument is given, creates an empty DynamicModel object
        % if a DynamicModel is given, creates a copy of the argument
            m.t = DynamicElement();
            if nargin == 1 && isa(dm, 'DynamicModel')
                
                % Make a hard copy of dm
                [stateNames, auxNames, ctrlNames, paramNames, inputNames] = getFieldNames(dm);

                m = DynamicModel();
                m.t = DynamicElement(dm.t);

                for k=1:length(stateNames)
                    m.x.(stateNames{k}) = DynamicElement(dm.x.(stateNames{k}));
                end

                for k=1:length(auxNames)
                    m.a.(auxNames{k}) = DynamicElement(dm.a.(auxNames{k}));
                end

                 for k=1:length(ctrlNames)
                    m.u.(ctrlNames{k}) = DynamicElement(dm.u.(ctrlNames{k}));
                end

                for k=1:length(paramNames)
                    m.p.(paramNames{k}) = DynamicElement(dm.p.(paramNames{k}));
                end

                for k=1:length(inputNames)
                    m.d.(inputNames{k}) = DynamicElement(dm.d.(inputNames{k}));
                end
                m.c = dm.c;
                m.g = dm.g;
            end
        end
    end
end

