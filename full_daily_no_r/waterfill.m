function a = waterfill(Ptot, w, cap)
%#codegen
a = zeros(1,4);
act = w > 0;
rem = Ptot;
for k = 1:4
    if rem <= 0 || sum(double(act)) == 0
        break;
    end
    ws = sum(w(act));
    share = zeros(1,4);
    share(act) = rem*w(act)/ws;
    over = act & (a + share > cap);
    if ~any(over)
        a = a + share;
        rem = 0;
        break;
    end
    for i = 1:4
        if over(i)
            rem = rem - (cap - a(i));
            a(i) = cap;
            act(i) = false;
        end
    end
end
end
