classdef rxCSMACD < handle
    
    properties
        addr        % Our address
        domain      % Collision domain of rx
        state       % Current state
        delay       % Current amount of delay
        tx          % Who is xmitting to rx
    end

    methods
        function obj = rxCSMACD(addr, domain)
            obj.addr = 1;
            obj.domain = [1 2];
            obj.state = "idle";
            obj.delay = 0;
            if nargin > 0
                obj.addr = addr;
            end
            if nargin > 1
                obj.domain = domain;
            end
        end
        
        function [xmit, ACK] = update(obj, channel, tx)
            xmit = [];  % By default, xmit to nobody
            ACK = [];   % By default, ACK nobody
            switch obj.state
                case "idle"
                    if sum(channel == obj.addr) > 1     % rx sees more than one xmission
                        obj.state = "collision";
                    elseif ismember(obj.addr, channel) && ~isempty(tx)  % rx sees one xmission, and one person xmitting to rx
                        obj.state = "receive";
                        obj.delay = 2;
                        obj.tx = tx;
                    end

                case "collision"
                    if ~ismember(obj.addr, channel)     % Wait for channel to clear
                        obj.state = "idle";
                    end

                case "receive"
                    if sum(channel == obj.addr) > 1     % rx sees more than one xmission
                        obj.state = "collision";
                    else
                        obj.delay = obj.delay - 1;
                        if obj.delay == 0
                            obj.state = "SIFS";
                            obj.delay = 1;
                        end
                    end

                case "SIFS"
                    if ismember(obj.addr, channel)      % rx still sees a busy channel
                        obj.state = "collision";
                    else
                        obj.delay = obj.delay - 1;
                        if obj.delay == 0
                            obj.state = "ACK";
                            obj.delay = 2;
                        end
                    end

                case "ACK"
                    if ismember(obj.addr, channel)      % rx still sees a busy channel
                        obj.state = "collision";
                    else
                        xmit = obj.domain;
                        ACK = obj.tx;
                        obj.delay = obj.delay - 1;
                        if obj.delay == 0
                            obj.state = "idle";
                        end
                    end

                otherwise
                    obj.state = "idle";
            end
        end
    end
    
end

