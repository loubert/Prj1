addrA = 100;    % Random
addrB = 101;    % Arbitrary
addrC = 102;    % Unique Addresses
% lambdaA = input('lambdaA? ');
% lambdaC = input('lambdaC? ');
% duration = input('duration (seconds)? ');     % How many seconds to run, usually 10

txA = tx2(addrA, addrB, [addrA addrB]);     % Initialize txA
rxB = rx2(addrB, [addrA addrB addrC]);      % Initialize rxB
txC = tx2(addrC, addrB, [addrB addrC]);     % Initialize txC

trafficA = floor(50000*poissonTraffic(lambdaA, duration));    % Converted from seconds to slots
trafficC = floor(50000*poissonTraffic(lambdaC, duration));    % 1 second = 50000 slots

pAin = packet();    % Packet seen by A
pBin = packet();    % Packet seen by B
pCin = packet();    % Packet seen by C
pAout = packet();   % Packet produced by A
pBout = packet();   % Packet produced by B
pCout = packet();   % Packet produced by C
slot = 0;
TA = size(trafficA, 2); % Number of packets arrived at txA
TC = size(trafficC, 2); % Number of packets arrived at txC
coll = 0;       % Is there an ongoing collision
N = 0;          % Number of collisions
FIAB = 0;       % Amount of time channel is occupied by A -> B
FICB = 0;       % Amount of time channel is occupied by C -> B

while(slot < 50000*duration)  % 1 second = 50,000 slots
    while ~isempty(trafficA) && trafficA(1) < slot  % Next packet arrival occured in previous slot
        txA.numPackets = txA.numPackets + 1;        % Update packets ready to tx in txA
        trafficA = trafficA(2:end);
    end
    while ~isempty(trafficC) && trafficC(1) < slot  % Next packet arrival occured in previous slot
        txC.numPackets = txC.numPackets + 1;        % Update packets ready to tx in txC
        trafficC = trafficC(2:end);
    end

    pAout = txA.update(pAin);       % Update txA
    pBout = rxB.update(pBin);       % Update rxB
    pCout = txC.update(pCin);       % Update txC

    pAin = packet();    % Packet seen by A
    pBin = packet();    % Packet seen by B
    pCin = packet();    % Packet seen by C

    for p = [pAout pBout pCout]
        for i = p.domain  % Update collision domain with packet
            switch i
                case addrA
                    pAin.update(p);
                case addrB
                    pBin.update(p);
                case addrC
                    pCin.update(p);
            end
        end
    end
    
    if (coll == 0) && (pBin.type == pktTypes.collision) % New collision
        coll = 1;
        N = N + 1;
    elseif (coll == 1) && (pBin.type ~= pktTypes.collision)  % Wait for old collision to clear
        coll = 0;
    end
    
    if (txA.state == txStates.DATA && rxB.state == rxStates.DATA) || ...    % A is xmitting to B, or
            (txA.state == txStates.waitACK && rxB.state == rxStates.ACK)    % B is xmitting to A
        FIAB = FIAB + 1;
    elseif (txC.state == txStates.DATA && rxB.state == rxStates.DATA) || ...% C is xmitting to D, or
            (txC.state == txStates.waitACK && rxB.state == rxStates.ACK)    % D is xmitting to C
        FICB = FICB + 1;
    end

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
fprintf("Fairness Index: %f\n", FIAB/FICB);