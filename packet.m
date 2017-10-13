classdef packet < handle
    % tx2 Implements a single slot of a transmission

    properties
        origin      % Origin address of packet
        dest        % Destination address of packet
        domain      % Collision domain of packet
        type        % Type of packet (eg. ACK, DATA, RTS, CTS)
        length      % Numerical value of packet (for NAV)
    end
    
    methods
        function obj = packet(origin, dest, domain, type, length)
            obj.origin = [];
            obj.dest = [];
            obj.domain = [];
            obj.type = pktTypes.idle;
            obj.length = 0;
            if nargin > 0
                obj.origin = origin;
            end
            if nargin > 1
                obj.dest = dest;
            end
            if nargin > 2
                obj.domain = domain;
            end
            if nargin > 3
                obj.type = type;
            end
            if nargin > 4
                obj.length = length;
            end
        end
        
        function [] = update(obj, pktIn)
            if obj.type == pktTypes.idle
                obj.origin = pktIn.origin;
                obj.dest = pktIn.dest;
                obj.domain = pktIn.domain;
                obj.type = pktIn.type;
                obj.length = pktIn.length;
            else
                obj.origin = [];
                obj.dest = [];
                obj.domain = [];
                obj.type = pktTypes.collision;
                obj.length = 0;
            end
        end
    end
end