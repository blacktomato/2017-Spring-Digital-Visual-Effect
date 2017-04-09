%% tone mapping

% Photographic Tone Reproduction for Digital Images
%
% hdr: high dynamic range radiance map, a matrix of size rows * columns * 3
% saturation: a value between 0 and 1 defining the desired saturation of
%             the resulting tonemapped image.

function [ldrPic] = tonemapping_global(hdrPic, saturation)

    % world luminance
    N = prod(size(hdrPic(:,:,1)));
    delta = 0.00001;
    
    % log-average luminance
    L_w = 0.27 * hdrPic(:,:,1) + 0.67 * hdrPic(:,:,2) +0.03 * hdrPic(:,:,3);
    L_w_mean = exp((1/N) .* sum(sum( log(delta + L_w) )));

    % scaled luminance
    a = 2.5;
    L = a / L_w_mean .* hdrPic;
    sL_w = a / L_w_mean .* L_w;

    % display luminance
    L_white = max(max(L));
    L_d = (L .* (1 + L ./ L_white .^ 2)) ./ (1 + L);

    ldrPic = zeros(size(hdrPic));

    %another implement
    for i=1:3
        ldrPic(:,:,i) = ((hdrPic(:,:,i) ./ L_w)) .^ saturation .* (sL_w./(sL_w+1));
    end
    
    %original paper work
    %figure(1);
    %imshow(L_d); 
    %improve the color and high light part
    %figure(2);
    %imshow(ldrPic);
end
