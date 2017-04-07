% HDR function based on Robertson's Method 2003

% Assume:
%   Xmin = 0
%   Xmax = 255
%   default_interation_num = 10

% input:
%   images: an array of images with dimension a x b x 3 x N
%     a: # row
%     b: # column
%     3: rgb three channels
%     N: number of image
%   shutter_speed: an array of shutter_speed with dimension N x 1

% output:
%   hdr: an HDR image with dimension a x b x 3

% parameters:
%   t: exposure time
%   I:
%   w: weighted function based on paper
%   x:

function hdr = RobertsonHDR(images, shutter_speed)
  %% initialization
  default_interation_num = 10;
  t = 1./shutter_speed;
  I_tmp = linspace(0,2,256);
  I = cat(3, I_tmp, I_tmp, I_tmp); % size: 1 x 256 x 3
  y = 0:255;
  w = exp(-4 * (y - 127.5).^2 / (127.5)^2);
  x = zeros(size(images,1), size(images,2),3); % a x b x 3 channels
  for c = 1:3
    for a = 1:size(x,1)
      for b = 1:size(x,2)
        numerator_tmp = 0;
        denominator_tmp = 0;
        for i = 1:size(images,4)
          wij = w(1,images(a,b,c,i)+1);
          Iyij = I(1,images(a,b,c,i)+1,c);
          numerator_tmp = numerator_tmp + wij*t(i)*Iyij;
          denominator_tmp = denominator_tmp + wij*t(i)^2;
        end
        x(a,b,c) = numerator_tmp / denominator_tmp;
      end
    end
  end
  
  %% iteration
  for l = 1:default_interation_num
    % update I
    for c = 1:3
      for m = 1:256
        cardEm = 0;
        tx = 0;
        for i = 1:size(images,4)
          for a = 1:size(x,1)
            for b = 1:size(x,2)
              if images(a,b,c,i) == m-1 % -1 due to index in matlab
                cardEm = cardEm + 1;
                tx = tx + t(i)*x(a,b,c);
              end
            end
          end
        end
        I(1,m,c) = tx / cardEm;
      end
    end
    
    % update x
    for c = 1:3
      for a = 1:size(x,1)
        for b = 1:size(x,2)
          numerator_tmp = 0;
          denominator_tmp = 0;
          for i = 1:size(images,4)
            wij = w(1,images(a,b,c,i)+1);
            Iyij = I(1,images(a,b,c,i)+1,c);
            numerator_tmp = numerator_tmp + wij*t(i)*Iyij;
            denominator_tmp = denominator_tmp + wij*t(i)^2;
          end
          x(a,b,c) = numerator_tmp / denominator_tmp;
        end
      end
    end
  end
  
  hdr = x;
end