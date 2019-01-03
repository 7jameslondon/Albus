function fun = gauss2DWBgFun
    fun = @(x,y,ux,uy,s,A,B)  A * exp(((x-ux).^2 + (y-uy).^2) / (-2*s)) / (2*pi*s) + B;
end