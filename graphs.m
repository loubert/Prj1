TA_SAI1eq = zeros([1 4]);
TA_SBI1eq = zeros([1 4]);
TA_SAI2eq = zeros([1 4]);
TA_SBI2eq = zeros([1 4]);
TC_SAI1eq = zeros([1 4]);
TC_SBI1eq = zeros([1 4]);
TC_SAI2eq = zeros([1 4]);
TC_SBI2eq = zeros([1 4]);
N_SAI1eq = zeros([1 4]);
N_SBI1eq = zeros([1 4]);
N_SAI2eq = zeros([1 4]);
N_SBI2eq = zeros([1 4]);
FI_SAI1eq = zeros([1 4]);
FI_SBI1eq = zeros([1 4]);
FI_SAI2eq = zeros([1 4]);
FI_SBI2eq = zeros([1 4]);

TA_SAI1ne = zeros([1 4]);
TA_SBI1ne = zeros([1 4]);
TA_SAI2ne = zeros([1 4]);
TA_SBI2ne = zeros([1 4]);
TC_SAI1ne = zeros([1 4]);
TC_SBI1ne = zeros([1 4]);
TC_SAI2ne = zeros([1 4]);
TC_SBI2ne = zeros([1 4]);
N_SAI1ne = zeros([1 4]);
N_SBI1ne = zeros([1 4]);
N_SAI2ne = zeros([1 4]);
N_SBI2ne = zeros([1 4]);
FI_SAI1ne = zeros([1 4]);
FI_SBI1ne = zeros([1 4]);
FI_SAI2ne = zeros([1 4]);
FI_SBI2ne = zeros([1 4]);

for i = 0:3
    TA_SAI1eq(i+1) = TAtot(8*i+1);
    TA_SBI1eq(i+1) = TAtot(8*i+2);
    TA_SAI2eq(i+1) = TAtot(8*i+3);
    TA_SBI2eq(i+1) = TAtot(8*i+4);
    TC_SAI1eq(i+1) = TCtot(8*i+1);
    TC_SBI1eq(i+1) = TCtot(8*i+2);
    TC_SAI2eq(i+1) = TCtot(8*i+3);
    TC_SBI2eq(i+1) = TCtot(8*i+4);
    N_SAI1eq(i+1) = Ntot(8*i+1);
    N_SBI1eq(i+1) = Ntot(8*i+2);
    N_SAI2eq(i+1) = Ntot(8*i+3);
    N_SBI2eq(i+1) = Ntot(8*i+4);
    FI_SAI1eq(i+1) = FItot(8*i+1);
    FI_SBI1eq(i+1) = FItot(8*i+2);
    FI_SAI2eq(i+1) = FItot(8*i+3);
    FI_SBI2eq(i+1) = FItot(8*i+4);
end

for i = 0:3
    TA_SAI1ne(i+1) = TAtot(8*i+5);
    TA_SBI1ne(i+1) = TAtot(8*i+6);
    TA_SAI2ne(i+1) = TAtot(8*i+7);
    TA_SBI2ne(i+1) = TAtot(8*i+8);
    TC_SAI1ne(i+1) = TCtot(8*i+5);
    TC_SBI1ne(i+1) = TCtot(8*i+6);
    TC_SAI2ne(i+1) = TCtot(8*i+7);
    TC_SBI2ne(i+1) = TCtot(8*i+8);
    N_SAI1ne(i+1) = Ntot(8*i+5);
    N_SBI1ne(i+1) = Ntot(8*i+6);
    N_SAI2ne(i+1) = Ntot(8*i+7);
    N_SBI2ne(i+1) = Ntot(8*i+8);
    FI_SAI1ne(i+1) = FItot(8*i+5);
    FI_SBI1ne(i+1) = FItot(8*i+6);
    FI_SAI2ne(i+1) = FItot(8*i+7);
    FI_SBI2ne(i+1) = FItot(8*i+8);
end

lambdas = [50 100 200 300];

close all;

set(0,'defaulttextinterpreter','latex'); % allows you to use latex math
set(0,'defaultlinelinewidth',2); % line width is set to 2
set(0,'DefaultLineMarkerSize',10); % marker size is set to 10
set(0,'DefaultTextFontSize', 16); % Font size is set to 16
set(0,'DefaultAxesFontSize',16); % font size for the axes is set to 16

figure(1);
plot(lambdas, TA_SAI1eq, '-bo', ...
    lambdas, TA_SBI1eq, '-rs',...
    lambdas, TA_SAI2eq, '-g+',...
    lambdas, TA_SBI2eq, '-kd');
