function r = xy2rdiff(xs,ys)
    x = diff(xs,1,2);
    y = diff(ys,1,2);
    r = xy2r(x,y);
end

