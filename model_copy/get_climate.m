function C = get_climate(lat, lon, yr)
url = sprintf(['https://power.larc.nasa.gov/api/temporal/daily/point?parameters=' ...
    'ALLSKY_SFC_SW_DWN,T2M,T2M_MAX,T2M_MIN&community=RE&longitude=%.4f&latitude=%.4f' ...
    '&start=%d0101&end=%d1231&format=JSON'], lon, lat, yr, yr);
opt = weboptions('Timeout', 60);
J = webread(url, opt);
p = J.properties.parameter;
f = fieldnames(p.ALLSKY_SFC_SW_DWN);
n = numel(f);
C.date = datetime(cellfun(@(s) s(2:end), f, 'UniformOutput', false), 'InputFormat', 'yyyyMMdd');
gv = @(fld) cellfun(@(k) p.(fld).(k), f);
C.H = gv('ALLSKY_SFC_SW_DWN'); C.T = gv('T2M'); C.Tmax = gv('T2M_MAX'); C.Tmin = gv('T2M_MIN');
C.nMissing = sum(C.H < -900) + sum(C.T < -900);
for v = {'H', 'T', 'Tmax', 'Tmin'}
    x = C.(v{1}); bad = x < -900;
    if any(bad), x(bad) = interp1(find(~bad), x(~bad), find(bad), 'linear', 'extrap'); end
    C.(v{1}) = x;
end
doy = day(C.date, 'dayofyear');
dec = 23.45*sind(360*(284 + doy)/365);
ws  = acosd(-tand(lat).*tand(dec));
C.L = 2*ws/15;
C.tsr = 12 - C.L/2;
C.lat = lat; C.lon = lon; C.year = yr; C.url = url; C.n = n;
end
