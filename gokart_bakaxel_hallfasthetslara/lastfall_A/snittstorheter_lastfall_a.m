run krafter_lastfall_a.m

My = @(x) x.*N_B/2 - (x>=b1).*(x-b1).*R_z1 - (x>=L-b1).*(x-(L-b1)).*R_z2;
Mz = @(x) x.*F_D/2 - (x>=b1).*(x-b1).*R_y1 - (x>=L-b1).*(x-(L-b1)).*R_y2;

Tz = @(x) N_B/2 - (x>=b1).*R_z1 - (x>=L-b1).*R_z2;
Ty = @(x) F_D/2 - (x>=b1).*R_y1 - (x>=L-b1).*R_y2;

Mv = @(x) (x<L/2).*-F_D*dh/4 + (x>L/2).*F_D*dh/4;



x = linspace(0,L,1000);

figure(1)
hold on
plot(x, My(x), LineWidth=2)
plot(x, Mz(x), LineWidth=2)
xlabel('Position x [m]')
ylabel('Böjmoment [Nm]')
legend('My(x)', 'Mz(x)')
grid on
hold off

figure(2)
hold on
plot(x, Tz(x), LineWidth=2)
plot(x, Ty(x), LineWidth=2, LineStyle="--")
xlabel('Position x [m]')
ylabel('Tvärkraft [N]')
legend('Tz(x)', 'Ty(x)')
grid on
hold off

figure(3)
plot(x, Mv(x), LineWidth=2)
xlabel('Position x [m]')
ylabel('Vridmoment [Nm]')
legend('Mv(x)')
grid on