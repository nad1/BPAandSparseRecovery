
% Load data from CSV files
data1 = csvread('C:\Users\nad\OneDrive\Masaüstü\gprMAX-Sar\3multi3d4nspecsinglez.csv');
data2 = csvread('C:\Users\nad\OneDrive\Masaüstü\gprMAX-Sar\3multi3d4nspecsinglex.csv');

%% If perfectly removing the direct coupling is desired, scan data from the same domain without any target can be used

datadc_z = readmatrix('C:\Users\nad\OneDrive\Masaüstü\gprMAX-Sar\3multi3demptyz.csv');
datadc_x = readmatrix('C:\Users\nad\OneDrive\Masaüstü\gprMAX-Sar\3multi3demptyx.csv');

%% Summing data files, if 2 scan data files are being used

% Check if the dimensions of the matrices are the same
if isequal(size(data1), size(data2))
    % Sum the matrices element-wise
    % data2=0;
    summed_data = data1 + data2;% + data3;
else
    error('Dimensions of input matrices are not the same.');
end

gpr_data = summed_data;

%% Removing the direct coupling

datadc = datadc_z + datadc_x;
gpr_data = (summed_data - datadc);

% gpr_data = gpr_data - mean(gpr_data,2); % Alternatively, mean substract method can
% be used to remove direct coupling

%% Downsampling the scan data to overcome memory issues

% Define the downsampling factor
factor = 20;

% Get the size of gpr_data
[nRows, nCols] = size(gpr_data);

% Preallocate the decimated data matrix
gpr_data_decimated = zeros(ceil(nRows / factor), nCols);

% Apply decimation to each column individually
for col = 1:nCols
    gpr_data_decimated(:, col) = decimate(gpr_data(:, col), factor);
end

gpr_data = gpr_data_decimated;

%% Selecting random scan points, and filling other un-selected ones with zeros

% Store original gpr_data for comparison without enhancement
gpr_data_original = gpr_data;

% Randomly select A-scan columns for enhancement
randomascannumber = 100; % Number of points that are going to be randomly selected
[m, n] = size(gpr_data);
selectedColumns = randperm(n, randomascannumber);

% Create a new matrix with only the selected columns
newMatrix = zeros(m, n);
newMatrix(:, selectedColumns) = gpr_data(:, selectedColumns);
gpr_data = newMatrix;  % Only the selected columns now have data

%%
% Load the CSV file with coordinates, each row corresponds to a scan point
% in the data file
csv_file = 'C:/Users/nad/OneDrive/Masaüstü/gprMAX-Sar/3multicoordinates.csv';
csv_data = readtable(csv_file);

% Extract the coordinates (assumed to be in meters)
X_coords = csv_data.X;
Y_coords = csv_data.Z;
Z_coords = csv_data.Y;

% Define the cell size in meters
c = 299792458;
time_window = 4e-9;
er_ground = 6;
time_step = time_window/(size(gpr_data, 1)-1);
cell_size = (time_window / (size(gpr_data, 1) - 1)) * (c / sqrt(er_ground));

% Define the cube dimensions in terms of number of cells
depth_cells = size(gpr_data, 1);
width_cells = 2 * depth_cells;
length_cells = 2 * depth_cells;

% Convert cube dimensions to real-world units (meters)
depth = depth_cells * cell_size;
width = width_cells * cell_size;
length = length_cells * cell_size;

% Determine the bounds of the entire grid
min_x = min(X_coords);
max_x = max(X_coords);
min_z = min(Z_coords);
max_z = max(Z_coords) + depth;
min_y = min(Y_coords);
max_y = max(Y_coords);

% Convert to integers
grid_size_x = floor((max_x - min_x) / cell_size);
grid_size_z = floor(((max_z - min_z) / cell_size) * 0.5);
grid_size_y = floor((max_y - min_y) / cell_size);

% Create the 3D grid with real-world coordinates for each cell
x_coords_grid = linspace(min_x, max_x, grid_size_x);
z_coords_grid = linspace(min_z, max_z, grid_size_z);
y_coords_grid = linspace(min_y, max_y, grid_size_y);

% Create 3D meshgrids for the x, y, and z coordinates of the grid
[X_grid, Z_grid, Y_grid] = ndgrid(x_coords_grid, z_coords_grid, y_coords_grid);

% Define the distance interval for GPR data, using the updated cell size as resolution
gpr_data_resolution = cell_size;  % Set to cell size

% Initialize an empty 3D array to store the summed GPR data for each grid cell
gpr_grid_data = zeros(grid_size_x, grid_size_z, grid_size_y, 'single');

% Compute GPR grid data
for i = 1:grid_size_x
    for j = 1:grid_size_z
        for k = 1:grid_size_y
            for point_index = 1:numel(X_coords)
                x_point = X_coords(point_index);
                z_point = Z_coords(point_index);
                y_point = Y_coords(point_index);
                
                % Vector components from scan point to grid cell
                dx = X_grid(i, j, k) - x_point;
                dz = Z_grid(i, j, k) - z_point;
                dy = Y_grid(i, j, k) - y_point;
                
                % Distance between the grid cell and scan point
                distance = sqrt(dx^2 + dz^2 + dy^2);
                
                % Calculate the cosine of the angle between the vector and z-axis
                if distance == 0
                    cos_theta = 1.0;  % Directly under the scan point
                else
                    cos_theta = dz / distance;
                end
                
                % Convert to degrees
                angle_deg = rad2deg(acos(cos_theta));
                
                % Skip this grid cell if the angle is greater than 15 degrees
                if angle_deg > 45 % The angle value is used to apply a simple antenna wave pattern
                    continue;
                end
                
                % Determine the row in the GPR data that corresponds to this distance
                row_idx = floor(2 * distance / gpr_data_resolution);
                
                % row_idx = floor((2 * distance/(c/sqrt(6)))/time_step);

                % If the index is valid, accumulate the GPR data
                if row_idx > 0 && row_idx <= size(gpr_data, 1)
                    gpr_grid_data(i, j, k) = gpr_grid_data(i, j, k) + gpr_data(row_idx, point_index);
                end
            end
        end
    end
end

gpr_grid_data_permuted = permute(gpr_grid_data, [3, 1, 2]);
gpr_grid_data_flipped_x = flip(gpr_grid_data_permuted, 3);

isobpa = gpr_grid_data;
figure;

% Find the maximum value indices along each dimension
[maxY, maxYIndex] = max(isobpa, [], 1);
[maxX, maxXIndex] = max(maxY, [], 2);
[~, maxZIndex] = max(maxX(:));

% Extract the corresponding slice indices
sliceX = maxXIndex(1, 1, maxZIndex);
sliceY = maxYIndex(1, maxXIndex(1, 1, maxZIndex), maxZIndex);
sliceZ = maxZIndex;

% Plot the slice
slice(isobpa, sliceX, sliceY, sliceZ);
xlabel('X-axis');
ylabel('Y-axis');
zlabel('Z-axis');
title('Slices of 3D Backprojected Image');
colormap('jet');
colorbar;


volumeViewer(gpr_grid_data)
