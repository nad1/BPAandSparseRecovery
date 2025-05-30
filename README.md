## 📘 Citation & Acknowledgment

This repository contains the source code associated with the following thesis and paper:

**Nihat Alperen Dayanir**  
*GPR 3D Image Reconstruction with Sparse Recovery for Random Spatial Sampling*  
Graduate College Dissertations and Theses. 1982, University of Vermont, 2025.  
[https://scholarworks.uvm.edu/graddis/1982](https://scholarworks.uvm.edu/graddis/1982)

Nihat Alperen Dayanir, Dryver Huston, and Tian Xia "Enhanced GPR 3D SAR imaging using sparse signal recovery and back-projection algorithms for spatially random samplings", Proc. SPIE 13456, Algorithms for Synthetic Aperture Radar Imagery XXXII, 1345604 (28 May 2025); https://doi.org/10.1117/12.3054143

If you find this work helpful in your research or projects and would like to cite it,  
please consider using the following citation:

> Nihat Alperen Dayanir, Dryver Huston, and Tian Xia "Enhanced GPR 3D SAR imaging using sparse signal recovery and back-projection algorithms for spatially random samplings", Proc. SPIE 13456, Algorithms for Synthetic Aperture Radar Imagery XXXII, 1345604 (28 May 2025); https://doi.org/10.1117/12.3054143


---

## 📁 SparseRecovery.m

### 🧩 Step 1: Loading and Preparing Data

#### Input Data Source:

- The grid C-scan data is obtained from gprMax simulations or real data. The data must be in 2D format, where each layer is appended sequentially, forming a 3D dataset represented as a 2D matrix.
- The code reads 2D data from CSV files using the readmatrix function.

#### Preprocessing
- **Direct Coupling Removal**:
  Direct coupling is mitigated using either:
  - Mean square subtraction, or
  - Subtracting reference scan data with no targets.
    
- **Polarization Bias Adjustment**:
  - For simulation data, combine X and Z polarization scans to reduce bias.
  - Not yet tested on real data.

- **Downsampling**:
  - Useful for large scans (e.g., 4 ns time window, 1040 samples).
  - A downsampling factor helps retain key features while reducing memory load.

---

### 🔁 Step 2: Random Sampling of A-Scans
Randomly selects A-scan columns from the C-scan data matrix based on the randomascannumber parameter. This step simulates random sampling for sparse recovery.

---

### ⚙️ Step 3: Defining Parameters

#### Image Domain
- `ysize`, `xsize`, `zsize`: Define resolution in each spatial axis.
- `zant`: Starting depth of the antenna (Z-axis), with Y representing height (gprMax convention).

#### Sparse Matrix Initialization
- Sparse matrices: `Psi_total`, `Phi_total`, `Beta_total`.
- `M`: Optional measurement size (typically unused).

#### Ricker Waveform Parameters
- `zeta`, `chi`: Derived parameters defining the shape and timing of the waveform.


---

### 🧠 Step 4: Construction of Sparse Matrices
#### Psi_total Construction Loop:

A sparse matrix Psi_i is created for each scan point.
**For every cell in the 3D image domain:**
- The cell position (xa, ya, za) is calculated.
- The round-trip delay time (Ti) from the cell to the scan point is determined.
- Corresponding Ricker waveform values are assigned in Psi_i, normalized by accumulated squared values of the signal.
  
#### Thresholding and Sparsity:
- Values below 0.03 V in Psi_i are set to zero to enhance sparsity and reduce memory usage.

#### Optional Matrices (Phi, Beta):
- Measurement matrix Phi and response matrix Beta are optionally generated for measurement matrix use cases.

#### Matrix Merging:
- Psi_i, Phi, and Beta are merged to form Psi_total, Phi_total, and Beta_total.


---

### 📉 Step 5: Sparse Recovery via Dantzig Selector
#### Data Preparation:
- The reshaped input data (data1d) serves as the known radar response.
- Sparse recovery solves for b, the unknown image domain matrix.

#### Cross-Validation Process:
- Initializes alpha to estimate the initial epsilon.
- Iteratively minimizes the L1 norm of b using CVX, subject to constraints on the residuals.

#### Reshaping Results:
- The recovered 1D matrix b is reshaped into the original data format for visualization or further analysis.

---

## 📁 RawBackProjection.m

This code is to apply back-projection on the same dataset used in sparse recovery. Through simulating the random sampling it's the same as SparseRecovery.m, but this code uses a coordinates.csv file. It creates a 3D image domain, then it caluclates the round trip delay time between the focused cell and scan positions respectively. According to the delay value it pulls data from the related scan point, then sums them. It goes thorug every cell in the same way, then visualizes in both 2D layers and 3D.

---

## 📁 BPAonDatafromSparseRecovery.m

- Follows the same backprojection logic as `RawBackProjection.m`.
- Input: Reconstructed scan dataset from `b` in `SparseRecovery.m`.
- Reconstructs scan data by multiplying `b` with `Psi_total`.
- Converts it back to 2D scan matrix and applies backprojection.
