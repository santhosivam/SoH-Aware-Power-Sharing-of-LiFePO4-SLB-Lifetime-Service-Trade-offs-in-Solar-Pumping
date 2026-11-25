function clipchunk(fname, k, n)
s = fileread(fname);
i0 = (k-1)*n + 1; i1 = min(k*n, numel(s));
clipboard('copy', sprintf('[%d/%d]\n%s', k, ceil(numel(s)/n), s(i0:i1)));
end
