%% REFERENCING PHASE
% Generate reference lines based on manually labelled measurements

matFiles = dir(fullfile("forMapping", "manualReferences", "*.mat"));
for i=1:length(matFiles)
    data = load(fullfile(matFiles(i).folder, matFiles(i).name));
    roadId = str2num(matFiles(i).name(strfind(matFiles(i).name,'roadId')+7:strfind(matFiles(i).name,'roadId')+9));
    laneId = str2num(matFiles(i).name(strfind(matFiles(i).name,'laneId')+7));
    refLanes(roadId, laneId) = dataPreprocess(data);    
end

% generate cells of 3 elements, one for each lane, 3 cell elements are:
% left,  right edges and centerline

for roadId = 1:size(refLanes,1)
    for laneId = 1:size(refLanes,2)
        [type{1}, line{1}] = calculateRoadCurvatureTypes(refLanes(roadId, laneId).leftLane);
        [type{2}, line{2}] = calculateRoadCurvatureTypes(refLanes(roadId, laneId).rightLane);
        [type{3}, line{3}] = calculateRoadCurvatureTypes(refLanes(roadId, laneId).path);
        for i=1:3
            boundingBox{i} = createBoundingBoxes(line{i}, type{i});
        end
        referenceData{roadId, laneId} = boundingBox;
        clear boundingBox
    end    
end

if(~isdir(fullfile("forMapping","references")))
    mkdir(fullfile("forMapping", "references"));
end

save(fullfile("forMapping", "references", "manRef.mat"), "referenceData");