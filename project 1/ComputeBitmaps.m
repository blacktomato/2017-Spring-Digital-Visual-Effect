% Compute the threshold bitmap and the exclusion bitmap for the image

% input
%   image: m x n x 3 RGB image

% return
%   threshold_bitmap: pixel value > median: 1, else: 0
%   exclusion_bitmap: zeroed all bits where pixels are within กำ4 of the median value.

function [threshold_bitmap, exclusion_bitmap] = ComputeBitmaps(image)
  
  %% initialization
  exclude_threshold = 4;
  threshold_bitmap = zeros(size(image,1), size(image, 2));
  exclusion_bitmap = ones(size(image,1), size(image, 2));
  
  %% generate grey scale image and compute median
  grey = 54/256 .* image(:,:,1) + 183/256 .* image(:,:,2) + 19/256 .* image(:,:,3);
  threshold = median(grey(:));
  
  %% generate threshold_bitmap and exclusion_bitmap
  for i = 1:size(image,1)
    for j = 1:size(image,2)
      if grey(i,j) >= threshold
        threshold_bitmap(i,j) = 1; % else = 0 as initialized
      end
      if (grey(i,j) <= (threshold + exclude_threshold)) && (grey(i,j) >= (threshold - exclude_threshold))
        exclusion_bitmap(i,j) = 0;
      end
    end
  end
end