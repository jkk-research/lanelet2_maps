function lanes = dataPreprocess(data, options)
    [x,y,utm_zone] = deg2utm(data.ADMA_INS_Lat_Abs_POI1,data.ADMA_INS_Long_Abs_POI1);

    % redundant point filter
    f = (abs(diff(x))>0) & (data.ADMA_Status_GNSS_Mode(1:end-1)'==8);
    x_filtered = x(f);
    y_filtered = y(f);

    path = [x_filtered y_filtered];
    if (options.fillHoles)
        laneLeft = zeros(size(path,1),2);
        laneRight = zeros(size(path,1),2);
        midLane = zeros(size(path,1),2);
        width = zeros(size(path,1),1);
    end

    % orientation
    theta = calculateOrientation(x_filtered, y_filtered);

    % adding lane edges and midlane
    f2 = data.BV_Linie_01_Existenzmass(f) > 0.75;
    f3 = data.BV_Linie_02_Existenzmass(f) > 0.75;
    BV_Linie_01_dy_filtered = data.BV_Linie_01_dy(f);
    BV_Linie_02_dy_filtered = data.BV_Linie_02_dy(f);
    
    c0 = 0.5*(BV_Linie_01_dy_filtered(f2&f3)+BV_Linie_02_dy_filtered(f2&f3));    

    if (options.fillHoles)
        laneLeft(f2&f3,:) = [path(f2&f3,1)-sin(theta(f2&f3)).*BV_Linie_01_dy_filtered(f2&f3)' path(f2&f3,2)+cos(theta(f2&f3)).*BV_Linie_01_dy_filtered(f2&f3)'];
        laneRight(f2&f3,:) = [path(f2&f3,1)-sin(theta(f2&f3)).*BV_Linie_02_dy_filtered(f2&f3)' path(f2&f3,2)+cos(theta(f2&f3)).*BV_Linie_02_dy_filtered(f2&f3)'];
        midLane(f2&f3,:) = [path(f2&f3,1)-sin(theta(f2&f3)).*c0' path(f2&f3,2)+cos(theta(f2&f3)).*c0'];
        width(f2&f3,:) = BV_Linie_01_dy_filtered(f2&f3)-BV_Linie_02_dy_filtered(f2&f3);
        
        w = mean(width(f2&f3));
        laneLeft(~(f2&f3),:) = [path(~(f2&f3),1)-sin(theta(~(f2&f3)))*w/2 path(~(f2&f3),2)+cos(theta(~(f2&f3)))*w/2];
        laneRight(~(f2&f3),:) = [path(~(f2&f3),1)-sin(theta(~(f2&f3)))*(-w/2) path(~(f2&f3),2)+cos(theta(~(f2&f3)))*(-w/2)];
        midLane(~(f2&f3),:) = [path(~(f2&f3),1) path(~(f2&f3),2)];

        width(~(f2&f3),:) = w;
    else
        laneLeft = [path(f2&f3,1)-sin(theta(f2&f3)).*BV_Linie_01_dy_filtered(f2&f3)' path(f2&f3,2)+cos(theta(f2&f3)).*BV_Linie_01_dy_filtered(f2&f3)'];
        laneRight = [path(f2&f3,1)-sin(theta(f2&f3)).*BV_Linie_02_dy_filtered(f2&f3)' path(f2&f3,2)+cos(theta(f2&f3)).*BV_Linie_02_dy_filtered(f2&f3)'];
        midLane = [path(f2&f3,1)-sin(theta(f2&f3)).*c0' path(f2&f3,2)+cos(theta(f2&f3)).*c0'];
        width = BV_Linie_01_dy_filtered(f2&f3)-BV_Linie_02_dy_filtered(f2&f3);
    end
    
    lanes.path = midLane;
    lanes.leftLane = laneLeft;
    lanes.width = width;
    lanes.rightLane = laneRight;    
end

