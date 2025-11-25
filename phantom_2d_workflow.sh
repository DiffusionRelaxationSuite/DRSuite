#!/bin/bash
# create phantom with 2D spectral encoding
RootDir="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/
PATH="$RootDir/bin:$PATH"

set -ex
# Phantom generation
# install -d Result.$$

create_phantom.sh --acqfile data/acq_phantom.txt \
    --spectfile data/Phantom_spect.txt \
    --outfolder Phantom2D --multislice 1 #or create_phantom

echo running beta calc
plot_beta_sweep.sh --imgfile Phantom2D/Phantom_data.mat \
    --betafile data/betafile_phantom2d.txt \
    --spect_infofile Phantom2D/Phantom_spectrm_info.mat \
    --outprefix Phantom2D/Phantom_data_ladmm_spect \
    --configfile demos/Phantom2D_ladmm.ini --spatmaskfile \
    Phantom2D/Phantom_mask_beta_calc.mat --file_types png

echo running spect estimation
#spectrum Estimation --ladmm
estimate_spectra.sh --imgfile Phantom2D/Phantom_data.mat \
    --spect_infofile Phantom2D/Phantom_spectrm_info.mat \
    --outprefix Phantom2D/Phantom2D_data_ladmm_spect.mat \
    --configfile demos/Phantom2D_ladmm.ini \
    --spatmaskfile Phantom2D/Phantom_mask.mat

#spectrum Estimation --admm
estimate_spectra.sh --imgfile Phantom2D/Phantom_data.mat \
    --spect_infofile Phantom2D/Phantom_spectrm_info.mat \
    --outprefix Phantom2D/Phantom2D_data_admm_spect.mat \
    --configfile demos/Phantom2D_admm.ini \
    --spatmaskfile Phantom2D/Phantom_mask.mat

#spectrum Estimation --nnls
estimate_spectra.sh --imgfile Phantom2D/Phantom_data.mat \
    --spect_infofile Phantom2D/Phantom_spectrm_info.mat \
    --outprefix Phantom2D/Phantom2D_data_nnls_spect.mat \
    --configfile demos/Phantom2D_nnls.ini \
    --spatmaskfile Phantom2D/Phantom_mask.mat

exit 0
#plot Average spectra
plot_avg_spectra.sh --spect_imfile Phantom2D/Phantom2D_data_ladmm_spect.mat \
    --spatmaskfile Phantom2D/Phantom_mask.mat \
    --outprefix Phantom2D/Phantom2D_data_ladmm_avg_spectra \
    --cbar 0 --color jet --linewidth 3 --ax_scale "log log" \
    --ax_lim "[ 0.05 2 10 200]" --nlevel 15 --file_types "png pdf"

# Plot spectroscopic image
plot_spect_im.sh --spect_imfile Phantom2D/Phantom2D_data_ladmm_spect.mat \
    --imgfile Phantom2D/Phantom_data.mat \
    --spatmaskfile Phantom2D/Phantom_mask.mat \
    --outprefix Phantom2D/Phantom2D_data_spectroscopic_Im \
    --ax_scale log --ax_lims "[0.01 1.5 10 100]" --color jet \
    --threshold .25 --linewidth 3, \
    --enc_idx 3 --file_types png

# Plot component Maps
plot_comp_maps.sh --spect_imfile Phantom2D/Phantom2D_data_ladmm_spect.mat --outprefix \
    Phantom2D/Phantom2D_data_component_maps --spectmaskfile \
    data/Phantom2D_spectrm_mask.mat \
    --cbar 1 --weights 1.4 1 1 --color data/four_color.mat



# create_phantom.sh -a data/acq_phantom.txt -i data/Phantom_spect.txt -o Phantom2D  # or create_phantom
# # spectrum Estimation --ladmm
# spectEstimation.sh -i Phantom2D/Phantom_data.mat -m Phantom2D/Phantom_mask.mat  \
#     -d Phantom2D/Phantom_spectrm_info.mat -c demos/Phantom_ladmm.ini -o Result/Phantom2D_ladmm_spect.mat 

# # spectrum Estimation --admm
# # spectEstimation.sh Phantom2D/Phantom_data.mat Phantom2D/Phantom_mask.mat  \
# #     Phantom2D/Phantom_spectrm_info.mat demos/Phantom_admm.ini Result/Phantom_admm_spect.mat 
# # 
# # spectrum Estimation --nnls
# # spectEstimation.sh Phantom2D/Phantom_data.mat Phantom2D/Phantom_mask.mat  \
# #     Phantom2D/Phantom_spectrm_info.mat demos/Phantom_nnls.ini Result/Phantom_nnls_spect.mat 

# # plot Average spectra
# plotAvgSpectra.sh -i Result/Phantom2D_ladmm_spect.mat -m Phantom2D/Phantom_mask.mat  \
#     -o Result/Phantom2D_data_ladmm_avg_spectra -t png pdf

# # Plot spectroscopic image
# idx=1; # encoding sample chosen to show back ground MR data intensity
# plotspectIm.sh Result/Phantom2D_ladmm_spect.mat Phantom2D/Phantom_data.mat ${idx} \
#     Phantom2D/Phantom_mask.mat Result/Phantom2D_spectroscopic_Im png 

# # Plot component Maps
# plotCompMaps.sh -i Result/Phantom2D_ladmm_spect.mat -m data/spectrum_mask_inj_mouse.mat \
#     -c data/four_color.mat -o Result/Phantom2D_component_maps -t png epsc

