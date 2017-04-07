%% 2017 Spring VFX Project 1 - HDR
%  Author: b03901032 Tzu-Sheng Kuo, b02901001 Sheng-Lung Chung
%  Date: 2017/03 - 2017/04

%  Assume:
%   codes are under directory src/ 
%   images and image_list.txt are under directory input_images/

%   image_list.txt format:
%   line 1: numebr of images (an integer)
%   line 2: <image_filename> <space> <shutter_speed>
%   .
%   .
%   line N: ...

%  Settings:
clear;
clc;

default_remove_blue_background    = false;

default_image_alignment           = false;
default_apply_MTB                 = true;

default_apply_Debevec             = false;
default_apply_Robertson           = true;

default_apply_tone_mapping_global = true;
default_apply_tone_mapping_local  = false;
default_tone_mapping_saturation   = 0.5;

%% read in images
fid = fopen('../input_image/image_list.txt', 'r');
image_num = str2double(fgets(fid)); % read in first line
files = {}; % testing purpose
% initialize
images = [];
shutter_speed = zeros(image_num, 1);
% read files
for i = 1:image_num
  readline = fgets(fid);
  readline = strsplit(readline);
  files = cat(1, files, strcat('../input_image/',readline{1,1})); % testing purpose
  img = imread(strcat('../input_image/',readline{1,1})); % read image 
  shutter_speed(i,1) = str2double(readline{1,2}); % read shutter speed
  images = cat(4, images, img);
end

expTimes = 1./shutter_speed; % testing purpose

%% remove pure blue background
if default_remove_blue_background
  for i = 1:image_num
    for j = 1:size(images,1)
      for k = 1:size(images,2)
        if images(j,k,1,i) == 0 && images(j,k,2,i) == 0 && images(j,k,3,i) == 255
          images(j,k,3,i) = 0;
        end
      end
    end
  end
end

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

%{
%show aligned images ( debugging purpose )
for i = 1:image_num
  imshow(aligned_images(:,:,:,i));
end
%}

% image cropping ( not implemented yet! )

%% generate HDR image
if default_apply_Debevec
  hdr = DebevecHDR(images, shutter_speed);
elseif default_apply_Robertson
  hdr = RobertsonHDR(images, shutter_speed);
else
  hdr = makehdr(files, 'ExposureValues', expTimes); % matlab default
end

%% tone mapping
if default_apply_tone_mapping_global
  ldr = tonemapping_global(hdr, default_tone_mapping_saturation);
elseif default_apply_tone_mapping_local
  [ldr,~] = tonemapping_local(hdr, default_tone_mapping_saturation);
else
  ldr = tonemap(hdr)
end

%% Test
imshow(ldr);
%imshowpair(ldr, ldr_test, 'montage');
