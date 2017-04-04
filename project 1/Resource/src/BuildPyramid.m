% build an image pyramid with height = input arg 'height'

function [image_pyramid, threshold_pyramid, exclusion_pyramid] = BuildPyramid(image, height)
  % first layer (original image)
  [threshold_bitmap_1, exclusion_bitmap_1] = ComputeBitmaps(image);
  image_pyramid = {image};
  threshold_pyramid = {threshold_bitmap_1};
  exclusion_pyramid = {exclusion_bitmap_1};
  % rest layers
  for j = 2:height
    image_pyramid = cat(1, image_pyramid, impyramid(image_pyramid(j-1), 'reduce'));
    [th_tmp, eb_tmp] = ComputeBitmaps(image_pyramid(j));
    threshold_pyramid = cat(1, threshold_pyramid, th_tmp);
    exclusion_pyramid = cat(1, exclusion_pyramid, eb_tmp);
  end
end