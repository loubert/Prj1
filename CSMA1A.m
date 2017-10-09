addrA = 100;    % Random
addrB = 101;    % Arbitrary
addrC = 102;    % Unique
addrD = 103;    % Addresses
lambdaA = input('lambdaA? ');
lambdaC = input('lambdaC? ');
duration = input('duration? ');     % How many seconds to run, usually 10

txA = tx1(addrA, addrB, [addrA addrB addrC addrD]);     % Initialize txA
rxB = rx1(addrB, [addrA addrB addrC addrD]);            % Initialize rxB
txC = tx1(addrC, addrD, [addrA addrB addrC addrD]);     % Initialize txC
rxD = rx1(addrD, [addrA addrB addrC addrD]);            % Initialize rxD

trafficA = floor(50000*poissonTraffic(lambdaA, duration));    % Converted from seconds to slots
trafficC = floor(50000*poissonTraffic(lambdaC, duration));    % 1 second = 50000 slots

channel = [];   % Busy addresses in collision domain
ACK = [];       % ACKS being sent out this slot
rxers = [];     % Receivers being xmitted to this slot
slot = 0;
txB = [];       % Nodes currently xmitting to B
txD = [];       % Nodes currently xmitting to D
TA = size(trafficA, 2); % Number of transmissions by txA
TC = size(trafficC, 2); % Number of transmissions by txC
N = 0;          % Number of collisions
collision = 0;
FIAB = 0;       % Amount of time channel is occupied by A -> B
FICD = 0;       % Amount of time channel is occupied by C -> D

while(slot < 50000*duration)  % 1 second = 50,000 slots
    while ~isempty(trafficA) && trafficA(1) < slot  % Next packet arrival occured in previous slot
        txA.numPackets = txA.numPackets + 1;        % Update packets ready to tx in txA
        trafficA = trafficA(2:end);
    end
    [xmitA, rxA] = txA.update(channel, ACK);        % Update txA

    [xmitB, ACKB] = rxB.update(channel, txB);       % Update rxB
    
    while ~isempty(trafficC) && trafficC(1) < slot  % Next packet arrival occured in previous slot
        txC.numPackets = txC.numPackets + 1;        % Update packets ready to tx in txC
        trafficC = trafficC(2:end);
    end
    [xmitC, rxC] = txC.update(channel, ACK);        % Update txC

    [xmitD, ACKD] = rxD.update(channel, txD);       % Update rxD

    if ismember(addrA, ACKB) && (rxB.state == rxStates.idle)        % txA receives ACK, rxB returns to idle
        TA = TA + 1;
    elseif ismember(addrC, ACKD) && (rxD.state == rxStates.idle)    % txC receives ACK, rxD returns to idle
        TC = TC + 1;
    end

    if (collision == 0) && ((rxB.state == "collision") || rxD.state == "collision")     % New collision
        collision = 1;
        N = N + 1;
    elseif (collision == 1) && (rxB.state ~= "collision") && (rxD.state ~= "collision") % Wait for old collision to clear
        collision = 0;
    end
    
    if (txA.state == txStates.frame && rxB.state == rxStates.receive) || ...    % A is xmitting to B, or
            (txA.state == txStates.waitACK && rxB.state == rxStates.ACK)        % B is xmitting to A
        FIAB = FIAB + 1;
    elseif (txC.state == txStates.frame && rxD.state == rxStates.receive) || ...% C is xmitting to D, or
            (txC.state == txStates.waitACK && rxD.state == rxStates.ACK)        % D is xmitting to C
        FICD = FICD + 1;
    end
    
    channel = [xmitA xmitB xmitC xmitD];    % Update channel

    txB = [];   % Who is xmitting to rxB?
    txD = [];   % Who is xmitting to rxD?
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
%     fprintf("%s %s %s %s\n", txA.state, rxB.state, txC.state, rxD.state);
%     fprintf("%d ", channel);
%     fprintf("-");
%     fprintf(" %d", ACK);
%     fprintf("\n");
end

TA = TA - txA.numPackets;
TC = TC - txC.numPackets;

fprintf("Throughput of txA: %f Kbps\n", 1500*8*TA/(duration*1000));
fprintf("Throughput of txC: %f Kbps\n", 1500*8*TC/(duration*1000));
fprintf("Number of collisions: %d\n", N);
fprintf("Fairness Index: %f\n", FIAB/FICD);

