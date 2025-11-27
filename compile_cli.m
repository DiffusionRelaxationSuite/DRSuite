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
    pkgdir='bin';
    builddir='build';
    [~, ~, ~] = mkdir(pkgdir);
    [~, ~, ~] = mkdir(builddir);
    % cd build
    Ext='';
    if ismac
        Ext='.app';
    elseif ispc
        Ext='.exe'
    end
    srcfiles=[ "plot_avg_spectra", "plot_comp_maps",...
        "plot_spect_im", "plot_beta_sweep", ...
        "estimate_crlb","estimate_spectra", ...
          "create_phantom" ];
    for i=1:length(srcfiles)
        mfile=sprintf("%s.m",srcfiles(i));
        efile=sprintf("%s%s",srcfiles(i),Ext);
        fprintf(1,"compiling %s to %s\n",mfile,efile);
        mcc("-m","-d",builddir,"-a","utilities",sprintf("%s.m",srcfiles(i)))
        if ~ispc
            sfile=sprintf("%s.sh",srcfiles(i));
            dest=fullfile(pkgdir,sfile);
            fprintf('updating %s...',srcfiles(i))
            writelines(change_runtime_version(fullfile('scripts',sfile)),dest);
            fileattrib(dest, '+x', 'all') 
        end
        movefile(fullfile(builddir,efile),fullfile(pkgdir,efile))
    end
    zip('cli.zip','bin')                
return
