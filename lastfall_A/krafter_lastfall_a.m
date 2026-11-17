run konstanter.m

F_L = 1/2*rho_luft*c*A*v_a^2;
F_D = F_L+m*a1;
N_F = 1/(df + db)*(db*m*g - (h + h1)*F_L - h*m*a1);
N_B = 1/(df + db)*(df*m*g + (h + h1)*F_L + h*m*a1);

R_y1 = F_D/2;  R_y2 = F_D/2;
R_z1 = N_B/2;  R_z2 = N_B/2;