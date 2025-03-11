%% REFERENCING PHASE
% Generate reference lines based on manually labelled measurements

clear;

addpath("library");

options.fillHoles = false;

crpMapDatabasePath = fullfile("..", "CRP_MAP_DB");

if (isfolder(crpMapDatabasePath))
    crpMapDatabaseFile = dir(fullfile(crpMapDatabasePath, "crp_map_db.mat"));
    crpDbExists = ~isempty(crpMapDatabaseFile);
    
    if (crpDbExists)
        load(fullfile(crpMapDatabaseFile(1).folder, crpMapDatabaseFile(1).name));
    else
        % create brand new db
        referenceData = {};
    end
end

matFilesForRef = dir(fullfile("..","ReferenceMeasurements", "*.mat"));

for i=1:length(matFilesForRef)
    data = load(fullfile(matFilesForRef(i).folder, matFilesForRef(i).name));
    roadId = str2num(matFilesForRef(i).name(strfind(matFilesForRef(i).name,'roadId')+7:strfind(matFilesForRef(i).name,'roadId')+9));
    laneId = str2num(matFilesForRef(i).name(strfind(matFilesForRef(i).name,'laneId')+7));
    refLanes(roadId, laneId) = dataPreprocess(data, options);    
end

% generate cells of 3 elements, one for each lane, 3 cell elements are:
% left,  right edges and centerline

for roadId = 1:size(refLanes,1)
    roadPlaceHolderExistsInDb = size(referenceData,1) >= roadId;    
    roadPlaceHolderExistsInMeasurement = size(refLanes,1) >= roadId;    

    for laneId = 1:size(refLanes,2)

        lanePlaceHolderExistsInDb = size(referenceData,2) >= laneId;
        roadAndLaneExistsInDb = false;
        if (roadPlaceHolderExistsInDb && lanePlaceHolderExistsInDb)
            roadAndLaneExistsInDb = ~isempty(referenceData{roadId, laneId});
        end

        lanePlaceHolderExistsInMeasurement = size(refLanes,2) >= laneId;
        roadAndLaneExistsInMeasurement = false;
        if (roadPlaceHolderExistsInMeasurement && lanePlaceHolderExistsInMeasurement)
            roadAndLaneExistsInMeasurement = ~isempty(refLanes(roadId, laneId).path);
        end

        if (~roadAndLaneExistsInDb && roadAndLaneExistsInMeasurement)
            snippets{1} = calculateRoadCurvatureTypes(refLanes(roadId, laneId).leftLane);
            snippets{2} = calculateRoadCurvatureTypes(refLanes(roadId, laneId).rightLane);
            snippets{3} = calculateRoadCurvatureTypes(refLanes(roadId, laneId).path);
            for i=1:3
                boundingBoxUnfiltered{i} = createBoundingBoxes(snippets{i});
                % remove those snippets that are not feasible
                n = 1;
                for j=1:length(boundingBoxUnfiltered{i})
                    displacements = sqrt(diff(boundingBoxUnfiltered{i}{j}.path(:,1)).^2+diff(boundingBoxUnfiltered{i}{j}.path(:,2)).^2);
                    if (max(displacements) <= 3)
                        boundingBox{i}{n} = boundingBoxUnfiltered{i}{j};
                        n = n +1;
                    end
                end
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