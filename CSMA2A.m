addrA = 100;    % Random
addrB = 101;    % Arbitrary
addrC = 102;    % Unique
addrD = 103;    % Addresses
lambdaA = input('lambdaA? ');
lambdaC = input('lambdaC? ');
duration = input('duration (seconds)? ');     % How many seconds to run, usually 10

txA = tx2(addrA, addrB, [addrA addrB addrC addrD]);     % Initialize txA
rxB = rx2(addrB, [addrA addrB addrC addrD]);            % Initialize rxB
txC = tx2(addrC, addrD, [addrA addrB addrC addrD]);     % Initialize txC
rxD = rx2(addrD, [addrA addrB addrC addrD]);            % Initialize rxD

trafficA = floor(50000*poissonTraffic(lambdaA, duration));    % Converted from seconds to slots
trafficC = floor(50000*poissonTraffic(lambdaC, duration));    % 1 second = 50000 slots

pAin = packet();    % Packet seen by A
pBin = packet();    % Packet seen by B
pCin = packet();    % Packet seen by C
pDin = packet();    % Packet seen by D
pAout = packet();   % Packet produced by A
pBout = packet();   % Packet produced by B
pCout = packet();   % Packet produced by C
pDout = packet();   % Packet produced by D
slot = 0;
TA = size(trafficA, 2); % Number of transmissions by txA
TC = size(trafficC, 2); % Number of transmissions by txC
coll = 0;       % Is there an ongoing collision
N = 0;          % Number of collisions
FIAB = 0;       % Amount of time channel is occupied by A -> B
FICD = 0;       % Amount of time channel is occupied by C -> D

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
    pDout = rxD.update(pDin);       % Update rxD

    pAin = packet();    % Packet seen by A
    pBin = packet();    % Packet seen by B
    pCin = packet();    % Packet seen by C
    pDin = packet();    % Packet seen by D

    for p = [pAout pBout pCout pDout]
        for i = p.domain  % Update txA's collision domain with its packet
            switch i
                case addrA
                    pAin.update(p);
                case addrB
                    pBin.update(p);
                case addrC
                    pCin.update(p);
                case addrD
                    pDin.update(p);
            end
        end
    end
    
    if (coll == 0) && ((pBin.type == pktTypes.collision) ||...  % New collision
            (pDin.type == pktTypes.collision))
        coll = 1;
        N = N + 1;
    elseif (coll == 1) && (pBin.type ~= pktTypes.collision) &&...  % Wait for old collision to clear
            (pDin.type ~= pktTypes.collision)
        coll = 0;
    end
    
    if (txA.state == txStates.DATA && rxB.state == rxStates.DATA) || ...    % A is xmitting to B, or
            (txA.state == txStates.waitACK && rxB.state == rxStates.ACK)    % B is xmitting to A
        FIAB = FIAB + 1;
    elseif (txC.state == txStates.DATA && rxD.state == rxStates.DATA) || ...% C is xmitting to D, or
            (txC.state == txStates.waitACK && rxD.state == rxStates.ACK)    % D is xmitting to C
        FICD = FICD + 1;
    end

    slot = slot + 1;
%     fprintf("%s %s %s %s\n", txA.state, rxB.state, txC.state, rxD.state);
%     fprintf("%s %s %s %s\n", pAin.type, pBin.type, pCin.type, pDin.type);
%     fprintf("%d %d %d %d\n", pAin.dest, pBin.dest, pCin.dest, pDin.dest);
end

TA = TA - txA.numPackets;
TC = TC - txC.numPackets;

fprintf("Throughput of txA: %f Kbps\n", 1500*8*TA/(duration*1000));
fprintf("Throughput of txC: %f Kbps\n", 1500*8*TC/(duration*1000));
fprintf("Number of collisions: %d\n", N);
fprintf("Fairness Index: %f\n", FIAB/FICD);