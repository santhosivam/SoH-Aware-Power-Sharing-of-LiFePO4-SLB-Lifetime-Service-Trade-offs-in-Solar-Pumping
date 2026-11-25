function C = load_weather_year(yr)
weatherPath = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'weather_2021_2024.csv');
T = readtable(weatherPath);
v = T(T.year == yr,:);
assert(height(v) == 365 && isequal(v.day,(1:365)'), ...
    'Requested weather year is missing or incomplete');
lat = 11.0168;
dec = 23.45*sind(360*(284 + v.day)/365);
ws = acosd(-tand(lat).*tand(dec));
C.H = v.H'; C.T = v.T'; C.Tmax = v.Tmax'; C.Tmin = v.Tmin';
C.L = (2*ws/15)'; C.tsr = 12 - C.L/2;
C.date = datetime(string(v.date),'InputFormat','yyyyMMdd');
C.lat = lat; C.lon = 76.9558; C.year = yr; C.n = 365;
end
