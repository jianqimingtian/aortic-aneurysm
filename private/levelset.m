%% --- level-set active contour algorithm
function h = levelset(handles)

% get image
im = handles.img(:,:,handles.imCount);

% get min and max values of image
maxv = double(max(im(:)));
minv = double(min(im(:)));

% gray value range
range = maxv - minv;

% convert image to double
Img = double(im(:,:,1));
% reduce value range to 0..256
Img = round(((Img - minv) / range) * 255);

% select axes
axes(handles.OrigImg);
% show image
imshow(Img, []);

% get ROI from user
rect = getrect;
% crop image to ROI
Img = imcrop(Img, rect);

%% parameter settings

% time step
timestep = 8;
% coefficient of the distance regularization term R(phi)
mu = 0.2 / timestep;
% iterator settings
iter_inner = 5;
iter_outer = handles.levelset_iter;
% coefficient of the weighted length term L(phi)
lambda = 5; % 5
% coefficient of the weighted area term A(phi)
alfa = -1.5; % 1.5
% paramater that specifies the width of the DiracDelta function
epsilon = 1.5; % 1.5
% scale parameter in Gaussian kernel
sigma = 1.5;
% matrix size for kernel
hsize = 10;  % 15
% potential well (single or double)
potential = 2;  

%% DRLSE

% show ROI
imshow(Img, []);

% Gaussian kernel
G = fspecial('gaussian', hsize, sigma); 
% smooth image by Gaussiin convolution
Img_smooth = conv2(Img, G, 'same');

% some kind of gradient
[Ix, Iy] = gradient(Img_smooth);
f = Ix .^ 2 + Iy .^ 2;
% edge indicator function.
g = 1 ./ (1 + f);

% initialize LSF as binary step function
c0 = 2;
initialLSF = c0 * ones(size(Img));

% get initial rectangle
rect = getrect;

% show the rectangle
rectangle('Position', rect, 'EdgeColor', 'r', ...
          'LineWidth', 2, 'LineStyle', '--');

% generate the initial region R0 as two rectangles
initialLSF(round(rect(2)):round(rect(2)+rect(4)), round(rect(1)):round(rect(1)+rect(3))) = -c0;

% change back to result axis
axes(handles.ResImg);

% initial 
phi = initialLSF;

% show initial zero level
imshow(Img, []);
%imshow(Img_smooth, []);
hold on;
contour(phi, [0,0], 'r');
title('Initial zero level contour');
pause(1.0);

% select potential well
if potential ==1
    % use single well potential p1(s)=0.5*(s-1)^2, which is good for region-based model 
    potentialFunction = 'single-well';
elseif potential == 2
    % use double-well potential in Eq. (16), which is good for both edge and region based models
    potentialFunction = 'double-well';
else
    % default choice of potential function
    potentialFunction = 'double-well';
end  

% start level set evolution
for n=1:iter_outer
    phi = drlse_edge(phi, g, lambda, mu, alfa, epsilon, timestep, iter_inner, potentialFunction);    
    if mod(n,2)==0
        imshow(Img, []);
        %imshow(Img_smooth, []);
        hold on;
        contour(phi, [0,0], 'r');
        pause(0.1);
    end
end

% refine the zero level contour by further level set evolution with alfa=0
alfa=0;
iter_refine = 10;
phi = drlse_edge(phi, g, lambda, mu, alfa, epsilon, timestep, iter_inner, potentialFunction);

finalLSF = phi;

imshow(Img, []);
%imshow(Img_smooth, []);
hold on;
contour(phi, [0,0], 'r');
str=['Final zero level contour, ', num2str(iter_outer*iter_inner+iter_refine), ' iterations'];
title(str);

% for a better view, the LSF is displayed upside down
pause(1);
figure;
mesh(-finalLSF);
hold on;  contour(phi, [0,0], 'r','LineWidth',2);
view([-80 35]);
str=['Final level set function, ', num2str(iter_outer*iter_inner+iter_refine), ' iterations'];
title(str);
axis on;
[nrow, ncol]=size(Img);
axis([1 ncol 1 nrow -5 5]);
set(gca,'ZTick',[-3:1:3]);
set(gca,'FontSize',14)

% return handle struct
h = handles;

end