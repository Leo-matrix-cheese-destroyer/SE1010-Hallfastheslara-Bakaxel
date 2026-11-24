%% Lastfall C - kurvtagning med konstant fart
run('konstanter.m');

marginal = 0.01;         % Relativ marginal till fartgränsen
bd = L/2;               % Drivningens läge från innerhjulet [m]
med_drevkraft = false;
rd = [];                % Drevets delningsradie [m]

D_guess = 0.050;         % Provdiameter mellan lagren [m]
diameterkvot = 0.6;      % d/D
if ~exist('Kt_c','var')
    Kt_c = [];          % Hålkälens Kt för drag, böjning och vridning
end
if ~exist('K_tb_utm_c','var')
    K_tb_utm_c = [];    % Böjningens Kt för beräkning av Kf
end
visa_figurer = true;

assert(all([v_b R h b1 dh D_guess sigma_s sigma_u ns nu] > 0) && ...
    b1 < bd && bd < L-b1 && marginal > 0 && marginal < 1, ...
    'Kontrollera fart, geometri, hållfasthetsvärden och fartmarginal.');
assert(~med_drevkraft || (isscalar(rd) && isfinite(rd) && rd > 0), ...
    'Ange positiv delningsradie rd om drevkraften ska ingå.');
assert(isempty(Kt_c) || (isvector(Kt_c) && numel(Kt_c) == 3 && ...
    all(isfinite(Kt_c)) && all(Kt_c >= 1)), 'Ange tre Kt-värden på minst 1.');
assert(isempty(K_tb_utm_c) || (isscalar(K_tb_utm_c) && ...
    isfinite(K_tb_utm_c) && K_tb_utm_c >= 1), 'Ange ett Kt-värde på minst 1 för utmattning.');

%% Kurvfart och krafter på hjulen
r_h = dh/2;
hjulbas = df + db;
v_tipp = sqrt(g*R*L/(2*h));
gamma = (1-marginal)*min(1, v_tipp/v_b);
v_c = gamma*v_b;

F_c = m*v_c^2/R;
F_L = rho_luft*c*A*v_c^2/2;
F_D = F_L;
M_motor = F_D*r_h;
Fd = 0;
if med_drevkraft
    Fd = M_motor/rd;
end

N_B = (m*g*df + F_L*(h+h1))/hjulbas;
N_F = m*g - N_B;
V_i = m*g/2 - F_c*h/L;
V_y = m*g/2 + F_c*h/L;
assert(min([N_F N_B V_i V_y]) > 0, 'Valda indata ger förlorad hjulkontakt.');

% Index på hjulkrafterna: b = bak, f = fram, i = inner, y = ytter.
andel_i = V_i/(m*g);
andel_y = V_y/(m*g);
Vbi = N_B*andel_i;
Vby = N_B*andel_y;
Vfi = N_F*andel_i;
Vfy = N_F*andel_y;

H_B = F_c*df/hjulbas;
H_F = F_c - H_B;
Hbi = H_B*andel_i;
Hby = H_B*andel_y;
Hfi = H_F*andel_i;
Hfy = H_F*andel_y;

%% Lagerreaktioner
% x går från innerhjulet mot ytterhjulet, y framåt och z uppåt.
% Hbi och Hby verkar i -x vid marken och ger ett moment kring y.
b2 = L-b1;
lageravstand = b2-b1;

R_x1 = Hbi+Hby;          % Inre lagret tar hela axiallasten
R_x2 = 0;
R_y2 = -F_D/2 - Fd*(bd-b1)/lageravstand;
R_y1 = -(F_D + Fd + R_y2);
R_z2 = (b1*Vbi - b2*Vby + r_h*(Hbi+Hby))/lageravstand;
R_z1 = -(Vbi + Vby + R_z2);

%% Snittstorheter
% Dubbla ändpunkter ger vänster- och högergränsvärden vid lastpunkterna.
lastpunkter = [0 b1 bd b2 L];
n = 101;
del = [0 repelem(1:4,n) 5];
x = zeros(size(del));
x(end) = L;
for k = 1:4
    intervall = 2+(k-1)*n:1+k*n;
    x(intervall) = linspace(lastpunkter(k),lastpunkter(k+1),n);
end

