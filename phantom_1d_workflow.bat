@echo off
ECHO Creating phantom with 1D spectral encoding.
set "RootDir=%~dp0"
set "PATH=%RootDir%bin;%PATH%"

echo on

echo Creating phantom...
"create_phantom.exe" acqfile data/acq_phantom1D.txt spectfile data/Phantom1D_spect.txt outfolder Phantom1D multislice 0
if %errorlevel% neq 0 exit /b %errorlevel%

echo Running beta sweep...
"plot_beta_sweep.exe" imgfile Phantom1D/Phantom_data.mat betafile data/betafile_phantom1d.txt spect_infofile Phantom1D/Phantom_spectrum_info.mat outprefix Phantom1D/Phantom_data_ladmm_spect configfile demos/Phantom1D_ladmm.ini spatmaskfile Phantom1D/Phantom_mask_beta_calc.mat file_types png
if %errorlevel% neq 0 exit /b %errorlevel%

echo Estimating spectra (ladmm)...
"estimate_spectra.exe" imgfile Phantom1D/Phantom_data.mat spect_infofile Phantom1D/Phantom_spectrum_info.mat outprefix Phantom1D/Phantom1D_data_ladmm_spect.mat configfile demos/Phantom1D_ladmm.ini spatmaskfile Phantom1D/Phantom_mask.mat
if %errorlevel% neq 0 exit /b %errorlevel%

echo Estimating spectra (admm)...
"estimate_spectra.exe" imgfile Phantom1D/Phantom_data.mat spect_infofile Phantom1D/Phantom_spectrum_info.mat outprefix Phantom1D/Phantom1D_data_admm_spect.mat configfile demos/Phantom1D_admm.ini spatmaskfile Phantom1D/Phantom_mask.mat
if %errorlevel% neq 0 exit /b %errorlevel%

echo Estimating spectra (nnls)...
"estimate_spectra.exe" imgfile Phantom1D/Phantom_data.mat spect_infofile Phantom1D/Phantom_spectrum_info.mat outprefix Phantom1D/Phantom1D_data_nnls_spect.mat configfile demos/Phantom1D_nnls.ini spatmaskfile Phantom1D/Phantom_mask.mat
if %errorlevel% neq 0 exit /b %errorlevel%

echo Plotting average spectra...
REM Plot Average spectra
"plot_avg_spectra.exe" spect_imfile Phantom1D/Phantom1D_data_ladmm_spect.mat spatmaskfile Phantom1D/Phantom_mask.mat outprefix Phantom1D/Phantom1D_data_ladmm_avg_spectra linewidth 3 ax_scale log color g cbar 1 ax_lims "[10 200]" file_types png
if %errorlevel% neq 0 exit /b %errorlevel%

echo Plotting spectroscopic image...
REM Plot spectroscopic image
"plot_spect_im.exe" spect_imfile Phantom1D/Phantom1D_data_ladmm_spect.mat imgfile Phantom1D/Phantom_data.mat spatmaskfile Phantom1D/Phantom_mask.mat outprefix Phantom1D/Phantom1D_data_spectroscopic_Im threshold .2 linewidth 1 enc_idx 8 ax_scale log color g ax_lims "[10 200]" file_types png
if %errorlevel% neq 0 exit /b %errorlevel%

echo Plotting component maps...
REM Plot component Maps
"plot_comp_maps.exe" spect_imfile Phantom1D/Phantom1D_data_ladmm_spect.mat spectmaskfile data/Phantom1D_spectrum_mask.mat color data/four_color.mat outprefix Phantom1D/Phantom1D_component_maps cbar 0 weights "[1 3]"
if %errorlevel% neq 0 exit /b %errorlevel%

echo Finished phantom 1D workflow!
