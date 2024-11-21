% file_path = 'C:\Users\nad\OneDrive\Masaüstü\gprMAX-Sar\boxLfocus3zxy.csv'; 
% matrix2D = csvread(file_path);
% 
% % Assuming 'matrix2D' is your input 2D matrix
% % Check if the number of columns is divisible by 47
% if mod(size(matrix2D, 2), 27) ~= 0
%     error('The number of columns in the 2D matrix must be divisible by 47.');
% end
matrix2D= gpr_data;
matrix2D = Image;
% Compute the size for the 3D matrix
rows = size(matrix2D, 1);
layers = size(matrix2D, 2) / 27;
cols = 27;

% Reshape the matrix into 3D
matrix3D = reshape(matrix2D, rows, cols, layers);
% 
% figure;
% isosurface(matrix3D, 10);

volumeViewer(matrix3D);

% volumeViewer(bp_image_3d);
%%
% Load your images
% Replace 'full_sampled_image.mat' and 'random_sampled_image.mat' with your actual file names
% fullSampledData = load('full_sampled_image.mat');
% randomSampledData = load('random_sampled_image.mat');

% If your data is stored in variables within the .mat files, extract them
% For example, if the images are stored in variables named 'I_full' and 'I_random':
I_full = borg; %fullSampledData.I_full;
I_random = b; %randomSampledData.I_random;

% Ensure the images are of the same size
if ~isequal(size(I_full), size(I_random))
    error('Images must be the same size for error calculation.');
end

% Normalize the images if necessary
% For GPR data, you might need to normalize based on the maximum absolute value
I_full_norm = I_full / max(abs(I_full(:)));
I_random_norm = I_random / max(abs(I_random(:)));

% Compute Mean Squared Error (MSE)
mseValue = immse(I_full_norm, I_random_norm);

% Compute Root Mean Squared Error (RMSE)
rmseValue = sqrt(mseValue);

% Compute Peak Signal-to-Noise Ratio (PSNR)
% PSNR function requires images in the range [0, 1] or [0, 255]
[psnrValue, ~] = psnr(I_random_norm, I_full_norm);

% Compute Structural Similarity Index Measure (SSIM)
[ssimValue, ssimMap] = ssim(I_random_norm, I_full_norm);

% Display the results
fprintf('MSE: %f\n', mseValue);
fprintf('RMSE: %f\n', rmseValue);
fprintf('PSNR: %f dB\n', psnrValue);
fprintf('SSIM: %f\n', ssimValue);

% Optional: Display the SSIM map
figure;
imshow(ssimMap, []);
title(sprintf('SSIM Index Map - Mean SSIM Value: %0.4f', ssimValue));
colorbar;
