%% tone mapping
% Photographic Tone Reproduction for Digital Images

% world luminance
% saturation: a value between 0 and 1 defining the desired saturation of
% the resulting tonemapped image

function [ldrPic, sm] = tonemapping_local(hdrPic, saturation)

    key = 0.18;
    N = prod(size(hdrPic(:,:,1)));
    delta = 0.00001;
    % log-average luminance
    L_w = 0.27 * hdrPic(:,:,1) + 0.67 * hdrPic(:,:,2) +0.03 * hdrPic(:,:,3); 

    % circularly symmetric Gaussian
    phi = 8;
    alpha1 = 1/(2*sqrt(2));
    alpha2 = alpha1 * 1.6;
    epi = 0.05;
 
    v1 = zeros(size(L_w,1), size(L_w,2), 8);
    v2 = zeros(size(L_w,1), size(L_w,2), 8);
    v = zeros(size(L_w,1), size(L_w,2), 8);
    v1final = zeros(size(L_w,1), size(L_w,2));
    
    for scale = 1:(8+1)
        s = 1.6 ^ (scale - 1);
        sigma = s * alpha1 / sqrt(2);
        sigma2 = s * alpha2 / sqrt(2);
        
    
        kernelRadius = ceil(2*sigma);
        kernelSize = 2*kernelRadius+1;
        gaussKernel = fspecial('gaussian', [kernelSize kernelSize], sigma);
        v1(:,:,scale) = conv2(L_w, gaussKernel, 'same');
        
        kernelRadius2 = ceil(2*sigma2);
        kernelSize2 = 2*kernelRadius2+1;
        gaussKernel2 = fspecial('gaussian', [kernelSize2 kernelSize2], sigma2);
        v2(:,:,scale) = conv2(L_w, gaussKernel2, 'same');
        
        v(:,:,scale) = (v1(:,:,scale) - v2(:,:,scale))...
                        ./ ((2 ^ phi * key / scale ^2) + v1(:,:,scale));
    end

    sm = zeros(size(L_w,1), size(L_w,2));
    rec = ones(size(L_w,1), size(L_w,2));
    
    for scale = 1:8
        target = rec .* (abs(v(:,:,scale)) < epi);
        rec = rec - target;
        if (nonzeros(target))
            sm(target==1) = scale;
        end
    end
    
    sm(sm == 0) = 1;
    
    for x=1:size(v1,1)
        for y=1:size(v1,2)
            v1final(x,y) = v1(x,y,sm(x,y));
        end
    end

 % 
    key = exp((1/N) .* sum(sum( log(delta + v1final) )));

    % scaled luminance
    a = 0.72;
    sL = a / key .* v1final;
    
    L_d = L_w .* (a/key) ./ (1 + sL);
 %

    % L_d = L_w ./ (1 + v1final);
    ldrPic = zeros(size(hdrPic));

    for i=1:3
        ldrPic(:,:,i) = ((hdrPic(:,:,i) ./ L_w) .^ saturation) .* L_d;
    end
 
    ldrPic(ldrPic > 1) = 1;
    
    figure(1);
    imshow(ldrPic);
end
