#!/bin/bash
set -e
RootDir="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/
PATH="$RootDir/bin:$PATH"

if [[ "$NO_COLOR" == "" ]]; then Color="\33[0;32m"; Clear="\33[0;0m"; fi;
printf "${Color}Creating phantom with 2D spectral encoding.${Clear}\n"

printf "${Color}Creating phantom...${Clear}\n"
create_phantom.sh --acqfile data/acq_phantom.txt \
    --spectfile data/Phantom_spect.txt \
    --outfolder Phantom2D --multislice 1

printf "${Color}Running beta sweep...${Clear}\n"
plot_beta_sweep.sh --imgfile Phantom2D/Phantom_data.mat \
    --betafile data/betafile_phantom2d.txt \
    --spect_infofile Phantom2D/Phantom_spectrm_info.mat \
    --outprefix Phantom2D/Phantom_data_ladmm_spect \
    --configfile demos/Phantom2D_ladmm.ini --spatmaskfile \
    Phantom2D/Phantom_mask_beta_calc.mat --file_types png

printf "${Color}Estimating spectra (ladmm)...${Clear}\n"
estimate_spectra.sh --imgfile Phantom2D/Phantom_data.mat \
    --spect_infofile Phantom2D/Phantom_spectrm_info.mat \
    --outprefix Phantom2D/Phantom2D_data_ladmm_spect \
    --configfile demos/Phantom2D_ladmm.ini \
    --spatmaskfile Phantom2D/Phantom_mask.mat

printf "${Color}Estimating spectra (admm)...${Clear}\n"
estimate_spectra.sh --imgfile Phantom2D/Phantom_data.mat \
    --spect_infofile Phantom2D/Phantom_spectrm_info.mat \
    --outprefix Phantom2D/Phantom2D_data_admm_spect.mat \
    --configfile demos/Phantom2D_admm.ini \
    --spatmaskfile Phantom2D/Phantom_mask.mat --cost_calc 1

printf "${Color}Estimating spectra (nnls)...${Clear}\n"
estimate_spectra.sh --imgfile Phantom2D/Phantom_data.mat \
    --spect_infofile Phantom2D/Phantom_spectrm_info.mat \
    --outprefix Phantom2D/Phantom2D_data_nnls_spect.mat \
    --configfile demos/Phantom2D_nnls.ini \
    --spatmaskfile Phantom2D/Phantom_mask.mat

printf "${Color}Plotting average spectra...${Clear}\n"
plot_avg_spectra.sh --spect_imfile Phantom2D/Phantom2D_data_ladmm_spect.mat \
    --spatmaskfile Phantom2D/Phantom_mask.mat \
    --outprefix Phantom2D/Phantom2D_data_ladmm_avg_spectra \
    --cbar 0 --color jet --linewidth 3 --ax_scale log \
    --ax_lims "[ 0.05 2 10 200]" --nlevel 15 --file_types "png pdf"

printf "${Color}Plotting spectroscopic image...${Clear}\n"
plot_spect_im.sh --spect_imfile Phantom2D/Phantom2D_data_ladmm_spect.mat \
    --imgfile Phantom2D/Phantom_data.mat \
    --spatmaskfile Phantom2D/Phantom_mask.mat \
    --outprefix Phantom2D/Phantom2D_data_spectroscopic_Im \
    --ax_scale log --ax_lims "[0.01 1.5 10 100]" --color jet \
    --threshold .25 --linewidth 3 \
    --enc_idx 3 --file_types png

printf "${Color}Plotting component maps...${Clear}\n"
plot_comp_maps.sh --spect_imfile Phantom2D/Phantom2D_data_ladmm_spect.mat --outprefix \
    Phantom2D/Phantom2D_data_component_maps --spectmaskfile \
    data/Phantom2D_spectrm_mask.mat \
    --cbar 1 --weights "[1.4 1 1]" --color data/four_color.mat

printf "${Color}Finished phantom 2D workflow!${Clear}\n"
