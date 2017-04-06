% HDR function based on Debevec SIGGRAPH 1997

% Assume:
%   Zmin = 0
%   Zmax = 255
%   lamdba = 1
%   default_sample_num = 50

% input:
%   images: an array of images with dimension m x n x 3 x N
%     m: # row
%     n: # column
%     3: rgb three channels
%     N: number of image
%   shutter_speed: an array of shutter_speed with dimension N x 1

% output:
%   hdr: an HDR image with dimension m x n x 3

% function [g,lE] = DebevecGsolve(Z,B,l,w)
%   input: 
%     Z(i,j) is the pixel values of pixel location number i in image j
%     B(j)   is the log delta t, or log shutter speed, for image j
%     l      is lamdba, the constant that determines the amount of smoothness
%     w(z)   is the weighting function value for pixel value z

%   output:
%     g(z)   is the log exposure corresponding to pixel value z
%     lE(i)  is the log fil irradiance at pixel location i

function hdr = DebevecHDR(images, shutter_speed)
  %% initialization and assumption
  Zmin = 0;
  Zmax = 255;
  
  % l (const)
  l = 1;
  
  % B(j)
  B = log(1./shutter_speed);
  
  % w(z)
  w = zeros(Zmax - Zmin + 1, 1); % (256,1)
  for i = 1:size(w,1)
    if (i-1) <= (Zmin + Zmax)/2
      w(i) = (i-1) - Zmin;
    else
      w(i) = Zmax - (i-1);
    end
  end
  
  % Z(i,j)
  default_sample_num = 50;
  sample_pixels_x = randi(size(images,1), default_sample_num, 1);
  sample_pixels_y = randi(size(images,2), default_sample_num, 1);
  
  %% compute g(z) of RGB 3 channels
  g = [];
  for i = 1:3 % RGB 3 channels
    Z = zeros(default_sample_num, size(images,4));
    for j = 1:size(Z,1)
      for k = 1:size(Z,2)
        Z(j,k) = images(sample_pixels_x(j), sample_pixels_y(j), i, k);
      end
    end
    [g_tmp,~] = DebevecGsolve(Z,B,l,w);
    g = cat(3, g, g_tmp);
  end
  
  %% generate HDR image
  hdr = zeros(size(images,1), size(images,2), 3);
  for i = 1:size(images,1)
    for j = 1:size(images,2)
      for k = 1:3
        numerator_tmp = 0;
        denominator_tmp = 0;
        for p = 1:size(images,4)
          Zij = images(i,j,k,p) + 1; % add 1 due to matlab index
          numerator_tmp = numerator_tmp + w(Zij)*(g(Zij) - B(p));
          denominator_tmp = denominator_tmp + w(Zij);
        end
        hdr(i,j,k) = exp(numerator_tmp / denominator_tmp);
      end
    end
  end
end