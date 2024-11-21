clear

% Load data from CSV files
data1 = readmatrix('C:\Users\nad\OneDrive\Masaüstü\gprMAX-Sar\3multi3d4nsz.csv');
data2 = readmatrix('C:\Users\nad\OneDrive\Masaüstü\gprMAX-Sar\3multi3d4nsx.csv');

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

data = summed_data;

%% Removing the direct coupling

datadc = datadc_z + datadc_x;
data = (summed_data - datadc);

% data = data - mean(data,2); % Alternatively, mean substract method can
% be used to remove direct coupling

%% Downsampling the scan data to overcome memory issues

% Define the downsampling factor
factor = 20;

% Get the size of gpr_data
[nRows, nCols] = size(data);

% Preallocate the decimated data matrix
gpr_data_decimated = zeros(ceil(nRows / factor), nCols);

% Apply decimation to each column individually
for col = 1:nCols
    gpr_data_decimated(:, col) = decimate(data(:, col), factor);
end

data = gpr_data_decimated;

%%

[Nt, Q] = size(data); % Nt: number of time samples, Q: number of A-scans

%% Selecting random scan points from the scan data

randomascannumber = 49; % Number of a-scan points to be selected
originalMatrix = data;

% Get the size of the original matrix
[m, n] = size(originalMatrix);

% Create a matrix of zeros with the same size as the original matrix
newMatrix = zeros(m, n);

selectedColumns = randperm(n, randomascannumber);

% Copy selected columns from the original matrix to the corresponding columns in the new matrix
newMatrix(:, selectedColumns) = originalMatrix(:, selectedColumns);

data = newMatrix;
%% Constants and parameters

layers = 18;
time_window = 4e-9; % Total time window of the B-scan
M = 52; % Number of measurements per a-scan for the measurement matrix(Psi matrix) size
step_size = 0.02; % Step size in meters, distance between A-scan positions
antenna_offset = 0.04; % Antenna offset in meters
er_ground = 6; % Relative permittivity of the ground
f = 1e9; % frequency in Hz
zeta = 2 * pi^2 * f^2; % Calculated value of zeta
chi = 1 / f; % Value of chi

t0 = 9.8047e-10; % Time value from the desired image domain cell to surface

c = 299792458; % Speed of light in m/s
iterations = Nt; % number of time samples
time_step = time_window/(iterations-1);
Fs = iterations/time_window; % Sampling frequency


ysize = Nt;
xsize = Q/layers;
zsize = layers;

zant = 0.02;

% Initialize cell arrays for parfor
Phi_total = sparse(M*Q, Nt*Q);
Psi_total = sparse(Nt*Q, Nt*Q);
Beta_total = sparse(M*Q, 1);

norm_threshold = 0;%1e-10; % Set an appropriate threshold

N = xsize*zsize;

% Construct a ParforProgressbar object to follow progress:
% PB = ProgressBar(N, 'taskname', 'Parfor loop', 'ui', 'cli');
PB = ProgressBar(N, 'taskname', 'Parfor loop');

