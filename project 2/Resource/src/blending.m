%% blending

% input
%   images_in: input images with dimension m x n x 3 x N
%   type: 1. linear
%         2. to be continue..
%   seam_carving: if apply seam_carving, set this to true;otherwise, false.

% output
%   images_out: output panorama image

function images_out = blending(images_in, images_starting_x, images_starting_y, type, seam_carving)
  %% init
  m = size(images_in{1,1,1,1},1);
  n = size(images_in{1,1,1,1},2);
  images_out = zeros(max(images_starting_y)+m-1, max(images_starting_x)+n-1, 3);
  if seam_carving
    images_out = images_out - 1;
  end
  
  images_out(1:m,1:n,:) = images_in{1,1,1,1}(:,:,:);

  %% linear
  if type == 1
    for i = 2:size(images_in,4)
      global_x = [1:n] + images_starting_x(i) - 1;
      global_y = [1:m] + images_starting_y(i) - 1;
      images_in_temp = zeros(max(images_starting_y)+m-1, max(images_starting_x)+n-1, 3)-1;
      images_in_temp(global_y, global_x, :) = images_in{1,1,1,i};

      [dummy, left_most_x, dummy] = ind2sub(size(images_in_temp), min(find(images_in_temp ~= -1)) );
      [dummy, right_most_x, dummy] = ind2sub(size(images_out), max(find(images_out ~= -1)) );
      intersection = right_most_x - left_most_x + 1;
      left_image_weight  = [ones(1, left_most_x - images_starting_x(i)) ...
                            linspace(1,0,intersection) ...
                            zeros(1, n - (right_most_x - images_starting_x(i)) - 1)];
      right_image_weight = 1 - left_image_weight;

      overlapping = (images_in_temp(global_y, global_x, :) ~= -1) & (images_out(global_y, global_x, :) ~= -1);
      left_part = (images_in_temp(global_y, global_x, :) == -1) & (images_out(global_y, global_x, :) ~= -1);
      right_part = (images_in_temp(global_y, global_x, :) ~= ~1) & (images_out(global_y, global_x, :) == -1);

      left_image_weight = repmat(left_image_weight, [m 1 3]) .* overlapping + left_part;
      right_image_weight = repmat(right_image_weight, [m 1 3]) .* overlapping + right_part;

      images_out(global_y,global_x,:) ...
        = images_out(global_y,global_x,:) .* left_image_weight ...
        + images_in{1,1,1,i} .* right_image_weight;
    end
  
  %% multiband
  elseif type == 2
    for i = 2:size(images_in,4)
      global_x = [1:n] + images_starting_x(i) - 1;
      global_y = [1:m] + images_starting_y(i) - 1;
      images_in_temp = zeros(max(images_starting_y)+m-1, max(images_starting_x)+n-1, 3)-1;
      images_in_temp(global_y, global_x, :) = images_in{1,1,1,i};

      [dummy, left_most_x, dummy] = ind2sub(size(images_in_temp), min(find(images_in_temp ~= -1)) );
      [dummy, right_most_x, dummy] = ind2sub(size(images_out), max(find(images_out ~= -1)) );

      overlapping = (images_in_temp(global_y, global_x, :) ~= -1) & (images_out(global_y, global_x, :) ~= -1);
      left_part = (images_in_temp(global_y, global_x, :) == -1) & (images_out(global_y, global_x, :) ~= -1);
      right_part = (images_in_temp(global_y, global_x, :) ~= ~1) & (images_out(global_y, global_x, :) == -1);

      M = floor(log2(max([m n])));
      p_left{1} = images_out(global_y, global_x, :) .* overlapping;
      p_right{1} = images_in_temp(global_y, global_x, :) .* overlapping;
      alpha = round((right_most_x + left_most_x - 2 * images_starting_x(i)) / 2);
      mp{1} = [ones(m, alpha) zeros(m, n-alpha)];
      mp{1} = imgaussfilt(mp{1}, 10);

      for j = 2:M
          p_left{j}  = imresize(p_left{j-1}, 0.5);
          p_right{j} = imresize(p_right{j-1}, 0.5);
          mp{j} = imresize(mp{j-1}, 0.5, 'bilinear');
      end

      % Laplician pyramid
      for j = 1 : M-1
          p_left{j} = p_left{j} - imresize(p_left{j+1}, [size(p_left{j},1), size(p_left{j},2)]);
          p_right{j} = p_right{j} - imresize(p_right{j+1}, [size(p_right{j},1), size(p_right{j},2)]);
      end  

      % Multi-band blending Laplician pyramid
      for j = 1 : M
          p_blending{j} = p_left{j} .* mp{j} + p_right{j} .* (1-mp{j});
      end
     
      % Laplician pyramid reconstruction
      im = p_blending{M};
      for j = M-1 : -1 : 1
          im = p_blending{j} + imresize(im, [size(p_blending{j},1) size(p_blending{j},2)]);
      end
 
      images_out(global_y,global_x,:) ...
        = im .* overlapping + images_out(global_y,global_x,:) .* left_part ...
        + images_in{1,1,1,i} .* right_part;
      imshow(uint8(images_out))
    end
      
  %% illegal input type
  else
    fprintf('Illegal blending type!');
  end
end
