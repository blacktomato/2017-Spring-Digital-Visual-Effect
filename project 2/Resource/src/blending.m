%% blending

% input
%   images_in: input images with dimension m x n x 3 x N
%   type: 1. linear
%         2. to be continue..

% output
%   images_out: output panorama image

function images_out = blending(images_in, images_starting_x, images_starting_y, type)
  %% init
  m = size(images_in,1);
  n = size(images_in,2);
  images_out = zeros(max(images_starting_x)+m-1, max(images_starting_y)+n-1, 3);
  for i = 1:m
    for j = 1:n
      for k = 1:3
        images_out(i,j,k) = images_in(i,j,k,1);
      end
    end
  end

  %% linear
  if type == 1
    for i = 2:size(images_in,4)
      left_most_x  = images_starting_x(i);
      right_most_x = images_starting_x(i-1) + m - 1;
      left_image_weight  = linspace(1,0,right_most_x-left_most_x+1);
      right_image_weight = linspace(0,1,right_most_x-left_most_x+1);
      for a = 1:m
        for b = 1:n
          for c = 1:3
            global_x = images_starting_x(i) + a - 1;
            global_y = images_starting_y(i) + b - 1;
            if (global_x) < right_most_x
              images_out(global_x,global_y,c) ...
                = images_out(global_x,global_y,c) * left_image_weight(global_x-left_most_x+1) ...
                + images_in(a,b,c) * right_image_weight(a);
            else
              images_out(global_x, global_y,c) = images_in(a,b,c);
            end
          end
        end
      end
    end
  
  %% else
  elseif type == 2
      
  %% illegal input type
  else
    fprintf('Illegal blending type!');
  end
end
