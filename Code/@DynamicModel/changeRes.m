function newObj = changeRes(obj, newRes)
%CHANGERES create a new DynamicModel object where all data is in a given time resolution
% All DynamicElements belonging to obj, that have a time trajectory as
% their val (a two-column matrix), will have the trajectory reformatted to 
% a fixed time step trajectory with step size newRes

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com

    [stateNames, auxNames, ctrlNames, paramNames, inputNames] = getFieldNames(obj);

    newObj = DynamicModel(obj);
    
    tStart = newObj.t.val(1);
    tEnd = newObj.t.val(2);
    
    timePhase = tStart:newRes:tEnd;
    
    for k=1:length(stateNames)
        newObj.x.(stateNames{k}) = DynamicElement(obj.x.(stateNames{k}));
        if ~isempty(newObj.x.(stateNames{k}).val) && ~isscalar(newObj.x.(stateNames{k}).val)
            newObj.x.(stateNames{k}).val = [];
            newObj.x.(stateNames{k}).val(:,1) = timePhase';
            newObj.x.(stateNames{k}).val(:,2) = interp1(obj.x.(stateNames{k}).val(:,1),...
                obj.x.(stateNames{k}).val(:,2),timePhase); 
            newObj.x.(stateNames{k}).val(find(newObj.x.(stateNames{k}).val(:,1) ...
                > obj.x.(stateNames{k}).val(end,1)),2)=obj.x.(stateNames{k}).val(end,2);
            newObj.x.(stateNames{k}).val(find(newObj.x.(stateNames{k}).val(:,1) ...
                < obj.x.(stateNames{k}).val(1,1)),2)=obj.x.(stateNames{k}).val(1,2);
        end
    end
    
    for k=1:length(auxNames)
        newObj.a.(auxNames{k}) = DynamicElement(obj.a.(auxNames{k}));
        if ~isempty(newObj.a.(auxNames{k}).val) && ~isscalar(newObj.a.(auxNames{k}).val)
            newObj.a.(auxNames{k}).val = [];
            newObj.a.(auxNames{k}).val(:,1) = timePhase';
            newObj.a.(auxNames{k}).val(:,2) = interp1(obj.a.(auxNames{k}).val(:,1),...
                obj.a.(auxNames{k}).val(:,2),timePhase); 
            newObj.a.(auxNames{k}).val(find(newObj.a.(auxNames{k}).val(:,1) ...
                > obj.a.(auxNames{k}).val(end,1)),2)=obj.a.(auxNames{k}).val(end,2);
            newObj.a.(auxNames{k}).val(find(newObj.a.(auxNames{k}).val(:,1) ...
                < obj.a.(auxNames{k}).val(1,1)),2)=obj.a.(auxNames{k}).val(1,2);
        end
    end
    
     for k=1:length(ctrlNames)
        newObj.u.(ctrlNames{k}) = DynamicElement(obj.u.(ctrlNames{k}));
        if ~isempty(newObj.u.(ctrlNames{k}).val) && ~isscalar(newObj.u.(ctrlNames{k}).val)
            newObj.u.(ctrlNames{k}).val = [];
            newObj.u.(ctrlNames{k}).val(:,1) = timePhase';
            newObj.u.(ctrlNames{k}).val(:,2) = interp1(obj.u.(ctrlNames{k}).val(:,1),...
                obj.u.(ctrlNames{k}).val(:,2),timePhase); 
            newObj.u.(ctrlNames{k}).val(find(newObj.u.(ctrlNames{k}).val(:,1) ...
                > obj.u.(ctrlNames{k}).val(end,1)),2)=obj.u.(ctrlNames{k}).val(end,2);
            newObj.u.(ctrlNames{k}).val(find(newObj.u.(ctrlNames{k}).val(:,1) ...
                < obj.u.(ctrlNames{k}).val(1,1)),2)=obj.u.(ctrlNames{k}).val(1,2);
        end
    end
   
    for k=1:length(paramNames)
        newObj.p.(paramNames{k}) = DynamicElement(obj.p.(paramNames{k}));
    end
    
    for k=1:length(inputNames)
        newObj.d.(inputNames{k}) = DynamicElement(obj.d.(inputNames{k}));
        if ~isempty(newObj.d.(inputNames{k}).val) && ~isscalar(newObj.d.(inputNames{k}).val)
            newObj.d.(inputNames{k}).val = [];
            newObj.d.(inputNames{k}).val(:,1) = timePhase';
            newObj.d.(inputNames{k}).val(:,2) = interp1(obj.d.(inputNames{k}).val(:,1),...
                obj.d.(inputNames{k}).val(:,2),timePhase); 
            newObj.d.(inputNames{k}).val(find(newObj.d.(inputNames{k}).val(:,1) ...
                > obj.d.(inputNames{k}).val(end,1)),2)=obj.d.(inputNames{k}).val(end,2);
            newObj.d.(inputNames{k}).val(find(newObj.d.(inputNames{k}).val(:,1) ...
                < obj.d.(inputNames{k}).val(1,1)),2)=obj.d.(inputNames{k}).val(1,2);
        end
    end

end
  
