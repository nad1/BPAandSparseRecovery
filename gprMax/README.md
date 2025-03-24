# C-Scan Emulation with gprMax

gprMax does not natively support C-scan simulations. However, you can emulate C-scans by running multiple parallel B-scans at different z-axises. This repository provides scripts to automate that process.

## 📄 Files Overview

- **`3multi3d.in`** – Sample simulation setup file located in the `user_models` directory.
- **`cscan.sh`** – Automates multiple B-scan simulations by incrementally adjusting the antenna’s z-position.
- > ℹ️ The **step size** used to increase the z-axis is automatically extracted from the `.in` file.
- **`runc.sh`** – Ensures `cscan.sh` is in the correct Unix format and runs the script.

> ⚠️ Note: Editing `cscan.sh` on Windows may result in incompatible line endings. `runc.sh` will convert it automatically before running.

---

## ▶️ How to Run a C-Scan

1. **Validate Your Simulation Setup**
   - Ensure your simulation input file (e.g., `xxx.in`) runs successfully in gprMax before starting a C-scan batch.

2. **Watch for z-Axis Issues**
   - Sometimes the z-axis value may not apply correctly during the C-scan loop. If that happens, the simulation may fail. Keep this in mind while testing.

3. **Execute the Script**
   - Open your terminal, navigate to the script's directory, and run:
     ```bash
     ./runc.sh
     ```
> 🧩 The output file is a **2D data array** where each B-scan is appended to the end of the previous one.  
> This creates a vertically stacked structure of B-scan layers, effectively forming a simulated C-scan dataset.
---

## 🔁 Antenna Polarization Control

The antenna polarization is controlled by the `POL` variable at the beginning of the script.  
**This value is not automatically extracted from the `.in` file**, so make sure it matches your intended polarization.

### Default Behavior

By default, polarization remains fixed throughout the C-scan simulation.  
If you'd like to **alternate the polarization** between `x` and `z` after each B-scan, you can enable that option by modifying the `POL` logic in the script.

### Enabling Alternating Polarizations

To switch the polarization between `x` and `z` on each B-scan, update the following section in `cscan.bh`:

```bash
# Alternate the TX location between z and x after each B-scan
if (( i % 2 == 0 )); then
    # Use x-value for TX
    sed -i "/^#hertzian_dipole:/c\#hertzian_dipole: x $TX_X $TX_Y $hertzian_dipole_z my_ricker" ${IN_FILE}
else
    # Use z-value for TX
    sed -i "/^#hertzian_dipole:/c\#hertzian_dipole: z $TX_X $TX_Y $hertzian_dipole_z my_ricker" ${IN_FILE}
fi
 ```
This will alternate the transmit polarization direction for each B-scan simulation.

> ⚠️ **Note:** The `POL` variable is manually set — the script does **not** read the polarization from your `.in` file.