parfor i = 1:(xsize*zsize)

    Psi_i = zeros(Nt, xsize*ysize*zsize); % Initialize Psi_i as a sparse matrix
    jth_cell = 1; % Initializing the jth cell counter
    Remaining = Q - i

    xsi = 0.04 + mod((i-1), xsize)*(step_size); % Initialize xsi for each iteration
    xri = xsi + antenna_offset;
    zant = 0.02 + floor((i-1)/xsize) * step_size;

    for depth = 1:zsize
        for col = 1:xsize
            for row = 1:ysize

                xa = 0.04 + (col-1)*step_size; % xa is the calculated cell's position
                ya = (row-1)*time_step*(c/sqrt(er_ground)); % ya is the calculated cell's position
                za = 0.02 + (depth-1)*(step_size);

                % Calculating "Ti" delay time between the selected jth cell and ith antenna position
                Ti = (sqrt((xa - xsi)^2 + ya^2 + (za-zant)^2) + sqrt((xa - xri)^2 + ya^2 + (za-zant)^2)) / (c / sqrt(er_ground));

                if Ti <= time_window

                    accumulated_S_t_squared = 0;

                    for n = 1:Nt
                        t = (t0 + (n-1)*time_step - Ti);
                        S_t = exp(-zeta * (t - chi)^2);
                        accumulated_S_t_squared = accumulated_S_t_squared + S_t^2;
                    end

                    normalization_factor = sqrt(accumulated_S_t_squared);

                    for n = 1:Nt
                        t = (t0 + (n-1)*time_step - Ti);
                        S_t = exp(-zeta * (t - chi).^2);
                        Psi_i(n, jth_cell) = S_t / normalization_factor;
                    end

                else

                    Psi_i(:, jth_cell) = 0;

                end

                jth_cell = jth_cell + 1;

            end
        end
    end

    Psi_i(Psi_i < 0.03) = 0; % To get more sparse matrix to decrease memory usage

    Phi = randn(M, Nt); % Generate a new Phi matrix for each iteration

    % Beta_i = Phi * data(:,i); % Generate Beta matrix

    % Store results in cell arrays

    Psi_local{i} = sparse(Psi_i);
    Phi_local{i} = Phi;
    % Beta_local{i} = sparse(Beta_i);

    count(PB); % update the progress monitor
end

Psi_total = vertcat(Psi_local{:});
% Beta_total = vertcat(Beta_local{:});
for i = 1:Q
    row_start = (i-1)*M + 1;
    row_end = i*M;
    col_start = (i-1)*Nt + 1;
    col_end = i*Nt;
    Phi_total(row_start:row_end, col_start:col_end) = Phi_local{i};
end

data1d = reshape(data, Nt*Q, 1);


% Save variables to a .mat file
mat_filename = sprintf('random%d.mat', randomizer);
save(mat_filename, 'Phi_total', 'Beta_total', 'data1d', 'Psi_total', 'Nt', 'Q', 'M', '-v7.3');

%% Dantzig selector with cross-validation

alpha = 0.001; % Alpha value for initialization
zE = data1d;            % Estimate set, If using measuremrent matrix is desired use Phi_total * data1d;
ThetaE =  Psi_total;    % Estimate set, If using measuremrent matrix is desired use Phi_total * Psi_total;
zCV = data1d;           % Cross-validation set, If using measuremrent matrix is desired use Phi_total * data1d;
ThetaCV =  Psi_total;   % Cross-validation set, If using measuremrent matrix is desired use Phi_total * Psi_total;


% Parameters and initializations
epsilon = alpha * norm(ThetaE' * zE, inf);
b = zeros(size(ThetaE, 2), 1);

% Iterative process
while true
    % Estimation of b
    cvx_begin
        variable b(size(ThetaE, 2))
        % Minimize the error between zE and the predicted zE
        minimize(norm(b, 1))
        subject to
        % Constraint can be adjusted based on specific requirements
        norm(ThetaE' * (zE - ThetaE * b), inf) <= epsilon
        % norm(zE - ThetaE * b, 2) <= epsilon
    cvx_end

    epsilon = round(epsilon, 6);

    % Cross-validation to check if the solution is acceptable
    cv_value = norm(ThetaCV' * (zCV - ThetaCV * b), inf);
    % cv_value = norm((zE - ThetaE * b), 2);
    cv_value = round(cv_value, 6);
    if cv_value < epsilon
        epsilon = cv_value;
    else
        break;
    end
end

Image = reshape(b, Nt, Q); % The result in 2D


%
% % Plot results
% figure;
%
% subplot(1, 2, 1);
% imagesc(data);
% xlabel('X-axis');
% ylabel('Y-axis');
% title('Input Data');
% colormap('jet');
% colorbar;
%
% subplot(1, 2, 2);
% imagesc(Image);
% xlabel('X-axis');
% ylabel('Y-axis');
% title(['Result of b with Measurement size M = ', num2str(M), ', Alpha = ', num2str(alpha)]);
% colormap('jet');
% colorbar;
%
