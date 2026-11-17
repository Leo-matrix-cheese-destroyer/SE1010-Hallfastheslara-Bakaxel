function [x] = newton(g, dg, x0, tol, max_iter)
x = x0;

    for k = 1:max_iter
        gx = g(x);
        dgx = dg(x);

        if abs(dgx) < 1e-12
            error('Derivatan är för nära noll. Metoden avbryts.');
        end
        
        x_new = x - gx/dgx;
        
        if abs(x_new - x) < tol
            x = x_new;
            return;
        end

        x = x_new; 
        
    end
    
    error('Newtons metod konvergerade inte inom max_iter iterationer.');
end