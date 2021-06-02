%% Import af vandloebsdata
opts = spreadsheetImportOptions("NumVariables", 3);

% Specify sheet and range
opts.Sheet = "Ark1";
opts.DataRange = "B3:D367";

% Specify column names and types
opts.VariableNames = ["Qm3d", "cDINgm3", "cDIPgm3"];
opts.VariableTypes = ["double", "double", "double"];

% Import the data
Q50 = readtable("Q-C_tidsserie_2019to2050.xlsx", opts, "UseExcel", false);
Q50=table2array(Q50);

%% Oprettelse af vandloebsdata
tid_dag =[datetime('01-Jan-2050 00:00:00'):datetime('31-Dec-2050 00:00:00')]';

first_day = datenum('01-Jan-2050 00:00:00');
last_day = datenum('01-Jan-2051 00:00:00');
xt = datenum(2050, 01, 01,[0:(last_day-first_day)*24-1].',0,0);
tid = datetime(xt,'ConvertFrom','datenum');

%Forlængelse af importerede vandløbsdata, sådan at er der 24 elementer af
%hver værdi, angivet i [m3/d] (for Q) og [g/m3] for koncentrationer
for i = 1:length(Q50)
    Q_vlb = (repelem(Q50(:,1),24,1));
    C_V_DIN = repelem(Q50(:,2),24,1);
    C_V_DIP = repelem(Q50(:,3),24,1);
end

%% Indsaettelse af barriere
% Undersoegs nul-scenarieret skal linje 35-39 udkommenteres
barrier=ones(length(tid),1);
% for i = 2:length(tid)
%     if tid(i) >='29-Oct-2050 05:00:00' && tid(i)<='29-Oct-2050 09:00:00' || tid(i) >='06-Dec-2050 04:00:00' && tid(i)<='07-Dec-2050 02:00:00'
%        barrier(i)=0;
%     end
% end

%% Udregning af udveksling og frafoersel m. Kattegat
Q=zeros(length(tid),1);
q=zeros(length(tid),1);

Sf=14.94; %promille
Sh=25.36; %promille
V=233838245.5; %m^3
dt=1/24; %dag

for i=1:length(tid)
    if barrier(i)==1
        Q(i)=Q_vlb(i);
        q(i)=Q(i)*(Sf/(Sh-Sf));
    end
end
        
%% Intialbetingelser for Kattegat
%Uorganisk N og P i havet
C_DIN_h =([repelem(82.5,31,1);repelem(89.6,28,1);repelem(4.5,31,1);repelem(8.9,30,1);repelem(4.75,31,1);repelem(5.7,30,1); ...
repelem(5.6,31,1);repelem(6.2,31,1);repelem(4.5,30,1);repelem(10.3,31,1);repelem(34.7,30,1);repelem(73.5,31,1)])./1000; %g/m3

C_DIP_h =([repelem(19,31,1);repelem(17.8,28,1);repelem(1.9,31,1);repelem(2,30,1);repelem(1.8,31,1);repelem(1,30,1); ...
repelem(1.67,31,1);repelem(1,31,1);repelem(1.03,30,1);repelem(6.2,31,1);repelem(11.4,30,1);repelem(16,31,1)])./1000; %g/m3

for i = length(C_DIN_h)
    C_DIN_hav = repelem(C_DIN_h(:,1),24,1);
    C_DIP_hav = repelem(C_DIP_h(:,1),24,1);
end
    
%Organisk N og P i havet
C_ON_h=([repelem(132.5,31,1);repelem(174.4,28,1);repelem(175.5,31,1);repelem(194.43,30,1);repelem(205.25,31,1);repelem(199.3,30,1); ...
repelem(99.37,31,1);repelem(188.85,31,1);repelem(170.5,30,1);repelem(139.7,31,1);repelem(143.26,30,1);repelem(124.05,31,1)])./1000; %g/m3

C_OP_h=([repelem(7,31,1);repelem(8.4,28,1);repelem(10.1,31,1);repelem(9.38,30,1);repelem(13.2,31,1);repelem(8.15,30,1); ...
    repelem(8.68,31,1);repelem(9.5,31,1);repelem(9.375,30,1);repelem(13.3,31,1);repelem(9.6,30,1);repelem(9.75,31,1)])./1000; %g/m3

for i = length(C_ON_h)
    C_alg_N_hav = repelem(C_ON_h(:,1),24,1);
    C_alg_P_hav = repelem(C_OP_h(:,1),24,1);
end

%% Specifikke vækstrate og halvmætningens konstant
mu=0.3; %1/dag 
K_N=0.2; %g/m^3 
K_P=0.003; %g/m^3 

%Kalibrerings faktorer
K_SED=0.09; %1/dag 
K_MIN_S_N=0.018; %1/dag 
K_MIN_V_A=0.006; %1/dag 
K_DENIT=0.048; %1/dag 
K_MIN_S_P=0.045; %1/dag 

%Redfield ratio
Red=7.235;

% Reduktions tests
C_DIN=[0.2467;zeros(length(tid)-1,1)];
C_DIP=[0.0474;zeros(length(tid)-1,1)];
C_A=[0.0036;zeros(length(tid)-1,1)];
M_S_N=[9.5097e+05;zeros(length(tid)-1,1)];
M_S_P=[2.5861e+05;zeros(length(tid)-1,1)];

PP=zeros(length(tid),1);
SED=zeros(length(tid),1);
MIN_V_A=zeros(length(tid),1);
MIN_S_DIN=zeros(length(tid),1);
MIN_S_DIP=zeros(length(tid),1);
DENIT=zeros(length(tid),1);

M_V_DIN=zeros(length(tid),1);
M_q_DIN=zeros(length(tid),1);
M_Q_DIN=zeros(length(tid),1);
M_q_DIN_h=zeros(length(tid),1);
M_Q_A=zeros(length(tid),1);
M_q_A=zeros(length(tid),1);
M_q_ON_h=zeros(length(tid),1);

M_V_DIP=zeros(length(tid),1);
M_q_DIP=zeros(length(tid),1);
M_Q_DIP=zeros(length(tid),1);
M_q_DIN_h=zeros(length(tid),1);
M_q_OP_h=zeros(length(tid),1);

%% Beregninger 
for i=2:length(tid)
    if tid(i) >='01-Mar-2050 00:00:00' && tid(i) <='01-Oct-2050 00:00:00'
        PP(i)=(mu*C_A(i-1)*(C_DIN(i-1)/(K_N+C_DIN(i-1)))*(C_DIP(i-1)/(K_P+C_DIP(i-1)))).*V;
    end
    %Mellemregninger for kvælstof
    SED(i)=K_SED.*C_A(i-1).*V;
    MIN_V_A(i)=K_MIN_V_A.*C_A(i-1).*V;
    MIN_S_DIN(i)=K_MIN_S_N.*M_S_N(i-1);
    DENIT(i)=K_DENIT.*M_S_N(i-1);
    
    M_V_DIN(i)=Q_vlb(i)*C_V_DIN(i);                    
    M_q_DIN(i)=C_DIN(i-1)*q(i);
    M_Q_DIN(i)=C_DIN(i-1)*Q(i); 
    M_q_DIN_h(i)=C_DIN_hav(i)*q(i); 
    M_Q_A(i)=C_A(i-1)*Q(i);
    M_q_A(i)=C_A(i-1)*q(i); 
    M_q_ON_h(i)=C_alg_N_hav(i)*q(i); 
    
    %Mellemregninger for Fosfor
    
    MIN_S_DIP(i)=K_MIN_S_P.*M_S_P(i-1)';
    
    M_V_DIP(i)=Q_vlb(i)*C_V_DIP(i);                    
    M_q_DIP(i)=C_DIP(i-1)*q(i); 
    M_Q_DIP(i)=C_DIP(i-1)*Q(i); 
    M_q_DIN_h(i)=C_DIP_hav(i)*q(i); 
    M_q_OP_h(i)=C_alg_P_hav(i)*q(i); 
    
    %massebalancer
    C_A(i)=(PP(i)+M_q_ON_h(i)+M_q_OP_h(i)-M_Q_A(i)-M_q_A(i)-SED(i)-MIN_V_A(i))*(dt/V)+C_A(i-1);
        
    C_DIN(i)=(M_V_DIN(i)+MIN_S_DIN(i)+(1-(1/Red))*MIN_V_A(i)+M_q_DIN_h(i)-M_Q_DIN(i)-M_q_DIN(i)-(1-(1/Red))*PP(i))*(dt/V)+C_DIN(i-1);
    
    C_DIP(i)=(M_V_DIP(i)+MIN_S_DIP(i)+(1/Red)*MIN_V_A(i)+M_q_DIN_h(i)-M_Q_DIP(i)-M_q_DIP(i)-(1/Red)*PP(i))*(dt/V)+C_DIP(i-1);
    
    M_S_N(i)=((1-(1/Red))*SED(i)-MIN_S_DIN(i)-DENIT(i))*dt+M_S_N(i-1);
    
    M_S_P(i)=((1/Red)*SED(i)-MIN_S_DIP(i))*dt+M_S_P(i-1);
end

%% C:Chl forhold (Jakobsen & Markager, 2016)
% Årsvariation i forholdet mellem C:Chl a - Bestemt ud fra Jakobsen &
% Markager, 2016

%Værdier fra Mariager Fjord (table 1 i artikel)
amp = 8.5; %Sommer amplituden for C:Chl
win = 33; % Vinter minimum C:Ch2l
peak = -1; %Tidslig placering af summer peak, relativ til 1. juli

%Funktionen 
C2Chl_func = @(x) win+amp*((cos(((x-0.5-peak)/12)*2*pi-pi)+1)/2);

%x-værdier (modellen arbejder med conventionelle tal for månederne, dvs.
%januar = 1, december = 12 - Sikre at værdierne findes på månedsbasis, som
%representere midten af måneden

C2Chla = C2Chl_func(1:0.0012558: 12)';

%% Omregning fra biomasse til C, og fra C til Chl
ca_N = C_A.*(1-(1/Red));
Red_C2N = 5.68; %[g C/g N]
org_C_N = ca_N.*Red_C2N;
Chl = org_C_N./C2Chla;

%% AAlegraesdybde og klorofyl a
Total_N = ca_N+C_DIN;
mean_Total_N = mean(Total_N).*1000; %µg/L

laurentius_type1 = exp(5.257 - 0.673*log(mean_Total_N));
laurentius_type2 = exp(7.253 - 0.993*log(mean_Total_N));

mean_total_chl = (mean(Chl(2881:6552,1).*1000));