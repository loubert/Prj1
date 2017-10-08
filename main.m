txA = tx("idle", 0, 4, 0, 0);
txC = tx("idle", 0, 4, 0, 0);

lambdaA = 50;
lambdaC = 100;

trafficA = floor(500000*poissonTraffic(lambdaA, 10));
trafficC = floor(500000*poissonTraffic(lambdaC, 10));

channelA = "idle";
channelC = "idle";
rcvrState = "wait";
ACK = 0;
slot = 0;
collision = 0;
while(slot < 1000)  % 10 seconds = 500,000 slots
    while ~isempty(trafficA) && trafficA(1) < slot
        txA.numPackets = txA.numPackets + 1;
        trafficA = trafficA(2:end);
    end
    txA.update(channelA, ACK);

    if ~isempty(trafficC)
        if trafficC(1) < slot
            txC.numPackets = txC.numPackets + 1;
            trafficC = trafficC(2:end);
        end
    end
    txC.update(channelC, ACK);

    % switch txA.state
    switch rcvrState
        case "wait"
            if (txA.state == "frame") && (txC.state == "frame")
                rcvrState = "collision";
                channelA = "busy";
                channelC = "busy";
            elseif (txA.state == "frame") && ~(txC.state == "frame")
                rcvrState = "rx";
                channelA = "busy";
                channelC = "busy";
            elseif ~(txA.state == "frame") && (txC.state == "frame")
                rcvrState = "rx";
                channelA = "busy";
                channelC = "busy";
            elseif ~(txA.state == "frame") && ~(txC.state == "frame")
                rcvrState = "wait";
                channelA = "idle";
                channelC = "idle";
            end
        case "collision"
        case "rx"
            
        case "rxSIFS"
            
        case "ACK"
            
        otherwise
            
    end

    slot = slot + 1;
end