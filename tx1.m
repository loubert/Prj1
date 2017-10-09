classdef tx1 < handle
    % tx1 Implements CSMA/CA transmitter protocol 1

    properties
        addr        % Our address
        rx          % Address of our receiver
        domain      % Collision domain of xmitter
        state       % Current state of xmitter
        delay       % Current amount of DIFS/SIFS/ACK/frame delay
        CW          % Contention window max width
        backoff     % Current backoff value
        numPackets  % Number of packets ready to xmit
    end
    
    methods
        function obj = tx1(addr, rx, domain)
            obj.addr = 1;
            obj.rx = 2;
            obj.domain = [1 2];
            obj.state = txStates.idle;
            obj.delay = 0;
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

        function [xmitTo, rx] = update(obj, channel, ACK) % Return the channel state on next slot
            xmitTo = [];                        % By default, xmit to nobody
            rx = [];
            switch obj.state
                case txStates.idle              % Not preparing to xmit
                    if(~ismember(obj.addr, channel) && obj.numPackets > 0)  % Ready to xmit
                        obj.state = txStates.DIFS;  % Start DIFS timer
                        obj.delay = 2;              % DIFS = 2 slots
                    end

                case txStates.DIFS                  % Sensing channel for DIFS time
                    if ismember(obj.addr, channel)  % Channel became busy
                        obj.delay = 2;              % Start over
                    else
                        obj.delay = obj.delay - 1;
                        if obj.delay == 0                       % DIFS ended
                            obj.backoff = randi([0 obj.CW-1]);  % Select backoff
                            if obj.backoff == 0                 % Backoff of 0 selected
                                xmitTo = obj.domain;    % Xmit to collision domain
                                rx = obj.rx;            % Set our receiver address
                                obj.state = txStates.frame; % Start sending the frame
                                obj.delay = 100;        % Frame size = 100 slots
                            else
                                obj.state = txStates.bo;    % Start backoff phase
                            end
                        end
                    end

                case txStates.bo    % Backing off
                    if ~ismember(obj.addr, channel)     % Channel is still idle
                        obj.backoff = obj.backoff - 1;  % Keep backing off
                        if obj.backoff == 0
                            xmitTo = obj.domain;    	% Xmit to collision domain
                            rx = obj.rx;                % Set our receiver address
                            obj.state = txStates.frame; % Start sending the frame
                            obj.delay = 100;            % Frame size = 100 slots
                        end
                    else                                % Channel is busy...
                        obj.state = txStates.freeze;    % freeze
                        obj.delay = 2;                  % Resume backoff when channel is idle for DIFS time
                    end

                case txStates.freeze    % Freezing backoff
                    if ~ismember(obj.addr, channel)     % Channel is idle
                        obj.delay = obj.delay - 1;
                        if obj.delay == 0               % Channel has been idle for DIFS time
                            obj.state = txStates.bo;    % Resume backoff
                        end
                    else                                % Channel is busy, restart freeze
                        obj.delay = 2;
                    end

                case txStates.frame
                    obj.delay = obj.delay - 1;
                    if obj.delay == 0
                        obj.state = txStates.SIFS;      % Transition to SIFS
                        obj.delay = 1;                  % SIFS = 1 slot
                    else
                        xmitTo = obj.domain;            % Xmit to collision domain
                        rx = obj.rx;                    % Set our receiver address
                    end

                case txStates.SIFS
                    obj.delay = obj.delay - 1;
                    if obj.delay == 0
                        obj.state = txStates.waitACK;   % Transition to waiting for ACK
                        obj.delay = 2;                  % ACK = 2 slots
                    end

                case txStates.waitACK
                    obj.delay = obj.delay - 1;
                    if obj.delay == 0
                        if ismember(obj.addr, ACK)                  % ACK successfully received
                            obj.numPackets = obj.numPackets - 1;    % Reduce packet queue
                            obj.CW = 4;                             % Reset CW to 4
                        elseif obj.CW < 1024                        % If CW is less than max...
                            obj.CW = obj.CW * 2;                    % double CW
                        end
                        if obj.numPackets > 0
                            obj.state = txStates.DIFS;              % If we have another packet, go straight to DIFS
                            obj.delay = 2;                          % DIFS = 2 slots
                        else
                            obj.state = txStates.idle;              % Return to idle
                        end
                    end
                    
                otherwise
                    obj.state = txStates.idle;
            end
        end
    end
    
end