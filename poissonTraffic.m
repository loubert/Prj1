function [trafficStream] = poissonTraffic(lambda, endTime)
%poissonTraffic Generates Poisson traffic
    time = 0;
    trafficStream = [];
    while time < endTime
        trafficStream = [trafficStream, time];
        U = rand;
        X = -(1/lambda) * log(1 - U);
        time = time + X;
    end
    trafficStream = trafficStream(2:end);
end

