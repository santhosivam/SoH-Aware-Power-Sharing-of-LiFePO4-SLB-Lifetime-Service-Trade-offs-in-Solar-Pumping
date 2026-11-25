function cc(cmd)
try
    s = evalc(cmd);
catch e
    s = ['ERR: ' getReport(e, 'extended', 'hyperlinks', 'off')];
end
if isempty(s), s = '(no output)'; end
s = regexprep(s, 'https?://\S+', '<url>'); clipboard('copy', s);
end
