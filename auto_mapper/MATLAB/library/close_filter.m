function [rawData] = close_filter(rawData, thd)
% rising edges
f = find(diff(rawData)==-1);
r = find(diff(rawData)==1);
    
if (rawData(end)==0)
    r = [r; length(rawData)];
else
    %f = [f; length(rawData)];
end
if (rawData(1) == 0)
    f = [1; f];
else
    %r = [1; r];
end

bridges = r-f;

for i=1:numel(bridges)
    if bridges(i) < thd
        rawData(f(i):f(i)+bridges(i)) = 1;
    end
end
end

