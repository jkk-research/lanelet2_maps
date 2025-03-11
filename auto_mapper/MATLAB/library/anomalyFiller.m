function rawLanes = anomalyFiller(rawLanes)

stepThreshold = 3; % in meters

for i=1:length(rawLanes)
    stepDistances = sqrt(diff(rawLanes(i).path(:,1)).^2+diff(rawLanes(i).path(:,2)).^2);
    holes = find(stepDistances>stepThreshold);
end

