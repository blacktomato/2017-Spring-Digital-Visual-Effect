%% image matching using RANSAC

% input
%   images_in: input images with dimension m x n x 3 x N
%   feat     : input image cell array featues with dimension N x N
%              inside each call is an array with dimension N x 2
%              for example, cell at (2,1) is the matching feature of the
%              second image and the first image. 

% output
%   images_out: output images with dimension m x n x 3 x N'
%               ( N' may not equal to N after filtering out noisy images )
%   images_starting_x  : global x coordinates for the leftmost and upmost 
%                        point in images ( dimension: N' )
%   images_starting_y  : global y coordinates for the leftmost and upmost 
%                        point in images ( dimension: N' )
%  ------------------
% | * <- (x,y) of    |
% |      this point  |
% |                  |
% |                  |
% |                  |
% |                  |
%  ------------------

function [images_out, images_starting_x, images_starting_y] = image_matching(images_in, feat)
  %% select first image as reference at the beginning
  images_out = {images_in(:,:,:,1)};
  images_starting_x = [1];
  images_starting_y = [1];
  ref_id     = 1;
  
  %% init for loop
  selected_id = {};
  
  %% accumulated translation
  x_total = 0;
  y_total = 0;
  
  %% find the image which matches refernce image the most
  for i = 1:size(images_in,4)
    %% init
    n_in_best = 0;
    n_total_best = 1;
    x_best = 0;
    y_best = 0;
    end_loop = true; % if end_loop == true, end the for loop
    selected_id_tmp = -1;
    %% RANSAC
    for j = 1:size(images_in,4)
      if (ref_id == j) || (any(cellfun(@(x) isequal(x, j), selected_id)))
        continue % skip if same as current one or have already been selected
      else
        if ref_id < j
          feat_ref = feat{ref_id,j}(:,1:2);
          feat_current = feat{ref_id,j}(:,3:4);
        else
          feat_ref = feat{j,ref_id}(:,3:4);
          feat_current = feat{j,ref_id}(:,1:2);
        end
        [n_in, n_total, x, y] = RANSAC(feat_current, feat_ref);
        if (n_in > 5.9 + 0.22 * n_total) && (n_in/n_total > n_in_best/n_total_best)
          n_in_best = n_in;
          n_total_best = n_total;
          x_best = x;
          y_best = y;
          end_loop = false;
          selected_id_tmp = j;
        end
      end
    end
    
    if end_loop
      break; % no matching images left (filter out noisy images)
    end
    ref_id = selected_id_tmp;
    selected_id = cat(1, selected_id, selected_id_tmp);
    x_total = x_total + x_best;
    y_total = y_total + y_best;
    images_starting_x = cat(1, images_starting_x, x_total);
    images_starting_y = cat(1, images_starting_y, y_total);
    images_out = cat(4, images_out, images_in(:,:,:,selected_id_tmp));
  end
  %% check if x and y out of boundary ( < 0)
  x_min = min(images_starting_x);
  y_min = min(images_starting_y);
  if x_min < 1
    x_min = abs(x_min) + 1;
    images_starting_x = images_starting_x + x_min;
  end
  if y_min < 1
    y_min = abs(y_min) + 1;
    images_starting_y = images_starting_y + y_min;
  end
end