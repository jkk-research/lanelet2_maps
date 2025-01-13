function lanes = dataPreprocess(data)
    [x,y,utmzone] = deg2utm(data.ADMA_INS_Lat_Abs_POI1,data.ADMA_INS_Long_Abs_POI1);

    % redundant point filter
    f = abs(diff(x))>0;
    x_filtered = x(f);
    y_filtered = y(f);

    theta0 = median(calculateOrientation(x_filtered, y_filtered));

    % global to local transformation
    T = [cos(theta0) sin(theta0); -sin(theta0) cos(theta0)];
    % quasi-local transformation
    path = ([x_filtered y_filtered]-[x_filtered(1) y_filtered(1)])*T';

    % quasi-local orientation
    theta = atan(diff(path(:,2))./diff(path(:,1)));
    theta = [theta; theta(end)];

    % adding lane edges
    f2 = data.BV_Linie_01_Existenzmass(f) > 0.75;
    f3 = data.BV_Linie_02_Existenzmass(f) > 0.75;
    data.BV_Linie_01_dy_filtered = data.BV_Linie_01_dy(f);
    data.BV_Linie_02_dy_filtered = data.BV_Linie_02_dy(f);
    
    % based on orientation decide over which lane / which direction we are
    % in and classify the lane accordingly
    if (mean(diff(y_filtered)) < 0)
        % heading south
        dir = 2;
    else
        % heading north
        dir = 1;
    end
    laneId = str2num(matFiles(i).name(strfind(matFiles(i).name,"laneId")+7));

    laneLeft = [path(f2,1)-sin(theta(f2)).*BV_Linie_01_dy_filtered(f2)' path(f2,2)+cos(theta(f2)).*BV_Linie_01_dy_filtered(f2)'];
    laneRight = [path(f3,1)-sin(theta(f3)).*BV_Linie_02_dy_filtered(f3)' path(f3,2)+cos(theta(f3)).*BV_Linie_02_dy_filtered(f3)'];

    c0 = 0.5*(BV_Linie_01_dy_filtered(f2&f3)+BV_Linie_02_dy_filtered(f2&f3));
    width = BV_Linie_01_dy_filtered(f2&f3)-BV_Linie_02_dy_filtered(f2&f3);
    midLane = [path(f2&f3,1)-sin(theta(f2&f3)).*c0' path(f2&f3,2)+cos(theta(f2&f3)).*c0'];
    
    if (dir == 1 && laneId == 1)
        % first struct element is the lane id 1 with dir north
        % transform to global
        midLaneGlobal = midLane*T+[x_filtered(1) y_filtered(1)];
        laneLeftGlobal = laneLeft*T+[x_filtered(1) y_filtered(1)];
        laneRightGlobal = laneRight*T+[x_filtered(1) y_filtered(1)];
        
        lanes(1).path = midLaneGlobal;
        lanes(1).dir = 1; lanes(1).laneId = 1;
        lanes(1).leftLane{j} = laneLeftGlobal;
        lanes(1).width{j} = width;
        lanes(1).rightLane{j} = laneRightGlobal;
        j = j+1;
    elseif (dir == 1 && laneId == 2)
        % first struct element is the lane id 1 with dir north
        % transform to global
        midLaneGlobal = midLane*T+[x_filtered(1) y_filtered(1)];
        laneLeftGlobal = laneLeft*T+[x_filtered(1) y_filtered(1)];
        laneRightGlobal = laneRight*T+[x_filtered(1) y_filtered(1)];
        
        lanes(2).path = midLaneGlobal;
        lanes(2).dir = 1; lanes(2).laneId = 2;
        lanes(2).leftLane = laneLeftGlobal;
        lanes(2).width = width;
        lanes(2).rightLane = laneRightGlobal;
        k = k+1;
    elseif (dir == 2 && laneId == 1)
        % first struct element is the lane id 1 with dir north
        % transform to global
        midLaneGlobal = midLane*T+[x_filtered(1) y_filtered(1)];
        laneLeftGlobal = laneLeft*T+[x_filtered(1) y_filtered(1)];
        laneRightGlobal = laneRight*T+[x_filtered(1) y_filtered(1)];
        
        lanes(1).path{j} = midLaneGlobal(end:-1:1,:);
        lanes(1).dir = 1; lanes(1).laneId = 1;
        lanes(1).leftLane{j} = laneRightGlobal(end:-1:1,:);
        lanes(1).width{j} = width(end:-1:1);
        lanes(1).rightLane{j} = laneLeftGlobal(end:-1:1,:);
        j = j+1;
    else
        % second struct element is the lane id 2, but transformed to north
        % as well
        % transform to global and rotate with 180 degrees
        midLaneGlobal = midLane*T+[x_filtered(1) y_filtered(1)];
        laneLeftGlobal = laneLeft*T+[x_filtered(1) y_filtered(1)];
        laneRightGlobal = laneRight*T+[x_filtered(1) y_filtered(1)];
        
        lanes(2).path{k} = midLaneGlobal(end:-1:1,:);
        lanes(2).dir = 1; lanes(2).laneId = 2;
        lanes(2).leftLane{k} = laneRightGlobal(end:-1:1,:);
        lanes(2).width{k} = width(end:-1:1);
        lanes(2).rightLane{k} = laneLeftGlobal(end:-1:1,:);
        k = k+1;
    end
end

