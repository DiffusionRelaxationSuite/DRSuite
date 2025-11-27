#!/bin/bash
RootDir="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/
PATH="$RootDir/bin:$PATH"

set -e
# create phantom with 2D spectral encoding
# Phantom generation
install -d Result

create_phantom.sh -a data/acq_phantom1D.txt -i data/Phantom1D_spect.txt -o Phantom1D
# spectrum Estimation --ladmm
estimate_spectra.sh -i Phantom1D/Phantom_data.mat -m Phantom1D/Phantom_mask.mat \
    -d Phantom1D/Phantom_spectrm_info.mat -c demos/Phantom1D_ladmm.ini -o Result/Phantom1D_ladmm_spect.mat

# spectrum Estimation --admm
# spectEstimation Phantom1D/Phantom_data.mat Phantom1D/Phantom_mask.mat \
#     Phantom1D/Phantom_spectrm_info.mat demos/Phantom_admm.ini Result/Phantom1D_admm_spect.mat)
# 
#spectrum Estimation --nnls
# spectEstimation Phantom1D/Phantom_data.mat Phantom1D/Phantom_mask.mat \
#     Phantom1D/Phantom_spectrm_info.mat demos/Phantom_nnls.ini Result/Phantom1D_nnls_spect.mat)

#plot Average spectra
plot_avg_spectra.sh -i Result/Phantom1D_ladmm_spect.mat -m Phantom1D/Phantom_mask.mat \
    -o Result/Phantom1D_data_ladmm_avg_spectra -t png pdf

# Plot spectroscopic image
idx=9; #encoding sample chosen to show back ground MR data intensity
plot_spect_im.sh Result/Phantom1D_ladmm_spect.mat Phantom1D/Phantom_data.mat ${idx} \
    Phantom1D/Phantom_mask.mat Result/Phantom1D_spectroscopic_Im png

# Plot component Maps
plot_comp_maps.sh -i Result/Phantom1D_ladmm_spect.mat -m data/Phantom1D_spectrm_mask.mat \
    -c data/four_color.mat -o Result/Phantom1D_component_maps -t png epsc

