run snittstorheter_lastfall_a.m



% Först definiera maximal böjmoment och vridmoment vid
% dimensionsövergången.
%-------------------------------------------------------------------%
My_max = My(b1);
Mz_max = Mz(b1);
Mv_max = F_D*dh/4;



%Sedan m.a.p specifikt material bestämma formfaktorerna K_tb för böjmoment
%och K_tv för vridmoment. Dessa faktorer ska multipliceras med maximal drag
%och skjuvspänning för att få den egentliga påfrestningen vid
%dimensionsövergången.
%--------------------------------------------------------------------%
sigma_max = @(D) K_tb * 32*sqrt(My_max^2+Mz_max^2)/(pi*(0.6*D)^3); %Maximal dragspänning vid dimensionsövergången
d_sigma_max = @(D) -3 * K_tb *32*sqrt(My_max^2 + Mz_max^2) / (pi * 0.6^3 * D^4); %Derivata m.a.p D

tau_max = @(D) K_tv * 16*Mv_max/(pi*(0.6*D)^3); %Maximal skjuvspänning vid dimensionsövergången
d_tau_max = @(D) -3 * K_tv * 16*Mv_max/(pi*0.6^3*D^4);

%Effektivspänningen kombinerar drag och skjuvspänning till en total
%amplitudspänning.
effektivspanning = @(D) sqrt(sigma_max(D)^2 + 3*tau_max(D)^2); %Maximal effektivspänning vid dimensionsövergången

g_pl = @(D) effektivspanning(D) - sigma_s/ns;
dg_pl = @(D) 1/2*(sigma_max(D)^2+3*tau_max(D)^2)^(-1/2)*(2*sigma_max(D)*d_sigma_max(D) + 6*tau_max(D)*d_tau_max(D));

Diameter = newton(g_pl, dg_pl, 0.04, 10^-8, 10);

Diameter 
%För varje iteration fram till diameter, måste K_tb och K_tv ändras enligt
%tabell 32.4 och 32.5. Det blir alltså två iterationer tills det att K_tb
%och K_tv håller sig på samma värden.



%Nu ska Diametern dimensioneras med avseende på utmattningen också. Den
%största diametern väljs.
%-----------------------------------------------------------------------%
sigma_ok_utm = sigma_u/(K_f*nu); %Enligt formel 25.2 och 25.3. Tillåten effektivspänning för materialet.

sigma_utm = @(D) 32*sqrt(My_max^2 + Mz_max^2) / (pi * (0.6*D)^3); %Tar bara hänsyn till böjspänningar, ingen effektivspänning
d_sigma_utm = @(D) -3 * 32*sqrt(My_max^2 + Mz_max^2) / (pi * 0.6^3 * D^4); %Derivatan

g_utm = @(D) sigma_utm(D) - sigma_ok_utm; %För att göra newton
dg_utm = @(D) d_sigma_utm(D); %Derivatan för g_utm

Diameter_utmattning = newton(g_utm, dg_utm, Diameter, 10^-10, 15);

Diameter_utmattning