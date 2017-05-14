% cylindrical projection with triangle filter

% Input
%   images: an array of images (m x n x 3 x N)
%     m: # row
%     n: # column
%     3: rgb three channels
%     N: number of image
%   f: focal length for each image in the images (N x 1)
%   f_p: feature points for each image in the images (N x 1 cell)

% Return:
%   projected_images: images after operated cylindrical projection (m x n x 3 x N)
%   masks: the region of the projected images (m x n x N logical array)
%   projected_f_p: feature points after operated cylindrical projection (N x 1 cell)

function [projected_images, masks, projected_f_p] = cylindrical_projection( images, f, f_p)

    projected_images = [];
    masks = [];
    projected_f_p = {};
    image_num = size(images, 4);
    for i = 1:image_num
        % find the transformed boundary
        img = images(:,:,:,i);

        %inverse warping
        s = size(img);
        p_img = zeros(s);
        x = [1:s(2)] - floor(s(2)/2);
        y = [1:s(1)] - floor(s(1)/2);
        y = transpose(y);

        %projected x and y
        p_x = repmat( x, [s(1) 1] );
        p_y = repmat( y, [1 s(2)] );

        %original x and y
        o_x = tan(p_x ./ f(i)) .* f(i);
        o_y = p_y ./ f(i) .* sqrt(o_x .^ 2 + f(i) ^ 2);
        o_x = o_x + floor(s(2)/2);
        o_y = o_y + floor(s(1)/2);
        mask = (o_x >= 1) & (o_y >= 1);
        o_x = o_x .* (o_x >= 1);
        o_y = o_y .* (o_y >= 1);
        o_x = o_x + (o_x == 0);
        o_y = o_y + (o_y == 0);

        mask = mask & (o_y <= s(1)) & (o_x <= s(2));
        o_x = o_x .* (o_x < s(2));
        o_y = o_y .* (o_y < s(1));
        o_x = o_x + (o_x == 0) * (s(2) - 1);
        o_y = o_y + (o_y == 0) * (s(1) - 1);
        a = mod(o_x, 1);
        b = mod(o_y, 1);

        %inverse warping triangle filter
        for j = 1:3     %RGB
            grayscale = double(img(:,:,j));
            s_g = size(grayscale);
            p_img(:,:,j) = (1 - a) .* (1 - b) .* grayscale(sub2ind(s_g, floor(o_y    ), floor(o_x    ))) ...
                         +      a  .* (1 - b) .* grayscale(sub2ind(s_g, floor(o_y + 1), floor(o_x    ))) ...
                         + (1 - a) .*      b  .* grayscale(sub2ind(s_g, floor(o_y    ), floor(o_x + 1))) ...
                         +      a  .*      b  .* grayscale(sub2ind(s_g, floor(o_y + 1), floor(o_x + 1)));
            p_img(:,:,j) = p_img(:,:,j) .* mask;
        end
        masks = cat(3, masks, mask);
        projected_images = cat(4, projected_images, p_img);
        
        if ~exist('f_p')
            continue;
        else
            projected_f_p{i} = f_p{i} - floor([s(2) s(1)] ./ 2);
            h = sqrt(projected_f_p{i}(:, 1) .^ 2 + f(i) .^ 2);
            projected_f_p{i}(:, 1)= f(i) * atan(projected_f_p{i}(:, 1) ./ f(i));
            projected_f_p{i}(:, 2)= f(i) * projected_f_p{i}(:, 2) ./ h;
            projected_f_p{i} = projected_f_p{i} + floor([s(2) s(1)] ./ 2);
        end

    end
end
