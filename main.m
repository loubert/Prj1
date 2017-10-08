txA = tx("idle", 0, 4, 0, 0);
txC = tx("idle", 0, 4, 0, 0);

lambdaA = 50;
lambdaC = 100;

trafficA = floor(500000*poissonTraffic(lambdaA, 10));
trafficC = floor(500000*poissonTraffic(lambdaC, 10));

channelA = "idle";
channelC = "idle";
ACK = 0;
slot = 0;
collision = 0;
while(slot < 1000)  % 10 seconds = 500,000 slots
    if ~isempty(trafficA)
        if trafficA(1) < slot
            txA.numPackets = txA.numPackets + 1;
            trafficA = trafficA(2:end);
        end
    end
    txA.update(channelA, ACK);

    if ~isempty(trafficC)
        if trafficC(1) < slot
            txB.numPackets = txC.numPackets + 1;
            trafficC = trafficC(2:end);
        end
    end
    txB.update(channelC, ACK);

    if (txA.state == "frame") && (txC.state == "frame")
        collision = 1;
    elseif (txA.state == "frame") && ~(txC.state == "frame")

    end
    slot = slot + 1;
end