hjul_i = del >= 1;
lager_i = del >= 2;
motor = del >= 3;
lager_y = del >= 4;
hjul_y = del >= 5;
havarm_1 = max(0,x-b1);
havarm_2 = max(0,x-b2);
havarm_d = max(0,x-bd);

N = Hbi*hjul_i - R_x1*lager_i + Hby*hjul_y;
Ty = F_D/2*(double(hjul_i)+double(hjul_y)) + R_y1*lager_i + Fd*motor + R_y2*lager_y;
Tz = Vbi*hjul_i + R_z1*lager_i + R_z2*lager_y + Vby*hjul_y;
My = Vbi*x + R_z1*havarm_1 + R_z2*havarm_2 + r_h*(Hbi*hjul_i + Hby*hjul_y);
Mz = F_D/2*x + R_y1*havarm_1 + Fd*havarm_d + R_y2*havarm_2;
torque = M_motor*(double(motor) - (double(hjul_i)+double(hjul_y))/2);
Mb = hypot(My,Mz);

kraftskala = max([1 N_B H_B F_D+Fd]);
assert(max(abs([N(end) Ty(end) Tz(end)])) < 1e-10*kraftskala && ...
    max(abs([My(end) Mz(end) torque(end)])) < 1e-10*L*kraftskala, ...
    'Axelns kraft- och momentjämvikt sluter inte.');

%% Spänningar vid provdiametern
i_axel = 2:numel(x)-1;
i_and = sort([2+(0:3)*n, 1+(1:4)*n]);   % Delsträckornas ändsnitt
i_kal = [1+n, 2+3*n];                  % Hålkälarnas smala sida

d_rel = diameterkvot*ones(size(x));
d_rel(del == 2 | del == 3) = 1;
d_lokal = D_guess*d_rel;
A_axel = pi*d_lokal.^2/4;
sigma_N = N./A_axel;
sigma_b = 32*Mb./(pi*d_lokal.^3);
tau_T = 16*torque./(pi*d_lokal.^3);
tau_V = 4*hypot(Ty,Tz)./(3*A_axel);    % Maximal tvärkraftsskjuvning i centrum
sigma_eff = hypot(abs(sigma_N)+sigma_b,sqrt(3)*tau_T);  % Vid ytan
[Mb_max,k] = max(Mb(i_and));
x_Mb_max = x(i_and(k));
[sigma_eff_max,k] = max(sigma_eff(i_and));
x_sigma_eff_max = x(i_and(k));
[~,k] = max(sigma_b(i_and));
x_sigma_b_max = x(i_and(k));

%% Dimensionering för C
% Effektivspänningen är konvex längs varje delsträcka, så max finns i ett ändsnitt.
% Spänningarna skalas med D^-2 för axiallast och D^-3 för böjning och vridning.
sigma_tillat = sigma_s/ns;
sigma_utm_tillat = sigma_u/nu;
a_N = abs(sigma_N(i_and))*D_guess^2;
a_b = sigma_b(i_and)*D_guess^3;
a_T = sqrt(3)*tau_T(i_and)*D_guess^3;

D_grans = @(aN,aB,aT) max(sqrt(max(aN)/sigma_tillat), ...
    (max(hypot(aB,aT))/sigma_tillat)^(1/3));
plastdiameter = @(aN,aB,aT) fzero(@(D) ...
    max(hypot(aN/D^2+aB/D^3,aT/D^3))-sigma_tillat, ...
    D_grans(aN,aB,aT)*[0.5 2]);
D_plast_nom = plastdiameter(a_N,a_b,a_T);
D_utm_nom = (max(a_b)/sigma_utm_tillat)^(1/3);
D_nom = max(D_plast_nom,D_utm_nom);

% Hålkälsfaktorerna hålls konstanta och ska gälla för slutligt rho1/d.
sigma_vm_kal = [];
ns_kal_min = [];
D_plast = D_plast_nom;
D_utm = D_utm_nom;
if ~isempty(Kt_c)
    N_kal = Kt_c(1)*abs(sigma_N(i_kal));
    b_kal = Kt_c(2)*sigma_b(i_kal);
    T_kal = Kt_c(3)*sqrt(3)*tau_T(i_kal);
    sigma_vm_kal = hypot(N_kal+b_kal,T_kal);
    ns_kal_min = sigma_s/max(sigma_vm_kal);
    D_plast = plastdiameter([a_N N_kal*D_guess^2], ...
        [a_b b_kal*D_guess^3], [a_T T_kal*D_guess^3]);
