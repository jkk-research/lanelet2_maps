clear; close all;clc;

matFiles = dir(fullfile("forMapping", "76", "*.mat"));
j=1; k=1;

for i=1:length(matFiles)
    load(fullfile(matFiles(i).folder, matFiles(i).name));

    
end

% create summary plots
f = figure(1);
f.Position = [800 400 550 750];
set(f,'defaulttextInterpreter','latex') ;
set(f, 'defaultAxesTickLabelInterpreter','latex');  
set(f, 'defaultLegendInterpreter','latex');

for i=1:length(lanes(1).path)
    plot(lanes(1).path{i}(:,1), lanes(1).path{i}(:,2), 'color', 'r', 'DisplayName', strcat('laneId=1 no',num2str(i)));
    hold on; grid on;
    axis equal;
    plot(lanes(1).path{i}(1,1), lanes(1).path{i}(1,2), 'ro', 'HandleVisibility', 'off');
    plot(lanes(1).leftLane{i}(:,1), lanes(1).leftLane{i}(:,2), 'color', 'k', 'LineStyle', '--', 'DisplayName', strcat('laneEdgeId=2 no',num2str(i)));
    plot(lanes(1).rightLane{i}(:,1), lanes(1).rightLane{i}(:,2), 'color', 'r', 'LineStyle', '--', 'DisplayName', strcat('laneEdgeId=1 no',num2str(i)));
end

for i=1:length(lanes(2).path)
    plot(lanes(2).path{i}(:,1), lanes(2).path{i}(:,2), 'color', 'b', 'DisplayName', strcat('laneId=2 no',num2str(i)));
    plot(lanes(2).path{i}(1,1), lanes(2).path{i}(1,2), 'bo', 'HandleVisibility', 'off');
    plot(lanes(2).leftLane{i}(:,1), lanes(2).leftLane{i}(:,2), 'color', 'b', 'LineStyle', '--', 'DisplayName', strcat('laneEdgeId=3 no.',num2str(i)));
    plot(lanes(2).rightLane{i}(:,1), lanes(2).rightLane{i}(:,2), 'color', 'k', 'LineStyle', '--', 'DisplayName', strcat('laneEdgeId=2 no',num2str(i)));
end

xlabel("$X_{UTM}(m)$"); ylabel("$Y_{UTM}(m)$");

set(gca,'TickLabelInterpreter','latex');
set(gca,'FontSize', 14);
legend ("Location", "best", "FontSize", 11);
title("Lane map for ZalaZONE highway, east segment");

% merging the separating marker
for i=1:length(lanes(1).leftLane)
    sepLane{i} = lanes(1).leftLane{i};
end
for i=1:length(lanes(2).rightLane)
    sepLane{i+length(lanes(1).leftLane)} = lanes(2).rightLane{i};
end

%% PART 2: classify road sections to separate types based on curvature
% NOTE: part 2 shall only be done by one time. This step produces bounding
% boxes in the global space (UTM coordinates), and each bounding boxes owns
% a types:
% 0 - straight
% 1 - left curve
% 2 - right curve
% Also, the bounding boxes are endowed with lane id information and
% direction.
% Once a new measurement comes in, it can be synhced with the bounding
% boxes, and segments that falls into any of the boxes are grouped. 

clear path
% PART 2/1: for midlane of line id = 1
[types{1}, path{1}] = calculateRoadCurvatureTypes(lanes(1).path);
% PART 2/2: for midlane of line id = 2
[types{2}, path{2}] = calculateRoadCurvatureTypes(lanes(2).path);
% PART 2/3: for separating line
[types{3}, path{3}] = calculateRoadCurvatureTypes(sepLane);
% PART 2/4: for lane id=1 right line
[types{4}, path{4}] = calculateRoadCurvatureTypes(lanes(1).rightLane);
% PART 2/5: for lane id=2 left line
[types{5}, path{5}] = calculateRoadCurvatureTypes(lanes(2).leftLane);

% calculate bounding boxes for various road types
for i=1:length(path)
    referenceData{i} = createBoundingBoxes(path{i}, types{i}, 1);
end

