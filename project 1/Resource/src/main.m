%% 2017 Spring VFX Project 1 - HDR
%  Author: b03901032 Tzu-Sheng Kuo, b02901
%  Date: 2017/03

%  Assume:
%   codes are under directory src/ 
%   images and image_list.txt are under directory input_images/

%   image_list.txt format:
%   line 1: numebr of images (an integer)
%   line 2: <image_filename> <space> <1/shutter_speed>
%   .
%   .
%   line N: ...

%  Settings:
clear;
clc;
default_image_alignment           = true;
default_apply_MTB                 = true;
default_apply_Debevec             = true;
default_apply_tone_mapping_global = true;
default_tone_mapping_saturation   = 0.5;


%% debugging purpose
files = {};

%% read in images
fid = fopen('../input_image/image_list.txt', 'r');
image_num = str2double(fgets(fid)); % read in first line
% initialize
images = [];
shutter_speed = zeros(image_num, 1);
% read files
for i = 1:image_num
  readline = fgets(fid);
  readline = strsplit(readline);
  files = cat(1, files, strcat('../input_image/',readline{1,1})); % debugging purpose
  img = imread(strcat('../input_image/',readline{1,1})); % read image 
  shutter_speed(i,1) = str2double(readline{1,2}); % read shutter speed
  images = cat(4, images, img);
end

expTimes = 1./shutter_speed; % debug

%{
for i = 1:image_num
  for j = 1:size(images,1)
    for k = 1:size(images,2)
      if images(j,k,1,i) == 0 && images(j,k,2,i) == 0 && images(j,k,3,i) == 255
        images(j,k,3,i) = 0;
      end
    end
  end
end
%}

%% image alignment
aligned_images = [];
reference_id = round(size(images,4)/2);
if default_image_alignment && default_apply_MTB
  [offset_X, offset_Y] = MTB(images, reference_id);
else
  offset_X = zeros(size(images,1), 1);
  offset_Y = zeros(size(images,1), 1);  
end

for i = 1:image_num
  aligned_images = cat(4, aligned_images, imtranslate(images(:,:,:,i), [offset_X(i,1), offset_Y(i,1)]));
end

%show aligned images ( debugging purpose )
for i = 1:image_num
  imshow(aligned_images(:,:,:,i));
end

% image cropping ( not implemented yet! )

%% generate HDR image
hdr = DebevecHDR(images, shutter_speed);
%hdr_test = makehdr(files, 'ExposureValues', expTimes);

%% tone mapping
if default_apply_tone_mapping_global
  ldr = tonemap(hdr);
  ldr_test = tonemapping_global(hdr, default_tone_mapping_saturation);
  %ldr_test = tonemapping_global(hdr_test, default_tone_mapping_saturation);
else
  [ldr,~] = tonemapping_local(hdr, default_tone_mapping_saturation);
end

%% Test
%imshow(ldr);
%imshow(ldr_test);
imshowpair(ldr, ldr_test, 'montage');
