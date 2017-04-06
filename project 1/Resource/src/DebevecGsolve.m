% Assume: Zmin = 0; Zmax = 255

% Arguments: 
%   Z(i,j) is the pixel values of pixel location number i in image j
%   B(j)   is the log delta t, or log shutter speed, for image j
%   l      is lamdba, the constant that determines the amount of smoothness
%   w(z)   is the weighting function value for pixel value z

% Returns:
%   g(z)   is the log exposure corresponding to pixel value z
%   lE(i)  is the log fil irradiance at pixel location i

function [g,lE] = DebevecGsolve(Z,B,l,w)
  %% initialization
  n = 256;
  
  A = zeros(size(Z,1)*size(Z,2)+(n-2)+1, n+size(Z,1));
  b = zeros(size(A,1), 1);
  
  %% include the data-fitting equations
  k = 1; % row counter
  for i=1:size(Z,1)
    for j=1:size(Z,2)
      wij = w(Z(i,j)+1); % +1 due to matlab index
      A(k, Z(i,j)+1) = wij;
      A(k, n+i) = -wij;
      b(k,1) = wij * B(j);
      k = k + 1;
    end
  end
  
  %% fix the curve by seeting its middle value to 0
  A(k,129) = 1;
  k = k + 1;
  
  %% include the smoothness equation (regulation term)
  for i=1:n-2 % n-2 due to 2nd derivative
    A(k,i) = l * w(i+1); % i+1 due to start from Zmin + 1 for 2nd derivative
    A(k,i+1) = -2 * l * w(i+1);
    A(k,i+2) = l * w(i+1);
    k = k+ 1;
  end
  
  %% solve the system usgin SVD
  x = A\b;
  
  g = x(1:n);
  lE = x(n+1:size(x,1));
end
      
  