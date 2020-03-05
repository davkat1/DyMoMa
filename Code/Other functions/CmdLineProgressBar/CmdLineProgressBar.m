classdef CmdLineProgressBar < handle
% class for command-line progress-bar notification.
% Use example:
%   pb = CmdLineProgressBar('Doing stuff...');
%   for k = 1 : 10
%       pb.print(k,10)
%       % do stuff
%   end
%
% Author: Itamar Katz, itakatz@gmail.com
% Added display of ETA, time left, and running time: 
%       David Katzin, david.katzin@wur.nl

    properties
        last_msg_len = 0;
        startTime = [];
    end
    methods
        %--- ctor
        function obj = CmdLineProgressBar(msg, startTime)
            fprintf('%s', msg)
            if exist('startTime','var')
               obj.startTime = startTime;
            end
        end
        %--- print method
        function print(obj, n, tot)
            fprintf('%s', char(8*ones(1, obj.last_msg_len))) % delete last info_str
            
            if ~isempty(obj.startTime) && n>0
                timeLeft = (tot-n)/n*days(datetime('now')-obj.startTime);
                eta = datestr(datetime('now')+timeLeft);
                hoursTl = floor(timeLeft*24);
                minutesTl = floor((timeLeft*24-hoursTl)*60);
                secondsTl = floor((timeLeft*24*60-hoursTl*60-minutesTl)*60);
                
                runtime = days(datetime('now')-obj.startTime);
                hoursRt = floor(runtime*24);
                minutesRt = floor((runtime*24-hoursRt)*60);
                secondsRt = floor((runtime*24*60-hoursRt*60-minutesRt)*60);

                info_str = sprintf('%2.2f/%03d; ETA: %s; time left: %02d:%02d:%02d running time: %02d:%02d:%02d',...
                    n, tot, eta, hoursTl,minutesTl,secondsTl, hoursRt, minutesRt, secondsRt);
            else
                info_str = sprintf('%d/%d',n, tot);
            end
            fprintf('%s', info_str);
            %--- assume user counts monotonically
            if n == tot
                fprintf('\n')
            end
            obj.last_msg_len = length(info_str);
        end
        %--- dtor
        function delete(obj)
            fprintf('\n')
        end
    end
end