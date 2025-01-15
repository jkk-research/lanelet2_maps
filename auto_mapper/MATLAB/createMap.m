clear; close all;clc;

%% step 1: read in new files, put them into raw lanes struct
matFiles = dir(fullfile("forMapping", "*.mat"));
for i=1:length(matFiles)
    data = load(fullfile(matFiles(i).folder, matFiles(i).name));
    rawLanes(i) = dataPreprocess(data);    
end

%% step 2: read reference files
refMatFile = dir(fullfile("forMapping", "references", "manRef.mat"));
load(fullfile(refMatFile.folder, refMatFile.name));

%% step 3: match the raw measurement files to the reference data
for rawLaneId=1:length(rawLanes)
    for roadId=1:size(referenceData,1)
        for laneId=1:size(referenceData,2)
            for snippetId=1:size(referenceData{roadId,laneId}{1,3},2)
                if (any(inpolygon(rawLanes(rawLaneId).path(:,1), ...
                        rawLanes(rawLaneId).path(:,2), ...
                        referenceData{roadId,laneId}{1,3}{1,snippetId}.boundingBox(:,1), ...
                        referenceData{roadId,laneId}{1,3}{1,snippetId}.boundingBox(:,2))))
                    
                    % centerline
                    referenceData{roadId,laneId}{1,3}{1,snippetId}.path = ...
                        [referenceData{roadId,laneId}{1,3}{1,snippetId}.path; ...
                        rawLanes(rawLaneId).path(...
                        inpolygon(rawLanes(rawLaneId).path(:,1), ...
                        rawLanes(rawLaneId).path(:,2), ...
                        referenceData{roadId,laneId}{1,3}{1,snippetId}.boundingBox(:,1), ...
                        referenceData{roadId,laneId}{1,3}{1,snippetId}.boundingBox(:,2)), :)];
                    
                    % left lane edge
                    referenceData{roadId,laneId}{1,1}{1,snippetId}.path = ...
                        [referenceData{roadId,laneId}{1,1}{1,snippetId}.path; ...
                        rawLanes(rawLaneId).leftLane(...
                        inpolygon(rawLanes(rawLaneId).leftLane(:,1), ...
                        rawLanes(rawLaneId).leftLane(:,2), ...
                        referenceData{roadId,laneId}{1,1}{1,snippetId}.boundingBox(:,1), ...
                        referenceData{roadId,laneId}{1,1}{1,snippetId}.boundingBox(:,2)), :)];
                    
                    % right lane edge
                    referenceData{roadId,laneId}{1,2}{1,snippetId}.path = ...
                        [referenceData{roadId,laneId}{1,2}{1,snippetId}.path; ...
                        rawLanes(rawLaneId).rightLane(...
                        inpolygon(rawLanes(rawLaneId).rightLane(:,1), ...
                        rawLanes(rawLaneId).rightLane(:,2), ...
                        referenceData{roadId,laneId}{1,2}{1,snippetId}.boundingBox(:,1), ...
                        referenceData{roadId,laneId}{1,2}{1,snippetId}.boundingBox(:,2)), :)];
                end
            end
        end
    end
end

%% step 4: accurate final path calculation
for roadId=1:size(referenceData,1)
    for laneId=1:size(referenceData,2)
        for laneEdgeId=1:size(referenceData{roadId, laneId}, 2)
            referenceData{roadId,laneId}{1,laneEdgeId} = calculateSmoothLine(referenceData{roadId,laneId}{1,laneEdgeId});
        end
    end
end

% create summary plots
f = figure(1);
f.Position = [800 400 550 750];
set(f,'defaulttextInterpreter','latex') ;
set(f, 'defaultAxesTickLabelInterpreter','latex');  
set(f, 'defaultLegendInterpreter','latex');

for roadId=1:size(referenceData,1)
    for laneId=1:size(referenceData,2)
        for laneEdgeId=1:size(referenceData{roadId, laneId}, 2)
            for snippetId=1:length(referenceData{roadId, laneId}{1,laneEdgeId})
                
                plot(referenceData{roadId, laneId}{1,laneEdgeId}{snippetId}.path(:,1), ...
                    referenceData{roadId, laneId}{1,laneEdgeId}{snippetId}.path(:,2), ...
                    'color', 'r', 'Marker', '.', 'LineStyle', 'none', ...
                    'DisplayName',strcat("laneId=",num2str(laneId)));
                
                    hold on; grid on;
                    axis equal;
                    
                plot(referenceData{roadId, laneId}{1,laneEdgeId}{snippetId}.finalPath(:,1), ...
                    referenceData{roadId, laneId}{1,laneEdgeId}{snippetId}.finalPath(:,2), ...
                    'color', 'k', 'LineWidth', 1, ...
                    'DisplayName', strcat("laneId=", num2str(laneId), "snippetId=", num2str(snippetId)));

            end
        end
    end
end