end
if ~isempty(K_tb_utm_c)
    K_f_c = 1 + q*(K_tb_utm_c-1);
    D_utm = max(D_utm_nom,D_guess*(max(K_f_c*sigma_b(i_kal))/sigma_utm_tillat)^(1/3));
end
D_c = max(D_plast,D_utm);

%% Resultat
fprintf('\nLASTFALL C\n');
fprintf('Kurvfart %.2f km/h, tippgräns %.2f km/h, gamma %.4f\n',v_c*3.6,v_tipp*3.6,gamma);
fprintf('Drivmoment %.2f Nm, drevkraft %.2f N\n',M_motor,Fd);
fprintf('Bakhjul inre/yttre: vertikalt %.1f / %.1f N, i sidled %.1f / %.1f N\n', ...
    Vbi,Vby,Hbi,Hby);
fprintf('Lagerkrafter [x, y, z] inre: [% .1f, % .1f, % .1f] N, yttre: [% .1f, % .1f, % .1f] N\n', ...
    R_x1,R_y1,R_z1,R_x2,R_y2,R_z2);
fprintf('Max böjmoment %.2f Nm vid x = %.3f m\n',Mb_max,x_Mb_max);
fprintf('Max nominell effektivspänning %.2f MPa vid x = %.3f m (D = %.1f mm)\n', ...
    sigma_eff_max/1e6,x_sigma_eff_max,D_guess*1e3);
fprintf('Nominellt diameterkrav: plasticering %.2f mm, utmattning %.2f mm\n', ...
    D_plast_nom*1e3,D_utm_nom*1e3);
if ~isempty(Kt_c) && ~isempty(K_tb_utm_c)
    fprintf('Diameterkrav inklusive hålkälar: %.2f mm\n',D_c*1e3);
else
    fprintf('Diameterkrav för genomförda kontroller: %.2f mm. Lokala faktorer för C saknas helt eller delvis.\n',D_c*1e3);
end
if ~isempty(Kt_c)
    fprintf('Lokal effektivspänning i hålkälarna vid provdiametern: %.2f / %.2f MPa\n', ...
        sigma_vm_kal(1)/1e6,sigma_vm_kal(2)/1e6);
end

C = struct('x',x,'N',N,'Ty',Ty,'Tz',Tz,'My',My,'Mz',Mz,'T',torque, ...
    'Mb',Mb,'d_lokal',d_lokal,'sigma_N',sigma_N,'sigma_b',sigma_b, ...
    'sigma_plus',sigma_N+sigma_b,'sigma_minus',sigma_N-sigma_b, ...
    'tau_t',tau_T,'tau_T_max',tau_V,'sigma_vm',sigma_eff,'Mv',M_motor,'Fd',Fd, ...
    'gamma',gamma,'u',v_c,'v_tipp',v_tipp,'lagerkrafter',[R_x1 R_y1 R_z1; R_x2 R_y2 R_z2], ...
    'D_plast_nom',D_plast_nom,'D_utm_nom',D_utm_nom,'D_nom',D_nom, ...
    'D_plast',D_plast,'D_utm',D_utm,'D_c',D_c, ...
    'lokal_plast_kontrollerad',~isempty(Kt_c),'lokal_utm_kontrollerad',~isempty(K_tb_utm_c), ...
    'x_Mb_max',x_Mb_max,'x_sigma_vm_max',x_sigma_eff_max,'x_sigma_b_max',x_sigma_b_max, ...
    'sigma_vm_kal',sigma_vm_kal,'ns_kal_min',ns_kal_min);

