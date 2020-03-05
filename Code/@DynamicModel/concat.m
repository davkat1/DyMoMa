function newObj = concat(obj1, obj2)
% CONCAT Create a new DynamicModel object with timelines that are a contactenation of obj1 and obj2
% For each of the DynamicModel objects, it is assumed that all DynamicElements
% within that object that have time trajectories, have identical time points
% (i.e., the first column in the val field is the same for all time-dependent 
% elements in the model). This can be ensured by using changeRes

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com

    [stateNames, auxNames, ctrlNames, paramNames, inputNames] = getFieldNames(obj1);
    [stateNames2, auxNames2, ctrlNames2, paramNames2, inputNames2] = getFieldNames(obj2);
    
    if ~(isequal(stateNames,stateNames2) && isequal(auxNames,auxNames2) && ...
            isequal(ctrlNames,ctrlNames2) && isequal(paramNames,paramNames2) && ...
            isequal(inputNames,inputNames2))
        error('Field names mismatch');
    end

    newObj = DynamicModel(obj1);
    
    if ~isfield(obj1.t,'val') && ~isempty(obj1.t.val)
        newObj.t.val(1) = obj1.t.val(1);
        newObj.t.val(2) = obj1.t.val(2)+obj2.t.val(2)-obj2.t.val(1);
    end

    timeline1 = obj1.x.(stateNames{1}).val(:,1);
    timeline2 = obj2.x.(stateNames{1}).val(:,1);   
    timeline = [timeline1; timeline2-timeline2(1)+timeline1(end)];
    start = 1;
    
    if timeline2(1) == 0 % ignore the first value in timeline2
        timeline2 = timeline2(2:end);
        timeline = [timeline1; timeline2+timeline1(end)];
        start = 2;
    end
    
    for k=1:length(stateNames)
        if ~isempty(obj1.x.(stateNames{k}).val) && ~isscalar(obj1.x.(stateNames{k}).val) && ...
                ~isempty(obj2.x.(stateNames{k}).val) && ~isscalar(obj2.x.(stateNames{k}).val)
            newObj.x.(stateNames{k}).val = [];
            newObj.x.(stateNames{k}).val(:,1) = timeline;
            newObj.x.(stateNames{k}).val(:,2) = ...
                [obj1.x.(stateNames{k}).val(:,2); obj2.x.(stateNames{k}).val(start:end,2)];
            
        
        elseif xor(isempty(obj1.x.(stateNames{k}).val),isempty(obj2.x.(stateNames{k}).val)) ...
                ... % one is empty and the other is not
            || xor(isscalar(obj1.x.(stateNames{k}).val),isscalar(obj2.x.(stateNames{k}).val)) ...
                ... % one is scalar and the other is not
            || (isscalar(obj1.x.(stateNames{k}).val) && isscalar(obj2.x.(stateNames{k}).val) ...
                && obj1.x.(stateNames{k}).val~=obj2.x.(stateNames{k}).val)
                    % both are scalars but not equal
            error('Field mismatch for x.%s',stateNames{k});
        end     
    end
    
    for k=1:length(auxNames)
        if ~isempty(obj1.a.(auxNames{k}).val) && ~isscalar(obj1.a.(auxNames{k}).val) && ...
                ~isempty(obj2.a.(auxNames{k}).val) && ~isscalar(obj2.a.(auxNames{k}).val)
            newObj.a.(auxNames{k}).val = [];
            newObj.a.(auxNames{k}).val(:,1) = timeline;
            newObj.a.(auxNames{k}).val(:,2) = ...
                [obj1.a.(auxNames{k}).val(:,2); obj2.a.(auxNames{k}).val(start:end,2)];
            
        
        elseif xor(isempty(obj1.a.(auxNames{k}).val),isempty(obj2.a.(auxNames{k}).val)) ...
                ... % one is empty and the other is not
            || xor(isscalar(obj1.a.(auxNames{k}).val),isscalar(obj2.a.(auxNames{k}).val)) ...
                ... % one is scalar and the other is not
            || (isscalar(obj1.a.(auxNames{k}).val) && isscalar(obj2.a.(auxNames{k}).val) ...
                && obj1.a.(auxNames{k}).val~=obj2.a.(auxNames{k}).val)
                    % both are scalars but not equal
            error('Field mismatch for a.%s',auxNames{k});
        end     
    end
    
    for k=1:length(inputNames)
        if ~isempty(obj1.d.(inputNames{k}).val) && ~isscalar(obj1.d.(inputNames{k}).val) && ...
                ~isempty(obj2.d.(inputNames{k}).val) && ~isscalar(obj2.d.(inputNames{k}).val)
            newObj.d.(inputNames{k}).val = [];
            newObj.d.(inputNames{k}).val(:,1) = timeline;
            newObj.d.(inputNames{k}).val(:,2) = ...
                [obj1.d.(inputNames{k}).val(:,2); obj2.d.(inputNames{k}).val(start:end,2)];
            
        
        elseif xor(isempty(obj1.d.(inputNames{k}).val),isempty(obj2.d.(inputNames{k}).val)) ...
                ... % one is empty and the other is not
            || xor(isscalar(obj1.d.(inputNames{k}).val),isscalar(obj2.d.(inputNames{k}).val)) ...
                ... % one is scalar and the other is not
            || (isscalar(obj1.d.(inputNames{k}).val) && isscalar(obj2.d.(inputNames{k}).val) ...
                && obj1.d.(inputNames{k}).val~=obj2.d.(inputNames{k}).val)
                    % both are scalars but not equal
            error('Field mismatch for d.%s',inputNames{k});
        end     
    end
    
    for k=1:length(ctrlNames)
        if ~isempty(obj1.u.(ctrlNames{k}).val) && ~isscalar(obj1.u.(ctrlNames{k}).val) && ...
                ~isempty(obj2.u.(ctrlNames{k}).val) && ~isscalar(obj2.u.(ctrlNames{k}).val)
            newObj.u.(ctrlNames{k}).val = [];
            newObj.u.(ctrlNames{k}).val(:,1) = timeline;
            newObj.u.(ctrlNames{k}).val(:,2) = ...
                [obj1.u.(ctrlNames{k}).val(:,2); obj2.u.(ctrlNames{k}).val(start:end,2)];
            
        
        elseif xor(isempty(obj1.u.(ctrlNames{k}).val),isempty(obj2.u.(ctrlNames{k}).val)) ...
                ... % one is empty and the other is not
            || xor(isscalar(obj1.u.(ctrlNames{k}).val),isscalar(obj2.u.(ctrlNames{k}).val)) ...
                ... % one is scalar and the other is not
            || (isscalar(obj1.u.(ctrlNames{k}).val) && isscalar(obj2.u.(ctrlNames{k}).val) ...
                && obj1.u.(ctrlNames{k}).val~=obj2.u.(ctrlNames{k}).val)
                    % both are scalars but not equal
            error('Field mismatch for u.%s',ctrlNames{k});
        end     
    end
    
    for k=1:length(paramNames)
        if xor(isempty(obj1.p.(paramNames{k}).val),isempty(obj2.p.(paramNames{k}).val)) ...
                ... % one is empty and the other is not
            || xor(isscalar(obj1.p.(paramNames{k}).val),isscalar(obj2.p.(paramNames{k}).val)) ...
                ... % one is scalar and the other is not
            || (isscalar(obj1.p.(paramNames{k}).val) && isscalar(obj2.p.(paramNames{k}).val) ...
                && obj1.p.(paramNames{k}).val~=obj2.p.(paramNames{k}).val)
                    % both are scalars but not equal
            error('Field mismatch for p.%s',paramNames{k});
        end     
    end

end
  
