@echo off
REM Creating phantom with 2D spectral encoding.
set "RootDir=%~dp0"
set "PATH=%RootDir%bin;%PATH%"

echo on

echo Creating phantom...
"%RootDir%bin\create_phantom.exe" --acqfile data/acq_phantom.txt --spectfile data/Phantom_spect.txt --outfolder Phantom2D --multislice 1
if %errorlevel% neq 0 exit /b %errorlevel%

echo Running beta sweep...
"%RootDir%bin\plot_beta_sweep.exe" --imgfile Phantom2D/Phantom_data.mat --betafile data/betafile_phantom2d.txt --spect_infofile Phantom2D/Phantom_spectrm_info.mat --outprefix Phantom2D/Phantom_data_ladmm_spect --configfile demos/Phantom2D_ladmm.ini --spatmaskfile Phantom2D/Phantom_mask_beta_calc.mat --file_types png
if %errorlevel% neq 0 exit /b %errorlevel%

echo Estimating spectra (ladmm)
"%RootDir%bin\estimate_spectra.exe" --imgfile Phantom2D/Phantom_data.mat --spect_infofile Phantom2D/Phantom_spectrm_info.mat --outprefix Phantom2D/Phantom2D_data_ladmm_spect --configfile demos/Phantom2D_ladmm.ini --spatmaskfile Phantom2D/Phantom_mask.mat
if %errorlevel% neq 0 exit /b %errorlevel%

echo Estimating spectra (admm)
"%RootDir%bin\estimate_spectra.exe" --imgfile Phantom2D/Phantom_data.mat --spect_infofile Phantom2D/Phantom_spectrm_info.mat --outprefix Phantom2D/Phantom2D_data_admm_spect.mat --configfile demos/Phantom2D_admm.ini --spatmaskfile Phantom2D/Phantom_mask.mat --cost_calc 1
if %errorlevel% neq 0 exit /b %errorlevel%

echo Estimating spectra (nnls)
"%RootDir%bin\estimate_spectra.exe" --imgfile Phantom2D/Phantom_data.mat --spect_infofile Phantom2D/Phantom_spectrm_info.mat --outprefix Phantom2D/Phantom2D_data_nnls_spect.mat --configfile demos/Phantom2D_nnls.ini --spatmaskfile Phantom2D/Phantom_mask.mat
if %errorlevel% neq 0 exit /b %errorlevel%

echo Plotting average spectra...
"%RootDir%bin\plot_avg_spectra.exe" --spect_imfile Phantom2D/Phantom2D_data_ladmm_spect.mat --spatmaskfile Phantom2D/Phantom_mask.mat --outprefix Phantom2D/Phantom2D_data_ladmm_avg_spectra --cbar 0 --color jet --linewidth 3 --ax_scale log --ax_lim "[ 0.05 2 10 200]" --nlevel 15 --file_types "png pdf"
if %errorlevel% neq 0 exit /b %errorlevel%

echo Plotting spectroscopic image...
"%RootDir%bin\plot_spect_im.exe" --spect_imfile Phantom2D/Phantom2D_data_ladmm_spect.mat --imgfile Phantom2D/Phantom_data.mat --spatmaskfile Phantom2D/Phantom_mask.mat --outprefix Phantom2D/Phantom2D_data_spectroscopic_Im --ax_scale log --ax_lims "[0.01 1.5 10 100]" --color jet --threshold .25 --linewidth 3 --enc_idx 3 --file_types png
if %errorlevel% neq 0 exit /b %errorlevel%

echo Plotting component maps...
"%RootDir%bin\plot_comp_maps.exe" --spect_imfile Phantom2D/Phantom2D_data_ladmm_spect.mat --outprefix Phantom2D/Phantom2D_data_component_maps --spectmaskfile data/Phantom2D_spectrm_mask.mat --cbar 1 --weights "[1.4 1 1]" --color data/four_color.mat
if %errorlevel% neq 0 exit /b %errorlevel%

echo Done!