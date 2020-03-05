function ctrl = proportionalControl(processVar, setPt, pBand, min, max)
%PROPORTIONALCONTROL Create a smooth controller directing processVar towards setPt
% Usage:
%   ctrl = proportionalControl(processVar, setPt, pBand, min, max)
% Inputs:
%   processVar      Process variable defining the controller (DynamicElement)
%   setPt           Set point for process variable (DynamicElement or scalar)
%   pBand           Proportional band for the controller (DynamicElement or scalar)
%                       If >0, controller starts when processVar is above setPoint
%                       If <0, controller starts when processVar is below setPoint
%   min             Controller value at no power (scalar)
%   max             Controller value at full power (scalar)
%
% Outputs (for the case pBand>=0, switch directions otherwise):
%   ctrl            Returns approx. min if processVar is at or below setPoint
%                   Returns approx. max if processVar is at or above
%                       setPoint+pBand
%                   Smoothly extraploates between these values if processVar
%                       is between setPoint and setPoint+pBand

% David Katzin, Wageningen University
% david.katzin@wur.nl
% david.katzin1@gmail.com
    
    ctrl = min+(max-min).*(1./(1+exp(-2./pBand.*log(100).*(processVar-setPt-pBand/2))));
    
end

