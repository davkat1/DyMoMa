function setTime(obj, label, val)
%SETTIME Set the time field obj.t as a DynamicElement with given label and val
    obj.t = DynamicElement();
    setLabel(obj.t, label);
    setVal(obj.t, val); 
end

