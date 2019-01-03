function [xf,fval,exitflag] = fminbnd_striped(funfcn, ax,bx)

    % exitflag
    % 0 - maxfun or maxiter
    % 1 - okay

    tol = 1;
    maxfun = 100;
    maxiter = 100;

    funccount = 0;
    iter = 0;
    xf = []; fx = [];

    % Assume we'll converge
    exitflag = 1;

    % Compute the start point
    seps = sqrt(eps);
    c = 0.5*(3.0 - sqrt(5.0));
    a = ax; b = bx;
    v = a; % inital guess (old: a + c*(b-a))
    w = v; xf = v;
    d = 0.0; e = 0.0;
    x= xf; fx = funfcn(x);
    funccount = funccount + 1;

    fv = fx; fw = fx;
    xm = 0.5*(a+b);
    tol1 = seps*abs(xf) + tol/3.0;
    tol2 = 2.0*tol1;

    % Main loop
    while ( abs(xf-xm) > (tol2 - 0.5*(b-a)) )
        gs = 1;
        % Is a parabolic fit possible
        if abs(e) > tol1
            % Yes, so fit parabola
            gs = 0;
            r = (xf-w)*(fx-fv);
            q = (xf-v)*(fx-fw);
            p = (xf-v)*q-(xf-w)*r;
            q = 2.0*(q-r);
            if q > 0.0,  p = -p; end
            q = abs(q);
            r = e;  e = d;

            % Is the parabola acceptable
            if ( (abs(p)<abs(0.5*q*r)) && (p>q*(a-xf)) && (p<q*(b-xf)) )

                % Yes, parabolic interpolation step
                d = p/q;
                x = xf+d;

                % f must not be evaluated too close to ax or bx
                if ((x-a) < tol2) || ((b-x) < tol2)
                    si = sign(xm-xf) + ((xm-xf) == 0);
                    d = tol1*si;
                end
            else
                % Not acceptable, must do a golden section step
                gs=1;
            end
        end
        if gs
            % A golden-section step is required
            if xf >= xm
                e = a-xf;
            else
                e = b-xf;
            end
            d = c*e;
        end

        % The function must not be evaluated too close to xf
        si = sign(d) + (d == 0);
        x = xf + si * max( abs(d), tol1 );
        fu = funfcn(x);
        funccount = funccount + 1;

        iter = iter + 1;

        % Update a, b, v, w, x, xm, tol1, tol2
        if fu <= fx
            if x >= xf
                a = xf;
            else
                b = xf;
            end
            v = w; fv = fw;
            w = xf; fw = fx;
            xf = x; fx = fu;
        else % fu > fx
            if x < xf
                a = x;
            else
                b = x;
            end
            if ( (fu <= fw) || (w == xf) )
                v = w; fv = fw;
                w = x; fw = fu;
            elseif ( (fu <= fv) || (v == xf) || (v == w) )
                v = x; fv = fu;
            end
        end
        xm = 0.5*(a+b);
        tol1 = seps*abs(xf) + tol/3.0; tol2 = 2.0*tol1;

        if funccount >= maxfun || iter >= maxiter
            exitflag = 0;
            fval = fx;
            return
        end
    end % while

    fval = fx;
end