%% PART 3: make regression
% calculate a smooth line (input 1: incoming lines, input 2: reference data
% is matching reference data
referenceData{1} = calculateSmoothLine(lanes(1).path, referenceData{1});
referenceData{2} = calculateSmoothLine(lanes(2).path, referenceData{2});
referenceData{3} = calculateSmoothLine(sepLane, referenceData{3});
referenceData{4} = calculateSmoothLine(lanes(1).rightLane, referenceData{4});
referenceData{5} = calculateSmoothLine(lanes(2).leftLane, referenceData{5});

for i=1:length(referenceData)
    finalPath = [];
    for n=1:length(referenceData{i})
        finalPath = [finalPath; referenceData{i}{n}.finalPath];
    end
    plot(finalPath(:,1), finalPath(:,2), 'LineStyle', ':', 'LineWidth', 2, 'color', 'k', 'DisplayName', 'Fitted line');
    mergedPath{i} = finalPath;
end

lanelets{1}.centerLine = mergedPath{1};
lanelets{1}.leftLine = mergedPath{3};
lanelets{1}.rightLine = mergedPath{4};
lanelets{1}.laneID = 1;

lanelets{2}.centerLine = mergedPath{2};
lanelets{2}.leftLine = mergedPath{5};
lanelets{2}.rightLine = mergedPath{3};
lanelets{2}.laneID = 2;

%% END OF ORIGINAL FUNCTION
%% START OF SUBFUNCTIONS

function [types, path] = calculateRoadCurvatureTypes(paths)
% Input: "paths" - a cell array that contains measurements with the same
% direction and lane id information. The longest measurement is selected as
% basis for bounding box creation
    % parameters
    Xmin = 0.02; % cm, parameter to be calibrated
    cmin = 0.001; % 1/m
    
    % selecting the longest route for laneId = 1
    s = 0;
    for i = 1:length(paths)
        if(size(paths{i},1)>s)
            s = size(paths{i},1);
            idxs = i;
        end
    end
    
    path = paths{idxs};
    
    % calculate mean orientation
    theta0 = median(calculateOrientation(path(:,1),path(:,2)));

    T = [cos(theta0) sin(theta0); -sin(theta0) cos(theta0)];
    localPath = ([path(:,1) path(:,2)]-[path(1,1) path(1,2)])*T';
    % now iterate to provide strictly monotonic X
    n = 1;
    snippets{1} = localPath; % initializing with complete local path
    endReached = false;
    while(~endReached)
        N = size(localPath,1);
        n1 = 1;
        for j=2:N
            dX = localPath(j,1)-localPath(j-1,1);
            if (abs(dX) < Xmin)
                % a breakpoint is found, snippet is cut
                snippets{n} = localPath(n1:j-1,:);
                n = n+1;
                n1 = j;
                % now recalculate (rotate) localPath
                localPath = localPath(n1:end,:);
                theta0 = median(atan2(localPath(:,2),localPath(:,1)));
                if (diff(localPath(1:2,1)) < 0 && diff(localPath(1:2,1)) > 0)
                    % 2nd quarter
                    theta0 = theta0+pi();
                end
                T = [cos(theta0) sin(theta0); -sin(theta0) cos(theta0)];
                localPath = ([localPath(:,1) localPath(:,2)]-[localPath(1,1) localPath(1,2)])*T';
                break;
            end
            if (j==N)
                endReached = true;
            end
        end
    end
    if (size(localPath,1)-n1 > 10)
        % enough points left, otherwise neglect remaining part
        snippets{n} = localPath(n1:end,:);
    end
    % now go through snippets and calculate the curvature
    c = []; % initializing with empty vector
    for n=1:length(snippets)
        if (size(snippets{n},2) > 1)
            o = diff(snippets{n}(:,2))./diff(snippets{n}(:,1));
            o = [o; o(end)];
            o = movmean(o,500);
            c = [c; movmean(diff(o)./diff(snippets{n}(:,1)),500)];
            c = [c; c(end)];
        else
            c = [c; c(end)];
        end
    end
    kappa = c;
    types = zeros(length(c),1);
    leftCurves = close_filter(c>cmin, 100);
    rightCurves = close_filter(c<-cmin, 100);
    types(leftCurves) = 1; % left
    types(rightCurves) = 2; % right
    % zero is straight
end

function snippets = createBoundingBoxes(path, types, laneID)
    % now recut the snippets - where type changes, we insert a breaking
    % point
    bp = find(abs(diff(types)) > 0);
    N = numel(bp); % number of breaking points
    clear snippets
    W = 1; % bounding box half width
    for n=1:N+1
        if(n==1)
            snippets{n}.path = path(1:bp(n),:);
            snippets{n}.type = types(bp(n)-1);
        elseif (n==N+1)
            snippets{n}.path = path(bp(n-1)+1:end,:);
            snippets{n}.type = types(bp(n-1)+1);
        else
            snippets{n}.path = path(bp(n-1)+1:bp(n),:);
            snippets{n}.type = types(bp(n)-1);
        end
        snippets{n}.laneID = laneID;
        % generate bounding boxes out of the snippets

        o = calculateOrientation(snippets{n}.path(:,1), snippets{n}.path(:,2));
        boundingBox(:,1:2) = [snippets{n}.path(:,1)-sin(o)*W snippets{n}.path(:,2)+cos(o)*W];
        boundingBox = [boundingBox; [snippets{n}.path(end:-1:1,1)+sin(o(end:-1:1))*W snippets{n}.path(end:-1:1,2)-cos(o(end:-1:1))*W]];

        snippets{n}.boundingBox(:,1:2) = DouglasPeuckerB(boundingBox(:,1:2),W);  
        clear boundingBox
    end
end

function snippets = calculateSmoothLine(paths, snippets)
    % input:
    % 1 - "paths" a cell array containing the X-Y points in Nx2 form of all
    % new measurements
    % 2 - "snippets" is a cell array that contains the bounding boxes in
    % Nx2 form for all available road segments
    
    % output:
    % 1 - "snippets" is extended with sorted points and final path which is
    % the smooth lane path
    
    % now iterate through lanes, and classify them into the lane segments based
    % on the bounding box. Then, the points in the boundingbox are rotated and
    % regression is applied on them
    for i=1:length(paths)
        % sorting the points to the bounding boxes
        for n=1:length(snippets)
            if (~isfield(snippets{n}, "sortedPoints"))
                snippets{n}.sortedPoints = [];
            end
            snippets{n}.sortedPoints = [snippets{n}.sortedPoints; paths{i}(inpolygon(paths{i}(:,1), paths{i}(:,2), snippets{n}.boundingBox(:,1), snippets{n}.boundingBox(:,2)), :)];
        end
    end

    % now rotate and fit
    for n=1:length(snippets)
        if (size(snippets{n}.sortedPoints,1) > 20)
            theta0 = median(calculateOrientation(snippets{n}.sortedPoints(:,1), snippets{n}.sortedPoints(:,2)));

            T = [cos(theta0) sin(theta0); -sin(theta0) cos(theta0)];
            if (n==1)
                localPath = (snippets{n}.sortedPoints-snippets{n}.sortedPoints(1,1:2))*T';
            else
                localPath = (snippets{n}.sortedPoints-snippets{n-1}.sortedPoints(end,1:2))*T';
            end
            % regression
            xFine = min(localPath(:,1)):0.1:max(localPath(:,1));
            if (snippets{n}.type == 0)
                % linear regression
                if (n==1)
                    c = polyfit(localPath(:,1), localPath(:,2), 1);
                    snippets{n}.finalPath = [xFine' c(2)+c(1)*xFine']*T+[snippets{n}.sortedPoints(1,1) snippets{n}.sortedPoints(1,2)];
                else
                    p0 = (snippets{n-1}.finalPath(end,1:2)-snippets{n}.sortedPoints(1,1:2))*T';
                    x0 = p0(1);
                    y0 = p0(2);
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
                        snippets{n}.finalPath = [xFine' yhat']*T+[snippets{n}.sortedPoints(1,1) snippets{n}.sortedPoints(1,2)];
                    else
                        snippets{n}.finalPath = [xFine' yhat']*T+[snippets{n-1}.sortedPoints(end,1) snippets{n-1}.sortedPoints(end,2)];
                    end
                end
            else
                if (n==1)
                    c = polyfit(localPath(:,1), localPath(:,2), 3);
                    snippets{n}.finalPath = [xFine' c(4)+c(3)*xFine'+c(2)*xFine'.^2+c(1)*xFine'.^3]*T+[snippets{n}.sortedPoints(1,1) snippets{n}.sortedPoints(1,2)];
                else
                    p0 = (snippets{n-1}.finalPath(end,1:2)-snippets{n}.sortedPoints(1,1:2))*T';
                    x0 = p0(1);
                    y0 = p0(2);
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
                        snippets{n}.finalPath = [xFine' yhat']*T+[snippets{n}.sortedPoints(1,1) snippets{n}.sortedPoints(1,2)];
                    else
                        snippets{n}.finalPath = [xFine' yhat']*T+[snippets{n-1}.sortedPoints(end,1) snippets{n-1}.sortedPoints(end,2)];
                    end
                end
            end
        else
            snippets{n}.finalPath = [];
        end
    end    
end

function theta = calculateOrientation(x,y)
    theta = atan(diff(y)./diff(x)); theta = [theta; theta(end)];
    % check quarterplane 2 and 3 conditions
    dx = diff(x); dx = [dx; dx(end)];
    dy = diff(y); dy = [dy; dy(end)];
    
    qp2 = (dx < 0) & (dy > 0); % the division in the atan function is negative, therefore the angle is negative - compensation of +pi() is needed
    qp3 = (dx < 0) & (dy < 0); % the division in the atan function is positive, therefore the angle is positive - compensation of -pi() is needed
    
    theta(qp2) = theta(qp2)+pi();
    theta(qp3) = theta(qp3)-pi();
end
