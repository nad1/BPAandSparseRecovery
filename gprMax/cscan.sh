#!/bin/bash

# Number of simulations to run (B-scan layers)
NUM_SIMULATIONS=18

# A-scan number (In a B-scan)
ASCAN=21

POL=x

# Path to the input .in file
FILENAME=3multi3d

IN_FILE="/home/nad/gprMax/user_models/$FILENAME.in"

# Directory where gprMax is located
GPRMAX_DIR="/home/nad/gprMax"

# Log file
LOG_FILE="/home/nad/gprMax/user_models/simulation_log.txt"

# Read initial values from the .in file
TX_LOC=$(grep -oP '#hertzian_dipole: \K[^#]+' $IN_FILE)
RX_LOC=$(grep -oP '#rx: \K[^#]+' $IN_FILE)
STEP_SIZE=$(grep -oP '#src_steps: \K[^#]+' $IN_FILE | awk '{print $1}')

# Initial values for TX and RX locations
TX_X=$(echo $TX_LOC | awk '{print $2}')
TX_Y=$(echo $TX_LOC | awk '{print $3}')
RX=$(echo $RX_LOC | awk '{print $1, $2}')
hertzian_dipole_z=$(echo $TX_LOC | awk '{print $4}')
rx_z=$(echo $RX_LOC | awk '{print $3}')

# Initial increment value
INCREMENT=0

# Start the simulation
cd $GPRMAX_DIR
source /home/nad/miniconda3/etc/profile.d/conda.sh  # Adjust the path
conda activate gprMax

# Loop for the desired number of simulations
for (( i=0; i<NUM_SIMULATIONS; i++ ))
do
    # Run the simulation
    python -m gprMax $IN_FILE -n $ASCAN

    # Rename output files using Python script with the current increment value
    python renamer.py $INCREMENT $ASCAN $FILENAME > renamer_output.log

    # Increment the z-value with the specified step size
    hertzian_dipole_z=$(echo "$hertzian_dipole_z + $STEP_SIZE" | bc)
    rx_z=$(echo "$rx_z + $STEP_SIZE" | bc)

    # Update the .in file with the new values
    sed -i "/^#hertzian_dipole:/c\#hertzian_dipole: z $TX_X $TX_Y $hertzian_dipole_z my_ricker" ${IN_FILE}
    sed -i "/^#rx:/c\#rx: $RX $rx_z" ${IN_FILE}

    # Increment the value for the next run
    ((INCREMENT++))

    # Alternate the TX location between z and x after each B-scan
    if (( i % 2 == 0 )); then
        # Use x-value for TX
        sed -i "/^#hertzian_dipole:/c\#hertzian_dipole: $POL $TX_X $TX_Y $hertzian_dipole_z my_ricker" ${IN_FILE}
    else
        # Use z-value for TX
        sed -i "/^#hertzian_dipole:/c\#hertzian_dipole: $POL $TX_X $TX_Y $hertzian_dipole_z my_ricker" ${IN_FILE}
    fi

done

python -m tools.outputfiles_merge /home/nad/gprMax/user_models/mrg$FILENAME --remove-files

# Reset the .in file with the initial values
# sed -i "/^#hertzian_dipole:/c\#hertzian_dipole: $TX_LOC" ${IN_FILE}
# sed -i "/^#rx:/c\#rx: $RX_LOC" ${IN_FILE}

echo "All simulations completed."