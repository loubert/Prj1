classdef rx2 < handle
    % rx2 Implements CSMA/CA receiver protocol 2

    properties
        addr        % Our address
        domain      % Collision domain of rx
        state       % Current state
        delay       % Current amount of delay
        tx          % Who is xmitting to rx
        next        % Next state (after SIFS/NAV)
        nextDelay   % Delay for next state
    end

    methods
        function obj = rx2(addr, domain)
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
        
        function [pkt] = update(obj, channel)
            pkt = packet();     % Empty packet
            switch obj.state
                case rxStates.idle
                    if (channel.type == pktTypes.RTS) &&... % rx sees an RTS
                            (channel.dest == obj.addr)      % RTS addressed to rx
                        obj.state = rxStates.RTS;
                        obj.delay = const.RTS-1;            % Minus one for the current slot
                        obj.tx = channel.origin;            % Set our tx
                    end

                case rxStates.collision
                    if channel.type == pktTypes.idle    % Wait for channel to clear
                        obj.state = rxStates.idle;
                    end

                case rxStates.RTS
                    if (channel.type ~= pktTypes.RTS) || ...    % Rest of RTS
                            (channel.dest ~= obj.addr) || ...   % Not received
                            (channel.origin ~= obj.tx)          % Assumes RTS > 1 slot
                        obj.state = rxStates.idle;
                    else
                        obj.delay = obj.delay - 1;
                        if obj.delay == 0
                            obj.state = rxStates.RTSSIFS;      % Wait SIFS
                            obj.delay = const.SIFS;
                        end
                    end

                case rxStates.RTSSIFS
                    obj.delay = obj.delay - 1;
                    if obj.delay == 0
                        obj.state = rxStates.CTS;
                        obj.delay = const.CTS;
                        pkt.origin = obj.addr;      % Start sending CTS
                        pkt.dest = obj.tx;
                        pkt.domain = obj.domain;
                        pkt.type = pktTypes.CTS;
                        pkt.length = const.CTS + const.SIFS + const.DATA...
                            + const.SIFS + const.ACK;
                    end

                case rxStates.CTS
                    obj.delay = obj.delay - 1;
                    if obj.delay == 0
                        obj.delay = const.SIFS;
                        obj.state = rxStates.CTSSIFS;
                    else
                        pkt.origin = obj.addr;      % Continue sending CTS
                        pkt.dest = obj.tx;
                        pkt.domain = obj.domain;
                        pkt.type = pktTypes.CTS;
                    end
                    
                case rxStates.CTSSIFS
                    obj.delay = obj.delay - 1;
                    if obj.delay == 0
                        obj.delay = const.DATA;
                        obj.state = rxStates.DATA;
                    end

                case rxStates.DATA
                    obj.delay = obj.delay - 1;
                    if channel.type ~= pktTypes.DATA    % rx sees wrong type of xmission
                        obj.state = rxStates.collision;
                    elseif obj.delay == 0
                        obj.state = rxStates.DATASIFS;  % Wait for SIFS
                        obj.delay = const.SIFS;
                    end

                case rxStates.DATASIFS
                    obj.delay = obj.delay - 1;
                    if obj.delay == 0
                        pkt.origin = obj.addr;      % Set origin as rx
                        pkt.dest = obj.tx;          % Set destination as tx
                        pkt.domain = obj.domain;    % Send to entire collision domain
                        pkt.type = pktTypes.ACK;    % Packet type = ACK
                        obj.state = rxStates.ACK;   % Transition to ACK state
                        obj.delay = const.ACK;
                    end

                case rxStates.ACK
                    obj.delay = obj.delay - 1;
                    if obj.delay == 0
                        obj.state = rxStates.idle;
                        obj.tx = [];
                    else
                        pkt.origin = obj.addr;      % Set origin as rx
                        pkt.dest = obj.tx;          % Set destination as tx
                        pkt.domain = obj.domain;    % Send to entire collision domain
                        pkt.type = pktTypes.ACK;    % Packet type = ACK
                        obj.state = rxStates.ACK;   % Transition to ACK state
                    end

                otherwise
                    obj.state = rxStates.idle;
            end
        end
    end
    
end