function snippets_out = createBoundingBoxes(snippets)
    % now recut the snippets - where type changes, we insert a breaking
    % point
    W = 1; % bounding box half width
    for n=1:length(snippets)
        % generate bounding boxes out of the snippets
        o = calculateOrientation(snippets{n}(:,1), snippets{n}(:,2));
        boundingBox(:,1:2) = [snippets{n}(:,1)-sin(o)*W snippets{n}(:,2)+cos(o)*W];
        boundingBox = [boundingBox; [snippets{n}(end:-1:1,1)+sin(o(end:-1:1))*W snippets{n}(end:-1:1,2)-cos(o(end:-1:1))*W]];

        snippets_out{n}.boundingBox(:,1:2) = DouglasPeuckerB(boundingBox(:,1:2),W); 
        snippets_out{n}.path = snippets{n};
        clear boundingBox
    end
end
