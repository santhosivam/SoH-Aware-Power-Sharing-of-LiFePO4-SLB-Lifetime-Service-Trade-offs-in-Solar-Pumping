function set_sizes(mdl)
v4  = {'soc','socHat','Pbus','vrc','T','dsoc','dvrc','dT','I','Vt','PbusAct'};
rt = sfroot;
chs = rt.find('-isa', 'Stateflow.EMChart');
for c = 1:numel(chs)
    if ~startsWith(chs(c).Path, mdl), continue; end
    ds = chs(c).find('-isa', 'Stateflow.Data');
    for k = 1:numel(ds)
        nm = ds(k).Name;
        if strcmp(nm, 'P'), continue; end
        if any(strcmp(nm, v4)), sz = '[1 4]';
        elseif any(strcmp(nm, {'r','acc'})), sz = '[1 14]';
        elseif strcmp(nm, 'y'), sz = '[1 43]';
        else, sz = '1';
        end
        ds(k).Props.Array.Size = sz;
    end
end
end
