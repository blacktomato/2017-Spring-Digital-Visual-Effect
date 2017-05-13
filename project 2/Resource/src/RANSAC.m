%% RANSAC algorithm

% image 1 translate with vector (x,y) to image 2 gives best image
% stitching outcome ( no rotation )

% input
%   feat_1: coordinates of  first feature points with dimension (N x 2)
%   feat_2: coordinates of second feature points with dimension (N x 2)
%   k     : times of iteration

% output
%   n_in   : number of inlier features
%   n_total: number of total features
%   x      : optimal shift x
%   y      : optimal shift y

%% RANSAC
function [n_in, n_total, best_x, best_y] = RANSAC(feat_1, feat_2)
  % parameters
  threshold = 10;
  
  % init
  best_x  = 0;
  best_y  = 0;
  n_in    = 0;
  n_total = size(feat_1,1); % fix number of total features 
  k = size(feat_1,1); % size(feat_1,1) == size(feat_2,1)
  
  % start RANSAC
  for i = 1:k
    tmp_x = feat_2(i,1) - feat_1(i,1);
    tmp_y = feat_2(i,2) - feat_1(i,2);
    n_in_tmp = 0;
    for j = 1:size(feat_1,1)
      if i == j
        continue;
      else
        if sqrt(( feat_2(j,1) - feat_1(j,1) - tmp_x)^2 + ...
                ( feat_2(j,2) - feat_1(j,2) - tmp_y)^2 ) <= threshold
          n_in_tmp = n_in_tmp + 1;
        end
      end
    end
    if n_in_tmp > n_in
      n_in   = n_in_tmp;
      best_x = tmp_x;
      best_y = tmp_y;
    end
  end
end