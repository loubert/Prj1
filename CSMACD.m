addrA = 100;
addrB = 101;
addrC = 102;
addrD = 103;
lambdaA = 50;
lambdaC = 100;

txA = txCSMACD(addrA, addrB, [addrA addrB addrC addrD]);
rxB = rxCSMACD(addrB, [addrA addrB addrC addrD]);
txC = txCSMACD(addrC, addrD, [addrA addrB addrC addrD]);
rxD = rxCSMACD(addrD, [addrA addrB addrC addrD]);

trafficA = floor(500000*poissonTraffic(lambdaA, 10));   % Converted from seconds to slots
trafficC = floor(500000*poissonTraffic(lambdaC, 10));

channel = [];   % Busy addresses in collision domain
ACK = [];       % ACKS being sent out this slot
rxers = [];     % Receivers being xmitted to this slot
slot = 0;
txB = [];       % Nodes currently xmitting to B
txD = [];       % Nodes currently xmitting to D
while(slot < 10000)  % 10 seconds = 500,000 slots
    while ~isempty(trafficA) && trafficA(1) < slot
        txA.numPackets = txA.numPackets + 1;
        trafficA = trafficA(2:end);
    end
    [xmitA, rxA] = txA.update(channel, ACK);

    [xmitB, ACKB] = rxB.update(channel, txB);
    
    while ~isempty(trafficC) && trafficC(1) < slot
        txC.numPackets = txC.numPackets + 1;
        trafficC = trafficC(2:end);
    end
    [xmitC, rxC] = txC.update(channel, ACK);

    [xmitD, ACKD] = rxD.update(channel, txD);

    channel = [xmitA xmitB xmitC xmitD];    % Update channel

    txB = [];
    txD = [];
    if rxA == addrB
        txB = [txB addrA];
    elseif rxA == addrD
        txD = [txD addrA];
    end
    if rxC == addrB
        txB = [txB addrC];
    elseif rxC == addrD
        txD = [txD addrC];
    end

    ACK = [ACKB ACKD];                      % Update ACKs
    slot = slot + 1;
    fprintf("%s %s %s %s\n",txA.state,rxB.state,txC.state,rxD.state);
end