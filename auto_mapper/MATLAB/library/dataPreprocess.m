function lanes = dataPreprocess(data)
    [x,y,~] = deg2utm(data.ADMA_INS_Lat_Abs_POI1,data.ADMA_INS_Long_Abs_POI1);

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
    BV_Linie_01_dy_filtered = data.BV_Linie_01_dy(f);
    BV_Linie_02_dy_filtered = data.BV_Linie_02_dy(f);
    
    laneLeft = [path(f2,1)-sin(theta(f2)).*BV_Linie_01_dy_filtered(f2)' path(f2,2)+cos(theta(f2)).*BV_Linie_01_dy_filtered(f2)'];
    laneRight = [path(f3,1)-sin(theta(f3)).*BV_Linie_02_dy_filtered(f3)' path(f3,2)+cos(theta(f3)).*BV_Linie_02_dy_filtered(f3)'];

    c0 = 0.5*(BV_Linie_01_dy_filtered(f2&f3)+BV_Linie_02_dy_filtered(f2&f3));
    width = BV_Linie_01_dy_filtered(f2&f3)-BV_Linie_02_dy_filtered(f2&f3);
    midLane = [path(f2&f3,1)-sin(theta(f2&f3)).*c0' path(f2&f3,2)+cos(theta(f2&f3)).*c0'];

    midLaneGlobal = midLane*T+[x_filtered(1) y_filtered(1)];
    laneLeftGlobal = laneLeft*T+[x_filtered(1) y_filtered(1)];
    laneRightGlobal = laneRight*T+[x_filtered(1) y_filtered(1)];

    lanes.path = midLaneGlobal;
    lanes.leftLane = laneLeftGlobal;
    lanes.width = width;
    lanes.rightLane = laneRightGlobal;
    
end

