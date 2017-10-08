classdef tx < handle
    
    properties
        state       % Current state of xmitter
        delay       % Current amount of DIFS/SIFS/ACK/frame delay
        CW          % Contention window max width
        backoff     % Current backoff value
        numPackets  % Number of packets ready to xmit
        xmitting    % Are we currently xmitting?
    end
    
    methods
        function obj = tx(state, delay, CW, backoff, numPackets, xmitting)
            obj.state = "idle";
            obj.delay = 0;
            obj.CW = 4;
            obj.backoff = 0;
            obj.numPackets = 0;
            obj.xmitting = 0;
            if nargin > 0
                obj.state = state;
            end
            if nargin > 1
                obj.delay = delay;
            end
            if nargin > 2
                obj.CW = CW;
            end
            if nargin > 3
                obj.backoff = backoff;
            end
            if nargin > 4
                obj.numPackets = numPackets;
            end
            if nargin > 5
                obj.xmitting = xmitting;
            end
        end
        function [] = update(obj, channel, isACK)   % channel={"idle","busy"),isACK={0,1}
            switch obj.state
                case "idle"                     % not preparing to xmit
                    if((channel == "idle") && obj.numPackets > 0) % Ready to xmit
                        obj.state = "txDIFS";   % Start DIFS timer
                        obj.delay = 2;          % DIFS = 2 slots
                    end
                    
                case "txDIFS"                   % Sensing channel for DIFS time
                    if(channel == "busy")       % Channel became busy
                        obj.state = "idle";     % Start over
                    else
                        obj.delay = obj.delay - 1;
                        if obj.delay == 0                       % DIFS ended
                            obj.backoff = randi([0 obj.CW-1]);  % Select backoff
                            if obj.backoff == 0                 % Backoff of 0 selected
                                obj.xmitting = 1;       % We are xmitting
                                obj.state = "frame";    % Start sending the frame
                                obj.delay = 100;        % Frame size = 100 slots
                            else
                                obj.state = "bo";       % Start backoff phase
                            end
                        end
                    end
                    
                case "bo"       % Backing off
                    if channel == "idle"                % Channel is still idle
                        obj.backoff = obj.backoff - 1;  % Keep backing off
                        if obj.backoff == 0
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
                        obj.xmitting = 0;               % Stop transmitting
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
                        if isACK == 1                               % ACK successfully received
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

