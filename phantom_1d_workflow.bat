@echo off
set "RootDir=%~dp0"
set "PATH=%RootDir%bin;%PATH%"


REM create phantom with 1D spectral encoding
REM Phantom generation
if not exist "Result" mkdir Result

"%RootDir%bin\create_phantom.exe" acqfile data/acq_phantom1D.txt spectfile data/Phantom1D_spect.txt outfolder Phantom1D
if %errorlevel% neq 0 exit /b %errorlevel%

REM Spectrum Estimation --ladmm
"%RootDir%bin\estimate_spectra.exe" imgfile Phantom1D/Phantom_data.mat spatmaskfile Phantom1D/Phantom_mask.mat spect_infofile Phantom1D/Phantom_spectrm_info.mat configfile demos/Phantom1D_ladmm.ini outprefix Result/Phantom1D_ladmm_spect.mat
if %errorlevel% neq 0 exit /b %errorlevel%







REM Plot Average spectra
"%RootDir%bin\plot_avg_spectra.exe" spect_imfile Result/Phantom1D_ladmm_spect.mat spatmaskfile Phantom1D/Phantom_mask.mat outprefix Result/Phantom1D_data_ladmm_avg_spectra file_types pdf

REM Plot spectroscopic image
REM encoding sample chosen to show background MR data intensity
set idx=9
REM "%RootDir%bin\plot_spect_im.exe" Result/Phantom1D_ladmm_spect.mat Phantom1D/Phantom_data.mat %idx% Phantom1D/Phantom_mask.mat Result/Phantom1D_spectroscopic_Im png
REM if %errorlevel% neq 0 exit /b %errorlevel%

REM Plot component Maps
"%RootDir%bin\plot_comp_maps.exe" spect_imfile Result/Phantom1D_ladmm_spect.mat spectmaskfile data/Phantom1D_spectrm_mask.mat color data/four_color.mat outprefix Result/Phantom1D_component_maps file_types epsc
if %errorlevel% neq 0 exit /b %errorlevel%

