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
        % generate bounding boxes out of the snippets

        o = calculateOrientation(snippets{n}.path(:,1), snippets{n}.path(:,2));
        boundingBox(:,1:2) = [snippets{n}.path(:,1)-sin(o)*W snippets{n}.path(:,2)+cos(o)*W];
        boundingBox = [boundingBox; [snippets{n}.path(end:-1:1,1)+sin(o(end:-1:1))*W snippets{n}.path(end:-1:1,2)-cos(o(end:-1:1))*W]];

        snippets{n}.boundingBox(:,1:2) = DouglasPeuckerB(boundingBox(:,1:2),W);  
        clear boundingBox
    end
end
