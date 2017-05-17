%% read in images
tic
file_directory = './input_image1/';
fprintf(['\nUsing file: ' file_directory ' ...'])
fid = fopen( [file_directory 'focal_length.txt'], 'r');
image_num = str2double(fgets(fid));                         % read in first line
files = {};                                                 % testing purpose

% initialize
images = [];
focal_length = zeros(image_num, 1);

% read files
fprintf('\n\nReading all the image...\n')
for i = 1:image_num
  readline = fgets(fid);
  readline = strsplit(readline);
  files = cat(1, files, [file_directory readline{1}]);      % testing purpose
  img = imread([file_directory readline{1}]);               % read image 
  focal_length(i,1) = str2double(readline{2});              % read focal length
  images = cat(4, images, img);
end
toc
fprintf(['\n\nTotal ' num2str(image_num) ' images...\n'])


%% Feature Detection
tic
fprintf('\nFeature Detection...\n')

%SIFT
%addpath('./SIFTtutorial/')
%[pos, scale, orient, desc] = SIFT(images(:,:,:,1));

%feature
f = {};
feature_descriptor = {};
scale_level = 5;
%Mutil-Scale Oriented Patches
for i = 1:image_num 
    [f{i}, feature_descriptor{i}] = MSOP(images(:,:,:,i), scale_level);
end
toc

%Concatenate all images
%for i = 1:image_num 
%    marked_image = [marked_image insertMarker(images(:,:,:,i),f{i},'o','color','red','size',2)];
%end
%imshow(marked_image)

%% Cylindrical Projection
tic
fprintf('\nCylindrical Projection...\n')
[projected_images, masks, f] = cylindrical_projection(images, focal_length, f);
toc

%% Feature Matching
tic
fprintf('\nFeature Matching...\n')

matching_f = {};
for i = 1: (image_num - 1)
    for j = i+1 : image_num
        matching_f{i, j} = feature_matching(f{i}, f{j}, feature_descriptor{i}, feature_descriptor{j});
    end
end
toc
    
%% Image Matching and Blending
tic
fprintf('\nImage Matching and Blending...\n')

[images_out, images_starting_x, images_starting_y] = image_matching(projected_images, matching_f);   
images_starting_x = round(images_starting_x);
images_starting_y = round(images_starting_y);
linear = blending(images_out, images_starting_x, images_starting_y, 1, true);
multiband = blending(images_out, images_starting_x, images_starting_y, 2, true);

toc

%fprintf('\nRectangling the Panorama...\n')
%images_out2 = seam_carving(images_out2);
%figure(1)
%imshow(uint8(linear));
figure(2)
imshow(uint8(multiband));
fprintf('\nOutput Images...\n')
imwrite(uint8(linear), 'linear.jpg')
imwrite(uint8(multiband), 'multiband.jpg')

