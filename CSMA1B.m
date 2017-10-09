addrA = 100;    % Random
addrB = 101;    % Arbitrary
addrC = 102;    % Unique Addresses
lambdaA = input('lambdaA? ');
lambdaC = input('lambdaC? ');
duration = input('duration? ');     % How many seconds to run, usually 10

txA = tx1(addrA, addrB, [addrA addrB]);     % Initialize txA
rxB = rx1(addrB, [addrA addrB addrC]);      % Initialize rxB
txC = tx1(addrC, addrB, [addrB addrC]);     % Initialize txC

trafficA = floor(50000*poissonTraffic(lambdaA, duration));    % Converted from seconds to slots
trafficC = floor(50000*poissonTraffic(lambdaC, duration));    % 1 second = 50000 slots

channel = [];   % Busy addresses in collision domain
ACK = [];       % ACKS being sent out this slot
rxers = [];     % Receivers being xmitted to this slot
slot = 0;
txB = [];       % Nodes currently xmitting to B
TA = size(trafficA, 2); % Number of transmissions by txA
TC = size(trafficC, 2); % Number of transmissions by txC
N = 0;          % Number of collisions
collision = 0;

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

    if (collision == 0) && (rxB.state == "collision")       % New collision
        collision = 1;
        N = N + 1;
    elseif (collision == 1) && (rxB.state ~= "collision")   % Wait for old collision to clear
        collision = 0;
    end

    channel = [xmitA xmitB xmitC];    % Update channel

    txB = [];   % Who is xmitting to rxB?
    if rxA == addrB
        txB = [txB addrA];
    end
    if rxC == addrB
        txB = [txB addrC];
    end

    ACK = ACKB;                      % Update ACKs
    slot = slot + 1;
%    fprintf("%s %s %s\n", txA.state, rxB.state, txC.state);
%    fprintf("%d ", channel);
%    fprintf("-");
%    fprintf(" %d", ACK);
%    fprintf("\n");
end

TA = TA - txA.numPackets;
TC = TC - txC.numPackets;

fprintf("Throughput of txA: %f Kbps\n", 1500*8*TA/(duration*1000));
fprintf("Throughput of txC: %f Kbps\n", 1500*8*TC/(duration*1000));
fprintf("Number of collisions: %d\n", N);