duration = 10;
for lambda = [50 100 200 300]
    for Amul = [1 2]
        lambdaA = lambda * Amul;
        lambdaC = lambda;
        fprintf("lambdaA = %d, lambdaC = %d\n", lambdaA, lambdaC);
        CSMA1A
        CSMA1B
        CSMA2A
        CSMA2B
    end
end