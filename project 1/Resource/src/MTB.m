% MTB median threshold bitmap for image alignment

% assume:
%   1. images are in order according to shutter speed
%   2. pyramid with height = 6

% input
%   images: an array of images with dimension N x m x n x 3
%     N: number of image
%     m: # row
%     n: # column
%     3: rgb three channels

% return:
%   each image shift (x,y) with respect to the n-th reference image among images
%   dimension: N x 1

function [n, X, Y] = MTB(images)

  %% initialization
  X = zeros(size(images,1), 1);
  Y = zeros(size(images,1), 1);
  pyramid_height = 6;

  %% select reference image
  n = round(size(images,1)/2);
  [~, threshold_pyramid_ref, exclusion_pyramid_ref]...
    = BuildPyramid(images(n,:,:,:), pyramid_height);
  
  %% MTB
  for i = 1:size(images,1)
    if i == n
      X(i,1) = 0;
      Y(i,1) = 0;
    else
      %% build pyramid
      [image_pyramid, threshold_pyramid, exclusion_pyramid]...
        = BuildPyramid(images(i,:,:,:), pyramid_height);
      
      %% compute translation (x,y)
      for j = pyramid_height:1
        % initialization
        best_x = 0;
        best_y = 0;
        least_diff = size(image_pyramid(j),2) * size(image_pyramid(j),3);
        
        % find optimal translation in current layer
        for x = -1:1
          for y = -1:1
            % translation
            th_tmp = imtranslate(threshold_pyramid(j), [x+X(i,1), y+Y(i,1)]);
            eb_tmp = imtranslate(exclusion_pyramid(j), [x+X(i,1), y+Y(i,1)]);
            
            % element wise XOR and AND
            diff_map = bitxor(th_tmp, threshold_pyramid_ref(j));
            diff_map = bitand(diff_map, eb_tmp);
            diff_map = bitand(diff_map, exclusion_pyramid_ref(j));
            diff = sum(diff_map(:));
            if diff < least_diff
              least_diff = diff;
              best_x = x;
              best_y = y;
            end
          end
        end
        
        % multiply 2 for the next layer in pyramid
        X(i,1) = X(i,1) * 2 + best_x;
        Y(i,1) = Y(i,1) * 2 + best_y;
      end
    end
  end
end