% MSOP(Mutil-Scale Oriented Patches)

% Input
%   images: an array of images (m x n x 3)
%     m: # row
%     n: # column
%     3: rgb three channels
%   maxlevel: the highest scale level would be used in the MSOP (1 x 1)

% Return:
%   f: feature_location (N, 2) [fx, fy]
%     N: number of features
%   feature_descriptor: a 64D vector used to represent a feature (N x 64)
%     N: number of features

function [f, feature_descriptor] = MSOP(image, maxlevel)
    pyramid = {single(image)};
    [height, width, dump] = size(image);
    is_feature            = zeros([height, width]);
    feature_level         = zeros([height, width]);
    feature_orientation   = zeros([height, width]);
    response_threshold = 10;
    f = [];
    feature_descriptor = [];

    %Change RGB into YCbCr(GrayScale)
    K = [0.299 0.578 0.114];
    K = reshape(K, [1 1 3]);
    K = repmat(K, [size(pyramid{1},1) size(pyramid{1},2)]);

    %Build pyramid to do the Multi-Scale Oriented Patches
    pyramid{1} = dot(pyramid{1}, K, 3); 
    maxlevel = 5;

    for level = 2:maxlevel
        pyramid{level} = imgaussfilt(pyramid{level-1}, 1);
        pyramid{level} = pyramid{level}(1:2:end, 1:2:end); 
    end

    %Calculate the response for Harris Corner Detection
    for level = 1:maxlevel
        [h w] = size(pyramid{level});
        Ix = imgaussfilt(gradient(pyramid{level}), 1);
        Iy = imgaussfilt(gradient(pyramid{level}'), 1);
        Iy = Iy';
        Ix2 = Ix .* Ix;
        Iy2 = Iy .* Iy;
        Ixy = Ix .* Iy;
        Ix2 = imgaussfilt(Ix2, 1.5);
        Iy2 = imgaussfilt(Iy2, 1.5);
        Ixy = imgaussfilt(Ixy, 1.5);
        response = (1) .* ( Ix2 .* Iy2 - Ixy .* Ixy) ./ (Ix2 + Iy2);
        response(find(isnan(response))) = 0;
        
        se = strel('square', 3);
        feature_p = response .* (imdilate(response, se) <= response) .* (response > response_threshold);

        %orientation
        theta = atan(Iy ./ Ix);

        [fy, fx] = ind2sub(size(feature_p), find(feature_p));
        fo = theta(find(feature_p));

        % 40 x 40 window
        r = [20 20; 20 -20; -20 -20; -20 20]'; 
        window_x = int32( [cos(fo) -sin(fo)] * r + fx );
        window_y = int32( [sin(fo)  cos(fo)] * r + fy );
        out_boundary = sum(window_x > w | window_x <= 0 , 2) + ...
                       sum(window_y > h | window_y <= 0 , 2);
        feature_inside = find(out_boundary == 0);
        %fprintf('\nlevel: %d\n\n',level)

        %no feature
        if(isempty(feature_inside))
            continue;
        else
            for i = 1:size(feature_inside, 1)
                new_feature = [fx(feature_inside(i)); fy(feature_inside(i))] * 2 ^ (level-1);
                %scale by the level
                if (is_feature(new_feature(2), new_feature(1)))
                    if (is_feature(new_feature(2), new_feature(1)) < ...
                        response(fy(feature_inside(i)), fx(feature_inside(i))))
                        %replace original feature with higher response 
                        is_feature(new_feature(2), new_feature(1)) = ...
                            response(fy(feature_inside(i)), fx(feature_inside(i)));
                        feature_orientation(new_feature(2), new_feature(1)) = fo(feature_inside(i));
                        feature_level(new_feature(2), new_feature(1)) = level;
                    end
                else
                    is_feature(new_feature(2), new_feature(1)) = ...
                        response(fy(feature_inside(i)), fx(feature_inside(i)));
                    feature_orientation(new_feature(2), new_feature(1)) = fo(feature_inside(i));
                    feature_level(new_feature(2), new_feature(1)) = level;
                end
            end
        end
    end

    % Non-Maximal Suppression
    radius = 5;
    d_radius = 1;
    f_number = sum(sum(is_feature > 0));
    %fprintf('\nf_number: %d', f_number);

    while( f_number > 500 )
        f_ind = find(is_feature);
        [fy, fx] = ind2sub([height, width], f_ind); 
        remove_candidate = triu(squareform(pdist([fx fy]) < radius)); 

        [p1, p2] = ind2sub(size(remove_candidate),find(remove_candidate)); 
        for i = 1:size(p1)
            if (is_feature(fy(p1(i)),  fx(p1(i))) * is_feature(fy(p2(i)), fx(p2(i))) ~= 0)
                %keep the one with larger response
                if is_feature(fy(p1(i)),  fx(p1(i))) <= is_feature(fy(p2(i)), fx(p2(i)))
                    is_feature(fy(p1(i)),  fx(p1(i))) = 0;
                else
                    is_feature(fy(p2(i)),  fx(p2(i))) = 0;
                end
            end 
        end
        f_number = sum(sum(is_feature > 0));
        radius = radius + d_radius;
        %fprintf('\nf_number: %d', f_number);
    end
    
    % calculate the descriptor
    for level = 1:maxlevel
        x = [-19:20];
        y = [-19:20];
        y = transpose(y);

        x = repmat( x, [40 1] );
        y = repmat( y, [1 40] );
        
        d = cat(3, x, y);
        d = permute(d, [3 1 2]);

        f_ind = find(is_feature .* (feature_level == level));

        for i = 1:size(f_ind, 1)
            [fy, fx] = ind2sub([height, width], f_ind(i));

            f = [f ;[fx fy]];
            o = feature_orientation(f_ind(i));
            x = int32(reshape(d(1,:,:) * cos(o) + d(2,:,:) * (-sin(o)), [40 40]));
            y = int32(reshape(d(1,:,:) * sin(o) + d(2,:,:) * ( cos(o)), [40 40]));
            x = x + fx / 2 ^ (level-1);
            y = y + fy / 2 ^ (level-1);
            
            window = sub2ind(size(pyramid{level}), y, x);
            window = pyramid{level}(window);
            sample = window(:, 1:5:end) + window(:, 2:5:end) + ...
                     window(:, 3:5:end) + window(:, 4:5:end) + ...
                     window(:, 5:5:end);
            sample = sample(1:5:end, :) + sample(2:5:end, :) + ...
                     sample(3:5:end, :) + sample(4:5:end, :) + ...
                     sample(5:5:end, :);

            sample = sample ./ 25;

            feature_descriptor = [feature_descriptor; reshape(sample', 1, []) ];
        end
    end
    fprintf('The highest scale level able to be used: %d\n', max(max(feature_level)));
end