%% Diagram
if visa_figurer
    bildfarg = [0.13 0.13 0.13];
    axelfarg = [0.08 0.08 0.08];
    textfarg = [0.87 0.87 0.87];
    bla = [0.29 0.57 1.00];
    rod = [1.00 0.33 0.33];
    gron = [0.23 0.88 0.40];
    orange = [1.00 0.72 0.27];
    magenta = [0.96 0.40 0.82];

    % Spänningar vid de diametrar som respektive villkor ger.
    effektivspanning = @(D) hypot(abs(sigma_N)*(D_guess/D)^2 + ...
        sigma_b*(D_guess/D)^3, sqrt(3)*tau_T*(D_guess/D)^3);
    plastkurvor = effektivspanning(D_plast_nom);
    plastnamn = {sprintf('Nominell, D = %.1f mm',D_plast_nom*1e3)};
    plastfarger = gron;
    plastlinjer = {'-'};
    if ~isempty(Kt_c)
        plast_lokal = effektivspanning(D_plast);
        skala = D_guess/D_plast;
        plast_lokal(i_kal) = hypot(N_kal*skala^2 + b_kal*skala^3,T_kal*skala^3);
        plastkurvor(end+1,:) = plast_lokal;
        plastnamn{end+1} = sprintf('Med K_t, D = %.1f mm',D_plast*1e3);
        plastfarger(end+1,:) = magenta;
        plastlinjer{end+1} = '--';
    end

    utmkurvor = sigma_b*(D_guess/D_utm_nom)^3;
    utmnamn = {sprintf('Nominell, D = %.1f mm',D_utm_nom*1e3)};
    utmfarger = gron;
    utmlinjer = {'-'};
    if ~isempty(K_tb_utm_c)
        utm_lokal = sigma_b*(D_guess/D_utm)^3;
        utm_lokal(i_kal) = K_f_c*utm_lokal(i_kal);
        utmkurvor(end+1,:) = utm_lokal;
        utmnamn{end+1} = sprintf('Med K_f, D = %.1f mm',D_utm*1e3);
        utmfarger(end+1,:) = magenta;
        utmlinjer{end+1} = '--';
    end

    kurvor = {[Ty; Tz; hypot(Ty,Tz); N], [My; Mz; Mb], torque, ...
        [sigma_b; abs(tau_T); tau_V; sigma_N]/1e6, ...
        [plastkurvor; sigma_tillat*ones(size(x))]/1e6, ...
        [utmkurvor; sigma_utm_tillat*ones(size(x))]/1e6};
    farger = {[bla; rod; gron; orange], [bla; rod; gron], bla, ...
        [bla; rod; gron; orange], [plastfarger; rod], [utmfarger; rod]};
    linjer = {{'-','-','--','-'}, {'-','-','--'}, {'-'}, {'-','-','-','-'}, ...
        [plastlinjer {'--'}], [utmlinjer {'--'}]};
    rubriker = {'Tvärkrafter och normalkraft','Böjmoment','Vridmoment', ...
        sprintf('Nominella spänningar, D = %.1f mm',D_guess*1e3), ...
        'Effektivspänning','Roterande böjspänning'};
    y_etiketter = {'Kraft [N]','Böjmoment [Nm]','T_x [Nm]','Spänning [MPa]', ...
        '\sigma_{eff} [MPa]','\sigma_a [MPa]'};
    serier = {{'T_y','T_z','T_{res}','N'}, {'M_y','M_z','M_b'}, {'T_x'}, ...
        {'Böjspänning','Vridskjuvspänning','Tvärkraftsskjuvning','Axialspänning'}, ...
        [plastnamn {'Tillåten'}], [utmnamn {'Tillåten'}]};

    figure('Name','Lastfall C','NumberTitle','off','Color',bildfarg, ...
        'Position',[80 60 1120 740],'InvertHardcopy','off');
    for k = 1:6
        ax = subplot(3,2,k);
        hold(ax,'on');
        idx = 1:numel(x);
        if k >= 4
            idx = i_axel;
        end
        for j = 1:size(kurvor{k},1)
            plot(ax,x(idx),kurvor{k}(j,idx),'Color',farger{k}(j,:), ...
                'LineStyle',linjer{k}{j},'LineWidth',1.25);
        end
        set(ax,'Color',axelfarg,'XColor',textfarg,'YColor',textfarg, ...
            'GridColor',textfarg,'GridAlpha',0.24,'Box','on','FontSize',10);
        grid(ax,'on');
        xlim(ax,[0 L]);
        if k == 5 || k == 6
            ylim(ax,[0 1.13*max(kurvor{k}(end,:))]);
        end
        title(ax,rubriker{k},'Color',textfarg);
        xlabel(ax,'x [m]','Color',textfarg);
        ylabel(ax,y_etiketter{k},'Color',textfarg);
        legend(ax,serier{k},'Location','northwest','Orientation','vertical','Color',axelfarg, ...
            'TextColor',textfarg,'EdgeColor',0.65*textfarg,'FontSize',9);
        hold(ax,'off');
    end
end