xlabel("$X_{UTM}(m)$"); ylabel("$Y_{UTM}(m)$");
set(gca,'TickLabelInterpreter','latex');
set(gca,'FontSize', 14);
legend ("Location", "best", "FontSize", 11);
title("Lane map for ZalaZONE highway, east segment");

%% END OF ORIGINAL FUNCTION
%% START OF SUBFUNCTIONS
function snippets = calculateSmoothLine(snippets)
    % input:
    % 1 - "paths" a cell array containing the X-Y points in Nx2 form of all
    % new measurements
    % 2 - "snippets" is a cell array that contains the bounding boxes in
    % Nx2 form for all available road segments
    
    % output:
    % 1 - "snippets" is extended with sorted points and final path which is
    % the smooth lane path
    
    % now rotate and fit
    for n=1:length(snippets)
        if (size(snippets{n}.path,1) > 20)
            theta0 = median(calculateOrientation(snippets{n}.path(:,1), snippets{n}.path(:,2)));

            T = [cos(theta0) sin(theta0); -sin(theta0) cos(theta0)];
            if (n==1)
                localPath = (snippets{n}.path-snippets{n}.path(1,1:2))*T';
            else
                localPath = (snippets{n}.path-snippets{n-1}.finalPath(end,1:2))*T';
            end
            % regression
            if (snippets{n}.type == 0)
                % linear regression
                if (n==1)
                    xFine = min(localPath(:,1)):0.1:max(localPath(:,1));
                    c = polyfit(localPath(:,1), localPath(:,2), 1);
                    snippets{n}.finalPath = [xFine' c(2)+c(1)*xFine']*T+[snippets{n}.path(1,1) snippets{n}.path(1,2)];
                else                    
                    x0 = 0;
                    y0 = 0;
                    xFine = 0:0.1:max(localPath(:,1));
                    clear V;
                    % 'C' is the Vandermonde matrix for 'x'
                    m = 3; % Degree of polynomial to fit
                    V(:,m+1) = ones(size(localPath,1),1,class(localPath));
                    for j = m:-1:1
                       V(:,j) = localPath(:,1).*V(:,j+1);
                    end
                    C = V;
                    % 'd' is the vector of target values, 'y'.
                    d = localPath(:,2);
                    %%
                    % There are no inequality constraints in this case, i.e.,
                    A = [];
                    b = [];
                    %%
                    % We use linear equality constraints to force the curve to hit the required point. In
                    % this case, 'Aeq' is the Vandermoonde matrix for 'x0'
                    Aeq = x0.^(m:-1:0);
                    % and 'beq' is the value the curve should take at that point
                    beq = y0;
                    %%
                    p = lsqlin( C, d, A, b, Aeq, beq );
                    %%
                    % We can then use POLYVAL to evaluate the fitted curve
                    yhat = polyval( p, xFine );
                    if (n==1)
                        snippets{n}.finalPath = [xFine' yhat']*T+[snippets{n}.path(1,1) snippets{n}.path(1,2)];
                    else
                        snippets{n}.finalPath = [xFine' yhat']*T+[snippets{n-1}.finalPath(end,1) snippets{n-1}.finalPath(end,2)];
                    end
                end
            else
                if (n==1)
                    c = polyfit(localPath(:,1), localPath(:,2), 3);
                    snippets{n}.finalPath = [xFine' c(4)+c(3)*xFine'+c(2)*xFine'.^2+c(1)*xFine'.^3]*T+[snippets{n}.path(1,1) snippets{n}.path(1,2)];
                else
                    x0 = 0;
                    y0 = 0;
                    xFine = 0:0.1:max(localPath(:,1));
                    clear V;
                    % 'C' is the Vandermonde matrix for 'x'
                    m = 17; % Degree of polynomial to fit
                    V(:,m+1) = ones(size(localPath,1),1,class(localPath));
                    for j = m:-1:1
                       V(:,j) = localPath(:,1).*V(:,j+1);
                    end
                    C = V;
                    % 'd' is the vector of target values, 'y'.
                    d = localPath(:,2);
                    %%
                    % There are no inequality constraints in this case, i.e.,
                    A = [];
                    b = [];
                    %%
                    % We use linear equality constraints to force the curve to hit the required point. In
                    % this case, 'Aeq' is the Vandermoonde matrix for 'x0'
                    Aeq = x0.^(m:-1:0);
                    % and 'beq' is the value the curve should take at that point
                    beq = y0;
                    %%
                    p = lsqlin( C, d, A, b, Aeq, beq );
                    %%
                    % We can then use POLYVAL to evaluate the fitted curve
                    yhat = polyval( p, xFine );
                    if (n==1)
                        snippets{n}.finalPath = [xFine' yhat']*T+[snippets{n}.path(1,1) snippets{n}.path(1,2)];
                    else
                        snippets{n}.finalPath = [xFine' yhat']*T+[snippets{n-1}.finalPath(end,1) snippets{n-1}.finalPath(end,2)];
                    end
                end
            end
        else
            snippets{n}.finalPath = [];
        end
    end    
end