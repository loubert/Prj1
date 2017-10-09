classdef rx1 < handle
    % rx1 Implements CSMA/CA receiver protocol 1

    properties
        addr        % Our address
        domain      % Collision domain of rx
        state       % Current state
        delay       % Current amount of delay
        tx          % Who is xmitting to rx
    end

    methods
        function obj = rx1(addr, domain)
            obj.addr = 1;
            obj.domain = [1 2];
            obj.state = rxStates.idle;
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
                case rxStates.idle
                    if sum(channel == obj.addr) > 1     % rx sees more than one xmission
                        obj.state = rxStates.collision;
                    elseif ismember(obj.addr, channel) && ~isempty(tx)  % rx sees one xmission, and one person xmitting to rx
                        obj.state = rxStates.receive;
                        obj.delay = 99;         % 100 slots, minus one for the current slot
                        obj.tx = tx;
                    end

                case rxStates.collision
                    if ~ismember(obj.addr, channel)     % Wait for channel to clear
                        obj.state = rxStates.idle;
                    end

                case rxStates.receive
                    if sum(channel == obj.addr) > 1     % rx sees more than one xmission
                        obj.state = rxStates.collision;
                    else
                        obj.delay = obj.delay - 1;
                        if obj.delay == 0
                            obj.state = rxStates.SIFS;
                            obj.delay = 1;
                        end
                    end

                case rxStates.SIFS
                    if ismember(obj.addr, channel)      % rx still sees a busy channel
                        obj.state = rxStates.collision;
                    else
                        obj.delay = obj.delay - 1;
                        if obj.delay == 0
                            xmit = obj.domain;          % rx has the channel
                            ACK = obj.tx;               % Sending ACK to tx
                            obj.state = rxStates.ACK;   % Transition to ACK
                            obj.delay = 2;              % ACK = 2 slots
                        end
                    end

                case rxStates.ACK
                    if sum(channel == obj.addr) > 1     % rx sees more than rx on the channel
                        obj.state = rxStates.collision;
                    else
                        obj.delay = obj.delay - 1;
                        if obj.delay == 0
                            obj.state = rxStates.idle;
                        else
                            xmit = obj.domain;          % rx has the channel
                            ACK = obj.tx;               % Sending ACK to tx
                        end
                    end

                otherwise
                    obj.state = rxStates.idle;
            end
        end
    end
    
end