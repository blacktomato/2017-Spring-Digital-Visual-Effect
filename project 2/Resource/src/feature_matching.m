% feature_matching
%   matching two images 

% Input
%   feature1 : the feature(fx fy) of first image (N1 x 2)
%   feature2 : the feature(fx fy) of second image (N2 x 2)
%   f_descriptor1 : the feature descriptor of first image (N1 x 64)
%   f_descriptor2 : the feature descriptor of second image (N1 x 64)

% Return:
%   matching_f: matching feature location (N_m, 4) [fx1 fy1 fx2 fy2]
%     N_m: number of matching features

function [matching_f] = feature_matching(feature1, feature2, f_descriptor1, f_descriptor2)
    %knn search with kdtree
    error_ratio = 0.8; 
    [min_size, smaller_one] = min([size(feature1, 1), size(feature2, 1)]);

    if (smaller_one == 1) % feature1 is less
        d1 = f_descriptor1;
        d2 = f_descriptor2;
        m2 = knnsearch(d2, d1, 'K', 2);
        m1 = knnsearch(d1, d2, 'K', 2);
        v1 = feature1;
        v2 = feature2(m2(:,1),:); 
    else % feature2 is less
        d1 = f_descriptor2;
        d2 = f_descriptor1;
        m2 = knnsearch(d2, d1, 'K', 2);
        m1 = knnsearch(d1, d2, 'K', 2);
        v1 = feature2;
        v2 = feature1(m2(:,1),:); 
    end

    k = [];
    for i = 1:min_size
        if m1(m2(i)) == i
            k = [k i];
        end
    end

    dd1_1 = d1(k,:);
    dd2_1 = d2(m2(k,1), :);
    dd2_2 = d2(m2(k,2), :);
    dis_1 = sqrt(sum((dd1_1 - dd2_1) .^ 2, 2));
    dis_2 = sqrt(sum((dd1_1 - dd2_2) .^ 2, 2));

    disp(size(dis_1))
    k = k(find(dis_1 < (error_ratio * dis_2)));

    if (smaller_one == 1) % feature1 is less
        matching_f = [v1(k, :) v2(k, :)];
    else
        matching_f = [v2(k, :) v1(k, :)];
    end

    %test
    %figure(1);
    %imshow([images(:,:,:,3), images(:,:,:,2)]);
    %for i = 1:size(fm1,1)
    %   line([fm2(i, 1) ,fm1(i,1)+384], [fm2(i,2), fm1(i,2)], 'marker', 'o');
    %end
end
