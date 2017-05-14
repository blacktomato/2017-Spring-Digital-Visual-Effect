% simplify seam-carving function to rectangularize the parorama image
%
% input
%   image_in: input image with irregular boundaries (dim: n x m x 3)

% output
%   reshaped (rectangular) image after seam carving (dim: n x m x 3)

% reference:
%   [1] Seam Carving for Content-Aware Image Resizing
%   [2] Rectangling Panoramic Images via Warping

function image_out = seam_carving(image_in)
  % init
  very_big_float = 100000.0; % for gradient map
  % for direction map
  up    = 1;
  down  = 2;
  left  = 3;
  
  while(true)
    % search for upper horizontal boundary segment
    fprintf('\nSearching boundary segment...\n')
    x_start = 0;
    x_end = 0;
    started = false;
    x_start_tmp = 0;
    x_end_tmp = 0;
    longest_segment = 0;
    for i = 1:size(image_in,2)
      if (image_in(1,i,1) == -1) && (image_in(1,i,2) == -1) && (image_in(1,i,3) == -1)
        if (started == false)
          x_start_tmp = i;
          x_end_tmp = i;
          started = true;
        else
          x_end_tmp = i;
        end
      else
        if (started == true)
          if (x_end_tmp - x_start_tmp + 1) > longest_segment
            x_start = x_start_tmp;
            x_end = x_end_tmp;
            longest_segment = x_end_tmp - x_start_tmp + 1;
          end
        end
        started = false;
      end
    end
    
    % no more boundary segment
    if (longest_segment == 0)
      break;
    end
    
    fprintf('\nConverting into black and white image...\n')
    % turn colorful image into black and white by equation in MTB
    grey = 54/256  .* image_in(:,x_start:x_end,1) ...
         + 183/256 .* image_in(:,x_start:x_end,2) ...
         + 19/256  .* image_in(:,x_start:x_end,3);
    
    fprintf('\nComputing gradient...\n')
    % compute gradient using default Sobel's method
    [Gmag, ~] = imgradient(grey);
    
    % remove the effect from pixels outside the boundary ( which have very
    % low gradient and may affect the result
    for i = 1:size(Gmag,1)
      for j = 1:size(Gmag,2)
        if (image_in(i,x_start+j-1,1) == -1) && ...
           (image_in(i,x_start+j-1,2) == -1) && ...
           (image_in(i,x_start+j-1,3) == -1)
          Gmag(i,j) = very_big_float;
        end
      end
    end
    
    % init directional map
    Dmap = zeros(size(Gmag,1), size(Gmag,2));
    
    fprintf('\nDynamic Programming...\n')
    % dynamic programming
    % start from 2nd column 
    % M(i, j) = e(i, j) + min(M(i?1, j?1),M(i, j-1),M(i+1, j-1))
    for j = 2:size(Gmag,2)
      for i = 1:size(Gmag,1)
        if i == 1 % first row
          m = min(Gmag(i,j-1), Gmag(i+1,j-1));
          Gmag(i,j) = Gmag(i,j) + m;
          if m == Gmag(i,j-1)
            Dmap(i,j) = left;
          else
            Dmap(i,j) = down;
          end
        elseif i == size(Gmag,1) % last row
          m = min(Gmag(i-1,j-1), Gmag(i,j-1));
          Gmag(i,j) = Gmag(i,j) + m;
          if m == Gmag(i-1,j-1)
            Dmap(i,j) = up;
          else
            Dmap(i,j) = left;
          end
        else
          m = min(Gmag(i-1,j-1), Gmag(i,j-1), Gmag(i+1,j-1));
          Gmag(i,j) = Gmag(i,j) + m;
          if m == Gmag(i-1,j-1)
            Dmap = up;
          elseif m == Gmag(i,j-1)
            Dmap = left;
          else
            Dmap = down;
          end
        end
      end
    end
    
    fprintf('\nShifting by 1 pixel...\n')
    % find smallest in the last column
    smallest_value = 10000000000.0;
    smallest_id = 0;
    last_col = size(Gmag,2);
    for i = 1:size(Gmag,1)
      if Gmag(i,last_col) < smallest_value
        smallest_value = Gmag(i,last_col);
        smallest_id = i;
      end
    end
    
    if (smallest_id == 0) || (smallest_id == 1)
      fprintf('\nError: should not come here!...\n')
      break; % didn't find ( this should never happen )
    end
    
    for col = x_end:x_start:-1
      for row = 2:size(Gmag,1)
          
        % shift image
        if row < smallest_id
          image_in(row-1,col,:) = image_in(row,col,:);
        elseif (row == smallest_id) && (row == size(Gmag,1)) %% last row
          image_in(row-1,col,:) = image_in(row,col,:);
        elseif (row == smallest_id) && (row ~= size(Gmag,1)) %% not last row
          tmp = image_in(row-1,col,:);
          image_in(row-1,col,:) = image_in(row,col,:);
          image_in(row,col) = 0.5 * (tmp + image_in(row+1,col,:));
        end
        
        % update smallest_id
        if smallest_id == up
          smallest_id = smallest_id - 1;
        elseif smallest_id == down
          smallest_id = smallest_id + 1;
        end
      end
    end  
  end
  image_out = image_in;
end

