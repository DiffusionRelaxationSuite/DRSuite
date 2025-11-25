% Copyright (C) 2025 University of Southern California and theRegents of the University of California
%
% Created by David W. Shattuck, Debdut Mandal, Anand A. Joshi, Justin P. Haldar
%
% This file is part of DRSuite.
%
% The DRSuite is free software; you can redistribute it and/or
% modify it under the terms of the GNU Lesser General Public License
% as published by the Free Software Foundation, version 2.1.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
% Lesser General Public License for more details.
% 
% You should have received a copy of the GNU Lesser General Public
% License along with this library; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
function compile_cli()
% builds cli_plot_composite_maps.m  cli_plot_spectra.m  cli_solver.m
    [~, ~, ~] = mkdir('bin');
    [~, ~, ~] = mkdir('build');
    cd build
    Ext='';
    if ismac
        Ext='.app';
    end
    mcc -m -a ../utilities ../plot_avg_spectra.m -o plot_avg_spectra
    movefile(['plot_avg_spectra' Ext],'../bin')
    mcc -m -a ../utilities ../plot_comp_maps.m -o plot_comp_maps
    movefile(['plot_comp_maps' Ext],'../bin')
    mcc -m -a ../utilities ../plot_spect_im.m -o plot_spect_im
    movefile(['plot_spect_im' Ext],'../bin')
    mcc -m -a ../solvers -a ../ini2struct -a ../utilities ../plot_beta_sweep.m -o plot_beta_sweep
    movefile(['plot_beta_sweep' Ext],'../bin')
    mcc -m -a ../utilities ../estimate_crlb.m -o estimate_crlb
    movefile(['estimate_crlb' Ext],'../bin')
    mcc -m -a ../solvers -a ../ini2struct -a ../utilities ../estimate_spectra.m -o estimate_spectra
    movefile(['estimate_spectra' Ext],'../bin')
    mcc -m -a ../utilities ../create_phantom.m -o create_phantom
    movefile(['create_phantom' Ext],'../bin')
    cd ..
    zip('cli.zip','bin')                
return