grid on; % grid lines on the plot
legend('CSMA', 'CSMA (hidden terminal)', 'CSMA/VCS',...
    'CSMA/VCS (hidden terminal)');
ylabel('$T$ (Kbps)');
xlabel('$\lambda$ (frames/sec)');
title("Throughput of A ($\lambda_A = \lambda_C$)");

figure(2);
plot(lambdas, TC_SAI1eq, '-bo', ...
    lambdas, TC_SBI1eq, '-rs',...
    lambdas, TC_SAI2eq, '-g+',...
    lambdas, TC_SBI2eq, '-kd');
grid on; % grid lines on the plot
legend('CSMA', 'CSMA (hidden terminal)', 'CSMA/VCS',...
    'CSMA/VCS (hidden terminal)');
ylabel('$T$ (Kbps)');
xlabel('$\lambda$ (frames/sec)');
title("Throughput of C ($\lambda_A = \lambda_C$)");

figure(3);
plot(lambdas, TA_SAI1ne, '-bo', ...
    lambdas, TA_SBI1ne, '-rs',...
    lambdas, TA_SAI2ne, '-g+',...
    lambdas, TA_SBI2ne, '-kd');
grid on; % grid lines on the plot
legend('CSMA', 'CSMA (hidden terminal)', 'CSMA/VCS',...
    'CSMA/VCS (hidden terminal)');
ylabel('$T$ (Kbps)');
xlabel('$\lambda$ (frames/sec)');
title("Throughput of A ($\lambda_A \neq \lambda_C$)");

figure(4);
plot(lambdas, TC_SAI1ne, '-bo', ...
    lambdas, TC_SBI1ne, '-rs',...
    lambdas, TC_SAI2ne, '-g+',...
    lambdas, TC_SBI2ne, '-kd');
grid on; % grid lines on the plot
legend('CSMA', 'CSMA (hidden terminal)', 'CSMA/VCS',...
    'CSMA/VCS (hidden terminal)');
ylabel('$T$ (Kbps)');
xlabel('$\lambda$ (frames/sec)');
title("Throughput of C ($\lambda_A \neq \lambda_C$)");

figure(5);
plot(lambdas, N_SAI1eq, '-bo', ...
    lambdas, N_SBI1eq, '-rs',...
    lambdas, N_SAI2eq, '-g+',...
    lambdas, N_SBI2eq, '-kd');
grid on; % grid lines on the plot
legend('CSMA', 'CSMA (hidden terminal)', 'CSMA/VCS',...
    'CSMA/VCS (hidden terminal)');
ylabel('$N$');
xlabel('$\lambda$ (frames/sec)');
title("Number of collisions ($\lambda_A = \lambda_C$)");

figure(6);
plot(lambdas, N_SAI1ne, '-bo', ...
    lambdas, N_SBI1ne, '-rs',...
    lambdas, N_SAI2ne, '-g+',...
    lambdas, N_SBI2ne, '-kd');
grid on; % grid lines on the plot
legend('CSMA', 'CSMA (hidden terminal)', 'CSMA/VCS',...
    'CSMA/VCS (hidden terminal)');
ylabel('$N$');
xlabel('$\lambda$ (frames/sec)');
title("Number of collisions ($\lambda_A \neq \lambda_C$)");

figure(7);
plot(lambdas, FI_SAI1eq, '-bo', ...
    lambdas, FI_SBI1eq, '-rs',...
    lambdas, FI_SAI2eq, '-g+',...
    lambdas, FI_SBI2eq, '-kd');
grid on; % grid lines on the plot
legend('CSMA', 'CSMA (hidden terminal)', 'CSMA/VCS',...
    'CSMA/VCS (hidden terminal)');
ylabel('$FI$');
xlabel('$\lambda$ (frames/sec)');
title("Fairness Index ($\lambda_A = \lambda_C$)");

figure(8);
plot(lambdas, FI_SAI1ne, '-bo', ...
    lambdas, FI_SBI1ne, '-rs',...
    lambdas, FI_SAI2ne, '-g+',...
    lambdas, FI_SBI2ne, '-kd');
grid on; % grid lines on the plot
legend('CSMA', 'CSMA (hidden terminal)', 'CSMA/VCS',...
    'CSMA/VCS (hidden terminal)');
ylabel('$FI$');
xlabel('$\lambda$ (frames/sec)');
title("Fairness Index ($\lambda_A \neq \lambda_C$)");
