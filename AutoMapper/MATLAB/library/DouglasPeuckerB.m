function result = DouglasPeuckerB(Points,epsilon)
% The Ramer-Douglas-Peucker algorithm (RDP) is an algorithm for reducing 
% the number of points in a curve that is approximated by a series of 
% points. The initial form of the algorithm was independently suggested 
% in 1972 by Urs Ramer and 1973 by David Douglas and Thomas Peucker and 
% several others in the following decade. This algorithm is also known 
% under the names Douglas鳳eucker algorithm, iterative end-point fit 
% algorithm and split-and-merge algorithm. [Source Wikipedia]
%
% Input:
%           Points: List of Points, double,  N x [x, y] 
%           epsilon: distance dimension, specifies the similarity between
%           the original curve and the approximated (smaller the epsilon,
%           the curves more similar), integer scalar.
%           Remark: You may add identifiers for the points, then List = N x [x, y, id]
% Output:
%           result: List of Points for the approximated curve M x [x, y],
%                   or M x [x, y, id] if identifiers were included.
% Example:
%           x = [8;  4;  5;  1;  0;  4;  8; 12; 11];
%           y = [0; -2;  2;  4; 10; 14;  8;  2;  0];
%           id = (1:9)';%identifier
%           Points = [x,y,id];
%           epsilon = 3;% Largest perpendicular distance from the new track to the original track
%           result = DouglasPeuckerB(Points,epsilon);
%           figure(1); plot(x,y,'.r-',result(:,1),result(:,2),'.b--'); grid on; axis equal
%           
%
% -------------------------------------------------------
% Original code by Reza Ahmadzadeh (2017), https://de.mathworks.com/matlabcentral/fileexchange/61046-douglas-peucker-algorithm 
% Altered  code by Peter Seibold   (2024) (Faster, vertical vectors in/out and identifiers)
% -------------------------------------------------------
edx = size(Points,1);% Index of last point in line segment

% Perpendicular distances d of the points Pp to the line segment
% Pp are all points within line segment
Pp = Points(2:edx-1,1:2);
x1 = Points(1,1);
y1 = Points(1,2);
dx = Points(edx,1)-x1;% x2-x1
dy = Points(edx,2)-y1;% y2-y1
den = sqrt(dx^2+dy^2);% denominator
if den > eps
  % segment is a line
  d = abs(dx*(y1-Pp(:,2))-(x1-Pp(:,1))*dy)/den;
else
  % segment is a point (line with zero length)
  d = sqrt((x1-Pp(:,1)).^2+ (y1-Pp(:,2)).^2);
end
[dmax,idx] = max(d);%[largest perpend. dist., index of it]
idx = idx+1;%shift by 1 since Pp(1,1) is at Points(2,1)

if dmax > epsilon
  % recursive call
  % from first point to vertex (idx) defined by dmax
  recResult1 = DouglasPeuckerB(Points(1:idx,:),epsilon);
  % from vertex to last point (edx), defined by previous line segment
  recResult2 = DouglasPeuckerB(Points(idx:edx,:),epsilon);
  result = [recResult1(1:size(recResult1,1)-1,:); recResult2(1:size(recResult2,1),:)];
else
  result = [Points(1,:); Points(edx,:)];
end
