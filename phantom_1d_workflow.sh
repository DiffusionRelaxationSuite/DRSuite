#!/bin/bash
# set -e
RootDir="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/
PATH="$RootDir/bin:$PATH"

if [[ -z "$NO_COLOR" ]]; then Color="\33[0;32m"; Clear="\33[0;0m"; fi;
printf "${Color}Creating phantom with 1D spectral encoding.${Clear}\n"

printf "${Color}Creating phantom...${Clear}\n"
create_phantom.sh --acqfile data/acq_phantom1D.txt --spectfile data/Phantom1D_spect.txt \
    --outfolder Phantom1D --multislice 0

printf "${Color}Running beta sweep...${Clear}\n"
plot_beta_sweep.sh --imgfile Phantom1D/Phantom_data.mat --betafile data/betafile_phantom1d.txt \
    --spect_infofile Phantom1D/Phantom_spectrum_info.mat \
    --outprefix Phantom1D/Phantom_data_ladmm_spect --configfile demos/Phantom1D_ladmm.ini \
    --spatmaskfile Phantom1D/Phantom_mask_beta_calc.mat --file_types png

printf "${Color}Estimating spectra (ladmm)...${Clear}\n"
estimate_spectra.sh --imgfile Phantom1D/Phantom_data.mat \
    --spect_infofile Phantom1D/Phantom_spectrum_info.mat \
    --outprefix Phantom1D/Phantom1D_data_ladmm_spect.mat \
    --configfile demos/Phantom1D_ladmm.ini --spatmaskfile Phantom1D/Phantom_mask.mat

printf "${Color}Estimating spectra (admm)...${Clear}\n"
estimate_spectra.sh --imgfile Phantom1D/Phantom_data.mat \
    --spect_infofile Phantom1D/Phantom_spectrum_info.mat \
    --outprefix Phantom1D/Phantom1D_data_admm_spect.mat \
    --configfile demos/Phantom1D_admm.ini --spatmaskfile Phantom1D/Phantom_mask.mat

printf "${Color}Estimating spectra (nnls)...${Clear}\n"
estimate_spectra.sh --imgfile Phantom1D/Phantom_data.mat \
    --spect_infofile Phantom1D/Phantom_spectrum_info.mat \
    --outprefix Phantom1D/Phantom1D_data_nnls_spect.mat \
    --configfile demos/Phantom1D_nnls.ini --spatmaskfile Phantom1D/Phantom_mask.mat

printf "${Color}Plotting average spectra...${Clear}\n"
plot_avg_spectra.sh --spect_imfile Phantom1D/Phantom1D_data_ladmm_spect.mat \
    --spatmaskfile Phantom1D/Phantom_mask.mat \
    --outprefix Phantom1D/Phantom1D_data_ladmm_avg_spectra --linewidth 3 \
    --ax_scale log --color g --cbar 1 --ax_lims "[10 200]" \
    --file_types "png pdf"

printf "${Color}Plotting spectroscopic image...${Clear}\n"
plot_spect_im.sh --spect_imfile Phantom1D/Phantom1D_data_ladmm_spect.mat \
    --imgfile Phantom1D/Phantom_data.mat --spatmaskfile Phantom1D/Phantom_mask.mat \
    --outprefix Phantom1D/Phantom1D_data_spectroscopic_Im --threshold .2 \
    --linewidth 1 --enc_idx 8 --ax_scale log --color g \
    --ax_lims "[10 200]" --file_types "png jpg"

printf "${Color}Plotting component maps...${Clear}\n"
plot_comp_maps.sh --spect_imfile Phantom1D/Phantom1D_data_ladmm_spect.mat \
    --spectmaskfile data/Phantom1D_spectrum_mask.mat \
    --color data/four_color.mat --outprefix Phantom1D/Phantom1D_component_maps \
    --cbar 0 --weights "[1 3]" --file_types png

printf "${Color}Finished phantom 1D workflow!${Clear}\n"
