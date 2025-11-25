[![Build DRSuite](https://github.com/DiffusionRelaxationSuite/DRSuite/actions/workflows/compile_matlab.yml/badge.svg)](https://github.com/DiffusionRelaxationSuite/DRSuite/actions/workflows/compile_matlab.yml)

Diffusion-Relaxation Suite is an open-source software package that provides novel analysis methods to identify and separate multiple microstructural tissue compartments from MRI data.  Full documentation is available from: https://drsuite.org/.  This software can be cited as:

- D. Mandal, A. A. Joshi, D. W. Shattuck, J. P. Haldar.  "Diffusion-Relaxation Suite." [Computer Software].  Available: https://drsuite.org/.

# Contents

`estimate_spectra.m`: This estimates the spectra from MR data. Details: https://drsuite.org/workflow/spect_estim.html

`plot_beta_sweep.m`: Plot cost function vs iteration for multiple beta. Details: https://drsuite.org/workflow/beta_calculation.html

`plot_spect_im.m`: Generates spectroscopic image. Details: https://drsuite.org/workflow/plot_avg_spectra.html

`plot_avg_spectra.m`: Generates average spectra from the estimates spectra. Details: https://drsuite.org/workflow/plot_avg_spectra.html

`plot_comp_maps.m`: Generates component maps. Details: https://drsuite.org/workflow/plot_comp_maps.html

`create_phantom.m`: This creates the 1D/2D phantom. Details: https://drsuite.org/generateSimData.html

`estimate_crlb.m`: Calculates Cramer-Rao bounds. Details: https://drsuite.org/optExpt.html

`Phantom_1d_workflow.m/.sh`: Runs full workflow for testing 1D Phantom generation and processing.

`Phantom_2d_workflow.m/.sh`: Runs full workflow for testing 2D Phantom generation and processing.

## bin

Contains bash scripts for commandline implementation of the above MATLAB functions.

## data

Contains files for running the work flow and the tutorials.

## demos

Contains `.ini` files to run the Phantom workflows.

## solvers

`solvers`: contains the function for running `ADMM`, `LADMM`, `NNLS` 

## utilities

This comprises of the sub functions to estimate spectra, plot spectroscopic image, average spectra and component maps, estimate CRLB and generate Phantoms.
