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

