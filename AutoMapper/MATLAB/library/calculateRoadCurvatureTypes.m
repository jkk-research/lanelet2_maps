function [types, path] = calculateRoadCurvatureTypes(path)
% Input: "paths" - a cell array that contains measurements with the same
% direction and lane id information. The longest measurement is selected as
% basis for bounding box creation
    % parameters
    Xmin = 0.02; % cm, parameter to be calibrated
    cmin = 0.001; % 1/m
        
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
        if (size(snippets{n},1) > 1)
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

