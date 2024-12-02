SparseRecovery.m 
-------------------------------------------------------------------------
Step 1: Loading and Preparing Data
Input Data Source:

The grid C-scan data is obtained from gprMax simulations or real data. The data must be in 2D format, where each layer is appended sequentially, forming a 3D dataset represented as a 2D matrix.
The code reads 2D data from CSV files using the readmatrix function.
Direct Coupling Removal:

Direct coupling is mitigated using either:
A mean square subtraction method.
Subtraction of scan data from the same domain without any targets.
Polarization Bias Adjustment:

To reduce polarization bias between X and Z antenna polarizations, data from the same domain with different polarizations is summed. This adjustment is significant in simulation data but not yet tested with real data.
Downsampling:

Downsampling is applied to reduce memory usage, especially for large datasets such as those with a 4 ns time window and 1040 samples per A-scan. The downsampling factor is defined to retain essential features.

-------------------------------------------------------------------------
Step 2: Random Sampling of A-Scans
Randomly selects A-scan columns from the C-scan data matrix based on the randomascannumber parameter. This step simulates random sampling for sparse recovery.

-------------------------------------------------------------------------
Step 3: Defining Parameters
Resolution and Antenna Location:

ysize, xsize, and zsize specify the resolution of the image domain.
zant defines the initial Z-axis location of the antenna, with the GPRMax convention where the Y-axis represents height.
Sparse Matrix Construction:

Psi_total, Phi_total, and Beta_total are initialized in sparse format to save memory.
M corresponds to the measurement size, which is unused by default.
Ricker Waveform Parameters:

zeta and chi are derived based on the Ricker waveform used in the simulations.

-------------------------------------------------------------------------
Step 4: Construction of Sparse Matrices
Psi_total Construction Loop:

A sparse matrix Psi_i is created for each scan point.
For every cell in the 3D image domain:
The cell position (xa, ya, za) is calculated.
The round-trip delay time (Ti) from the cell to the scan point is determined.
Corresponding Ricker waveform values are assigned in Psi_i, normalized by accumulated squared values of the signal.
Thresholding and Sparsity:

Values below 0.03 V in Psi_i are set to zero to enhance sparsity and reduce memory usage.
Optional Matrices (Phi, Beta):

Measurement matrix Phi and response matrix Beta are optionally generated for measurement matrix use cases.
Matrix Merging:

Psi_i, Phi, and Beta are merged to form Psi_total, Phi_total, and Beta_total.

-------------------------------------------------------------------------
Step 5: Sparse Recovery via Dantzig Selector
Data Preparation:

The reshaped input data (data1d) serves as the known radar response.
Sparse recovery solves for b, the unknown image domain matrix.
Cross-Validation Process:

Initializes alpha to estimate the initial epsilon.
Iteratively minimizes the L1 norm of b using CVX, subject to constraints on the residuals.
Reshaping Results:

The recovered 1D matrix b is reshaped into the original data format for visualization or further analysis.

-------------------------------------------------------------------------
Step 6: Visualization
Optional visualization displays:
The original input data.
The reconstructed image domain matrix.
