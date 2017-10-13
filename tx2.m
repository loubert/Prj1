classdef tx2 < handle
    % tx2 Implements CSMA/CA transmitter protocol 2

    properties
        addr        % Our address
        rx          % Address of our receiver
        domain      % Collision domain of xmitter
        state       % Current state of xmitter
        next        % Next state (after NAV)
        delay       % Current amount of DIFS/SIFS/ACK/frame delay
        NAVdelay    % Current amount of NAV delay
        CW          % Contention window max width
        backoff     % Current backoff value
        numPackets  % Number of packets ready to xmit
    end
    
    methods
        function obj = tx2(addr, rx, domain)
            obj.addr = 1;
            obj.rx = 2;
            obj.domain = [1 2];
            obj.state = txStates.idle;
            obj.next = txStates.idle;
            obj.delay = 0;
            obj.NAVdelay = 0;
            obj.CW = 4;
            obj.backoff = 0;
            obj.numPackets = 0;
            if nargin > 0
                obj.addr = addr;
            end
            if nargin > 1
                obj.rx = rx;
            end
            if nargin > 2
                obj.domain = domain;
            end
        end

        function [pkt] = update(obj, channel)   % Return the channel state on next slot
            pkt = packet();                     % By default, empty transmission

            switch obj.state
                case txStates.idle              % Not preparing to xmit
                    if channel.length > 0
                        obj.NAVdelay = channel.length-1;  % Start NAV
                        obj.state = txStates.NAV;
                        obj.next = txStates.idle;       % Then return to idle
                    elseif(obj.numPackets > 0 && channel.type == pktTypes.idle)  % Ready to xmit
                        obj.state = txStates.DIFS;  % Start DIFS timer
                        obj.delay = const.DIFS;
                    end

                case txStates.DIFS                      % Sensing channel for DIFS time
                    if channel.length > 0
                        obj.NAVdelay = channel.length;  % Start NAV
                        obj.next = txStates.DIFS;       % Then return to DIFS
                        obj.delay = const.DIFS;
                    elseif channel.type ~= pktTypes.idle    % Channel busy, no NAV
                        obj.delay = const.DIFS;             % Start DIFS over
                    else
                        obj.delay = obj.delay - 1;
                        if obj.delay == 0                       % DIFS ended
                            obj.backoff = randi([0 obj.CW-1]);  % Select backoff
                            if obj.backoff == 0                 % Backoff of 0 selected
                                pkt.origin = obj.addr;
                                pkt.dest = obj.rx;          % Set our receiver address
                                pkt.domain = obj.domain;    % Xmit to collision domain
                                pkt.type = pktTypes.RTS;    % Transmit RTS
                                pkt.length = const.RTS + const.SIFS + const.CTS +...
                                    const.SIFS + const.DATA + const.SIFS + const.ACK;
                                obj.state = txStates.RTS;   % Start sending the RTS
                                obj.delay = const.RTS;
                            else
                                obj.state = txStates.bo;    % Start backoff phase
                            end
                        end
                    end

                case txStates.NAV
                    obj.NAVdelay = obj.NAVdelay - 1;
                    if obj.NAVdelay == 0
                        obj.state = obj.next;
                    end

                case txStates.bo    % Backing off
                    if channel.type == pktTypes.idle    % Channel is still idle
                        obj.backoff = obj.backoff - 1;  % Keep backing off
                        if obj.backoff == 0
                            pkt.origin = obj.addr;      % Set origin of packet
                            pkt.dest = obj.rx;          % Set our receiver address
                            pkt.domain = obj.domain;    % Xmit to collision domain
                            pkt.type = pktTypes.RTS;    % Transmit RTS
                            pkt.length = const.RTS + const.SIFS + const.CTS +...
                                const.SIFS + const.DATA + const.SIFS + const.ACK;
                            obj.state = txStates.RTS;   % Start sending the RTS
                            obj.delay = const.RTS;
                        end
                    elseif channel.length > 0           % We have a NAV
                        obj.state = txStates.NAV;       % Defer from transmitting...
                        obj.NAVdelay = channel.length;  % for the time in the NAV...
                        obj.next = txStates.bo;         % then return to backoff
                    else    % Channel busy but no NAV seen
                        obj.state = txStates.freeze;    % freeze
                        obj.delay = const.DIFS;         % Resume backoff when channel is idle for DIFS time
                    end

                case txStates.freeze    % Freeze backoff, resume after DIFS idle time, or NAV seen
                    if channel.length > 0
                        obj.state = txStates.NAV;       % Switch to NAV
                        obj.NAVdelay = channel.length;
                        obj.next = txStates.bo;         % Resume backoff after NAV
                    elseif channel.type == pktTypes.idle    % Channel is idle
                        obj.delay = obj.delay - 1;
                        if obj.delay == 0               % Channel has been idle for DIFS time
                            obj.state = txStates.bo;    % Resume backoff
                        end
                    else                                % Channel is busy, restart freeze
                        obj.delay = const.DIFS;
                    end

                case txStates.RTS       % Transmitting a request to send
                    obj.delay = obj.delay - 1;
                    if obj.delay == 0
                        obj.state = txStates.RTSSIFS;   % Post RTS SIFS
                        obj.delay = const.SIFS;
                    else
                        pkt.origin = obj.addr;      % Set origin of packet
                        pkt.dest = obj.rx;          % Set our receiver address
                        pkt.domain = obj.domain;    % Xmit to collision domain
                        pkt.type = pktTypes.RTS;    % Continue transmit of RTS
                                                    % No NAV
                    end
                    
                case txStates.RTSSIFS
                    obj.delay = obj.delay - 1;
                    if obj.delay == 0
                        obj.state = txStates.waitCTS;
                        obj.delay = const.CTS;
                    end

                case txStates.waitCTS
                    obj.delay = obj.delay - 1;
                    if (channel.type ~= pktTypes.CTS) || (channel.dest ~= obj.addr)
                        obj.state = txStates.DIFS;      % Start over
                        obj.delay = const.DIFS;
                        if obj.CW < 1024                % Exponential backoff
                            obj.CW = obj.CW * 2;
                        end
                    elseif obj.delay == 0
                        obj.state = txStates.CTSSIFS;   % Begin xmitting frame
                        obj.delay = const.SIFS;         % SIFS then frame
                    end

                case txStates.CTSSIFS
                    obj.delay = obj.delay - 1;
                    if obj.delay == 0
                        obj.state = txStates.DATA;
                        obj.delay = const.DATA;
                        pkt.origin = obj.addr;      % Set origin of packet
                        pkt.dest = obj.rx;          % Set our receiver address
                        pkt.domain = obj.domain;    % Xmit to collision domain
                        pkt.type = pktTypes.DATA;   % Transmit RTS
                        pkt.length = const.DATA+const.SIFS+const.ACK;
                    end
                    
                case txStates.DATA
                    obj.delay = obj.delay - 1;
                    if obj.delay == 0
                        obj.state = txStates.DATASIFS;      % Transition to SIFS
                        obj.delay = const.SIFS;
                    else
                        pkt.origin = obj.addr;      % Set origin of packet
                        pkt.dest = obj.rx;          % Set our receiver address
                        pkt.domain = obj.domain;    % Xmit to collision domain
                        pkt.type = pktTypes.DATA;   % Transmit RTS
                    end

                case txStates.DATASIFS
                    obj.delay = obj.delay - 1;
                    if obj.delay == 0
                        obj.state = txStates.waitACK;
                        obj.delay = const.ACK;
                    end
                    
                case txStates.waitACK
                    obj.delay = obj.delay - 1;
                    if (channel.type ~= pktTypes.ACK) || (channel.dest ~= obj.addr)
                        obj.state = txStates.DIFS;              % Some sort of collision
                        obj.delay = const.DIFS;                 % Start over
                        if obj.CW < 1024
                            obj.CW = obj.CW * 2;
                        end
                    elseif obj.delay == 0
                        obj.numPackets = obj.numPackets - 1;    % Reduce packet queue
                        obj.CW = 4;                             % Reset CW to 4
                        if obj.numPackets > 0
                            obj.state = txStates.DIFS;          % If we have another packet, go straight to DIFS
                            obj.delay = const.DIFS;             % DIFS = 2 slots
                        else
                            obj.state = txStates.idle;          % Return to idle
                        end
                    end
                    
                otherwise
                    obj.state = txStates.idle;
            end
        end
    end
    
end