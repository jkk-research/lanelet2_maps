%% REFERENCING PHASE
% Generate reference lines based on manually labelled measurements

clear;

addpath("library");

crpMapDatabasePath = fullfile("..", "CRP_MAP_DB");

if (isfolder(crpMapDatabasePath))
    crpMapDatabaseFile = dir(fullfile(crpMapDatabasePath, "crp_map_db.mat"));
    if (~isempty(crpMapDatabaseFile))
        load(fullfile(crpMapDatabaseFile(1).folder, crpMapDatabaseFile(1).name));
    else
        referenceData = {};
    end
end

matFilesForRef = dir(fullfile("..","ReferenceMeasurements", "*.mat"));

for i=1:length(matFilesForRef)
    data = load(fullfile(matFilesForRef(i).folder, matFilesForRef(i).name));
    roadId = str2num(matFilesForRef(i).name(strfind(matFilesForRef(i).name,'roadId')+7:strfind(matFilesForRef(i).name,'roadId')+9));
    laneId = str2num(matFilesForRef(i).name(strfind(matFilesForRef(i).name,'laneId')+7));
    refLanes(roadId, laneId) = dataPreprocess(data);    
end

% generate cells of 3 elements, one for each lane, 3 cell elements are:
% left,  right edges and centerline

for roadId = 1:size(refLanes,1)
    for laneId = 1:size(refLanes,2)
        if (size(referenceData,1) >= roadId)
            if (isempty(referenceData{roadId, laneId}) && ~isempty(refLanes(roadId, laneId)))
                    addNewMapRef = true;
            else
                addNewMapRef = false;
            end
        else
            if (~isempty(refLanes(roadId, laneId).path))
                addNewMapRef = true;
            else
                addNewMapRef = false;
            end
        end
        if (addNewMapRef)
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
end

if(~isfolder(fullfile("..", "CRP_MAP_DB")))
    mkdir(fullfile("..", "CRP_MAP_DB"));
end

save(fullfile(crpMapDatabasePath, "crp_map_db.mat"), "referenceData");