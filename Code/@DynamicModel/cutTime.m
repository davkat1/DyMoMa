function newObj = cutTime(obj, startTime, timeSpan)
% CUTTIME Create a new DynamicModel where elements with a time trajectory are an excerpt of the original time trajectory. 
% It is assumed that all DynamicElements within the object that have time trajectories, have 
% identical time points (i.e., the first column in the val field is the same for all time-dependent 
% elements in the model). This can be ensured by using changeRes.
% 
% It is also assumed that obj has a t value (obj.t) where the time unit
% (expressed in obj.t.val) is expressed in seconds, and that obj.t.label
% can be read by the function datenum, i.e., datenum(obj.t.label) works.
%
% Usage:
%   newObj = cutTime(obj, startTime, timeSpan)
%   
%   obj - an existing DynamicModel
%   startTime - time where the new DynamicModel will start (datenum, days since 00-Jan-0000)
%   timeSpan - the length of time in the new DynamicModel (seconds)

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com

    [stateNames, auxNames, ctrlNames, ~, inputNames] = getFieldNames(obj);

    newObj = DynamicModel(obj);
    
    newObj.t.label = datestr(startTime);
    newObj.t.val = [0 timeSpan];
    
    timelineObj = obj.x.(stateNames{1}).val(:,1);
    
    startPoint = find(timelineObj>=86400*(datenum(newObj.t.label)-datenum(obj.t.label)),1);
    endPoint = find(timelineObj>=(86400*(datenum(newObj.t.label)-datenum(obj.t.label))+timeSpan));
    
    if isempty(endPoint)
        endPoint = length(timelineObj);
    end
    
    timelineNewObj = timelineObj(startPoint:endPoint)-timelineObj(startPoint);
    
    for k=1:length(stateNames)
        if ~isempty(obj.x.(stateNames{k}).val) && ~isscalar(obj.x.(stateNames{k}).val)
            newObj.x.(stateNames{k}).val = [];
            newObj.x.(stateNames{k}).val(:,1) = timelineNewObj;
            newObj.x.(stateNames{k}).val(:,2) = obj.x.(stateNames{k}).val(startPoint:endPoint,2);
        end     
    end
    
    for k=1:length(auxNames)
        if ~isempty(obj.a.(auxNames{k}).val) && ~isscalar(obj.a.(auxNames{k}).val)
            newObj.a.(auxNames{k}).val = [];
            newObj.a.(auxNames{k}).val(:,1) = timelineNewObj;
            newObj.a.(auxNames{k}).val(:,2) = obj.a.(auxNames{k}).val(startPoint:endPoint,2);
        end     
    end
    
    for k=1:length(inputNames)
        if ~isempty(obj.d.(inputNames{k}).val) && ~isscalar(obj.d.(inputNames{k}).val)
            newObj.d.(inputNames{k}).val = [];
            newObj.d.(inputNames{k}).val(:,1) = timelineNewObj;
            newObj.d.(inputNames{k}).val(:,2) = obj.d.(inputNames{k}).val(startPoint:endPoint,2);
        end     
    end
    
    for k=1:length(ctrlNames)
        if ~isempty(obj.u.(ctrlNames{k}).val) && ~isscalar(obj.u.(ctrlNames{k}).val)
            newObj.u.(ctrlNames{k}).val = [];
            newObj.u.(ctrlNames{k}).val(:,1) = timelineNewObj;
            newObj.u.(ctrlNames{k}).val(:,2) = obj.u.(ctrlNames{k}).val(startPoint:endPoint,2);
        end     
    end
end
  
