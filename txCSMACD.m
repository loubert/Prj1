classdef txCSMACD < handle
    
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
        function obj = txCSMACD(addr, rx, domain)
            obj.addr = 1;
            obj.rx = 2;
            obj.domain = [1 2];
            obj.state = "idle";
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
                case "idle"                     % Not preparing to xmit
                    if(~ismember(obj.addr, channel) && obj.numPackets > 0)  % Ready to xmit
                        obj.state = "txDIFS";   % Start DIFS timer
                        obj.delay = 2;          % DIFS = 2 slots
                    end

                case "txDIFS"                       % Sensing channel for DIFS time
                    if ismember(obj.addr, channel)  % Channel became busy
                        obj.state = "idle";         % Start over
                    else
                        obj.delay = obj.delay - 1;
                        if obj.delay == 0                       % DIFS ended
                            obj.backoff = randi([0 obj.CW-1]);  % Select backoff
                            if obj.backoff == 0                 % Backoff of 0 selected
                                xmitTo = obj.domain;    % Xmit to collision domain
                                rx = obj.rx;            % Set our receiver address
                                obj.state = "frame";    % Start sending the frame
                                obj.delay = 100;        % Frame size = 100 slots
                            else
                                obj.state = "bo";       % Start backoff phase
                            end
                        end
                    end

                case "bo"       % Backing off
                    if ~ismember(obj.addr, channel)     % Channel is still idle
                        obj.backoff = obj.backoff - 1;  % Keep backing off
                        if obj.backoff == 0
                            xmitTo = obj.domain;    	% Xmit to collision domain
                            rx = obj.rx;                % Set our receiver address
                            obj.state = "frame";        % Start sending the frame
                            obj.delay = 100;            % Frame size = 100 slots
                        end
                    else                                % Channel is busy...
                        obj.state = "freeze";           % freeze
                        obj.delay = 100 + 1 + 2;        % Delay for packet size, SIFS, and ACK
                    end

                case "freeze"   % Freezing backoff
                    obj.delay = obj.delay - 1;
                    if obj.delay == 0                   % Packet, SIFS, ACK all done
                        obj.state = "bo";               % Resume backoff
                    end

                case "frame"
                    obj.delay = obj.delay - 1;
                    if obj.delay == 0
                        obj.state = "txSIFS";           % Transition to SIFS
                        obj.delay = 1;                  % SIFS = 1 slot
                    else
                        xmitTo = obj.domain;            % Xmit to collision domain
                        rx = obj.rx;                    % Set our receiver address
                    end

                case "txSIFS"
                    obj.delay = obj.delay - 1;
                    if obj.delay == 0
                        obj.state = "waitACK";          % Transition to waiting for ACK
                        obj.delay = 2;                  % ACK = 2 slots
                    end

                case "waitACK"
                    obj.delay = obj.delay - 1;
                    if obj.delay == 0
                        if ismember(obj.addr, ACK)                  % ACK successfully received
                            obj.numPackets = obj.numPackets - 1;    % Reduce packet queue
                            obj.CW = 4;                             % Reset CW to 4
                        elseif obj.CW < 1024                        % If CW is less than max...
                            obj.CW = obj.CW * 2;                    % double CW
                        end
                        obj.state = "idle";                         % Return to idle
                    end
                    
                otherwise
                    obj.state = "idle";
            end
        end
    end
    
end

