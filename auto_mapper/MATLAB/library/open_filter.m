function [rawData] = open_filter(rawData, thd)
if (rawData(end) == 1)
    if (rawData(1) == 1)
        bridges = [find(diff(rawData)==-1); size(rawData,1)] -[1;find(diff(rawData)==1)];
        r = [1; find(diff(rawData)==1)];
    else
        bridges = [find(diff(rawData)==-1); size(rawData,1)] -find(diff(rawData)==1);
        r = find(diff(rawData)==1);
    end
elseif (rawData(1) == 1)
    r = [1; find(diff(rawData)==1)];
    bridges = find(diff(rawData)==-1) - [1; find(diff(rawData)==1)];
else
    r = find(diff(rawData)==1);
    bridges = find(diff(rawData)==-1) - find(diff(rawData)==1);
end

for i=1:numel(bridges)
    if bridges(i) < thd
        rawData(r(i):r(i)+bridges(i)) = 0;
    end
end
end

