function snippets = calculateRoadCurvatureTypes(path)
% Input: "paths" - a cell array that contains measurements with the same
% direction and lane id information. The longest measurement is selected as
% basis for bounding box creation
    % parameters
    Xmin = 0.02; % cm, parameter to be calibrated
        
    % calculate mean orientation
    theta0 = median(calculateOrientation(path(:,1),path(:,2)));

    T = [cos(theta0) sin(theta0); -sin(theta0) cos(theta0)];
    localPath0 = [path(1,1) path(1,2)];
    localPath = ([path(:,1) path(:,2)]-localPath0)*T';
    % now iterate to provide strictly monotonic X
    n = 1;
    endReached = false;

    while(~endReached)        
        n1 = 1;
        N = size(localPath,1);
        for j=2:N
            dX = localPath(j,1)-localPath(j-1,1);
            if ((abs(dX) < Xmin && j>20) || j > 100)
                % a breakpoint is found, snippet is cut
                snippets{n} = localPath(n1:j-1,:)*T+localPath0;
                n = n+1;
                n1 = j;
                % now recalculate (rotate) localPath
                path = path(n1:end,:);
                theta0 = median(calculateOrientation(path(:,1),path(:,2)));

                T = [cos(theta0) sin(theta0); -sin(theta0) cos(theta0)];
                localPath0 = [path(1,1) path(1,2)];

                localPath = ([path(:,1) path(:,2)]-localPath0)*T';
                break;
            end
            if (j==N)
                endReached = true;
            end
        end
    end
    if (size(localPath,1)-n1 > 10)
        % enough points left, otherwise neglect remaining part
        snippets{n} = localPath(n1:end,:)*T+localPath0;
    end
end

