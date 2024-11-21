matrix2D = gpr_data;
matrix2D = Image;

% Compute the size for the 3D matrix
rows = size(matrix2D, 1);
cols = 27;
layers = size(matrix2D, 2) / cols;


% Reshape the matrix into 3D
matrix3D = reshape(matrix2D, rows, cols, layers);
% 
% figure;
% isosurface(matrix3D, 10);

volumeViewer(matrix3D);
