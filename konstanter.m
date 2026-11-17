%% Modellparametrar (från Tabell 2, omvandlade till SI-enheter)
clear; clc; close all;

% Fysikaliska konstanter
g = 9.81;               % Tyngdacceleration [m/s^2]
rho_luft = 1.225;       % Luftens densitet [kg/m^3] (vid 15°C)

% Hastighet, kurvradie och accelerationer
v_kmh_a = 5;             % Hastighet vid max acceleration vid låg fart
v_a = v_kmh_a / 3.6;        % Maxfart i SI-enhet [m/s]
R = 10;                 % Kurvradie: 5 - 15 [m]
a1 = 6;                 % Max acceleration [m/s^2]
a2 = 15;                % Max retardation (-a2 i formler) [m/s^2]

% Fordonets massa och aerodynamik
m = 150;                % Vikt inkl. förare: 100 - 200 [kg]
c = 0.30;               % Luftmotståndskoefficient: 0.2 - 0.4 [-]
A = 0.50;               % Frontarea: 0.4 - 0.6 [m^2]

% Tyngdpunktens läge (omvandlat från mm och cm till m)
df = 0.800;             % Avstånd framaxel till tyngdpunkt: 600 - 1000 mm -> [m]
db = 0.300;             % Avstånd bakaxel till tyngdpunkt: 200 - 400 mm -> [m]
h  = 0.45;              % Tyngdpunktens höjd: 30 - 60 cm -> [m]
h1 = 0.20;              % Avstånd TP till luftmotstånd (FL): 15 - 25 cm -> [m]

% Bakaxelns, hjulens och bromsarnas geometri (omvandlat från mm till m)
L  = 1.100;             % Bakaxellängd: 1000 - 1200 mm -> [m]
b1 = 0.150;             % Hjullagerposition: 100 - 200 mm -> [m]
dh = 0.320;             % Hjuldiameter: 240 - 400 mm -> [m]
bb = 0.080;             % Bromsskivornas position: < b1 [m]
rb = 0.30 * dh;         % Bromsbackens radie: < 0.35 * dh [m]

% Dimensionsövergång och säkerhetsfaktorer
rho1 = 0.002;           % Kälradie: 1 - 4 mm -> [m]
ns = 2.5;               % Säkerhetsfaktor mot plastisk deformation [-]
nu = 2.0;               % Säkerhetsfaktor mot utmattning [-]

% Materialdata (Dessa är värden för kolstål rad 4 tabell 33.1)

%För beräkning av diameter m.a.p plasticering
sigma_s = 250*10^6; %Maximala dragspänningen innan plasticering för kolstål rad 4 i formelsamling
tau_s = 160*10^6; %Maximala skjuvspänning innan plasticering får kolstål rad 4 i formelsamling
%D/d ≈ 1.67, vilket ger från Tabell 32.4 någonstant mellan 2.0 0ch 1.2
%K_tb fås beroende på vilken diameter D som nyligen itererades fram med
%newton.
K_tb = 2.0; %OBS, gäller bara för rho1 = 0.002
%Samma D/d och rho1/d som innan, men annat tabellvärde. 
%Iterera om för varje newton till konvergerar
K_tv = 1.6; %OBS, gäller bara för rho1 = 0.002

%För beräkning av diameter m.a.p utmattning
sigma_u = 140*10^6; %Från rad 4 tabell 33.1
R_m = 470*10^6; %Taget från tabell 33.1, rad 4, Brottgräns
A_neuber = 0.21*10^-3; %Taget från figur 25.8 mha brottgränsen
q = 1/(1 + sqrt(A_neuber/rho1)); %Kälkänslighetsfaktor q
K_tb_utm = 2.0;
K_f = 1+q*(K_tb_utm-1); %Anvisningsfaktor K_f