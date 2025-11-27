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
function compile_cli(versno)
% builds cli_plot_composite_maps.m  cli_plot_spectra.m  cli_solver.m
    if (nargin<1)
        versno='v25a';
    end
    exec_extension='';
    architecture='';
    if ismac
        exec_extension='.app';
        [~,m]=system('uname -m'); m=strtrim(m);
        architecture=['mac_' m];
    elseif ispc
        architecture='win'
        exec_extension='.exe';
    else % assume linux
        [~,m]=system('uname -m'); m=strtrim(m);
        architecture=['linux_' m];
    end
    pkgname=sprintf('drsuite_%s_%s',versno,architecture)
    pkgdir=fullfile('.',pkgname);
    if exist(pkgdir, 'dir'); rmdir(pkgdir,'s'); end
    [~, ~, ~] = mkdir(pkgdir);
    bindir=fullfile(pkgdir,'/bin')
    if exist(bindir, 'dir'); rmdir(bindir,'s'); end
    [~, ~, ~] = mkdir(bindir);
    copyfile('LICENSE.txt',pkgdir)
    copyfile('readme.md',pkgdir);
    copyfile('ini2struct/license.txt',fullfile(pkgdir,'ini2struct_license.txt'))

    builddir='./build';
    if exist(builddir, 'dir'); rmdir(builddir,'s'); end
    [~, ~, ~] = mkdir(builddir);

    srcfiles=[ "plot_avg_spectra", "plot_comp_maps",...
        "plot_spect_im", "plot_beta_sweep", ...
        "estimate_crlb","estimate_spectra", ...
          "create_phantom" ];
    for i=1:length(srcfiles)
        mfile=sprintf("%s.m",srcfiles(i));
        efile=sprintf("%s%s",srcfiles(i),exec_extension);
        fprintf(1,"compiling %s to %s\n",mfile,efile);
        mcc("-m","-d",builddir,"-a","utilities",...
            "-a","solvers", "-a","ini2struct",...
            sprintf("%s.m",srcfiles(i)))
        if ~ispc
            sfile=sprintf("%s.sh",srcfiles(i));
            dest=fullfile(bindir,sfile);
            fprintf('updating %s...\n',sfile)
            writelines(change_runtime_version(fullfile('scripts',sfile)),dest);
            fileattrib(dest, '+x', 'all') 
        end
        movefile(fullfile(builddir,efile),fullfile(bindir,efile))
    end
    zipfile=fullfile(pwd,[pkgname '.zip'])
    zip(zipfile,pkgdir)
    fprintf(1,'saved package to %s',zipfile)
return
