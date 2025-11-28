% Copyright (C) 2025 University of Southern California and theRegents of the University of California
%
% Created by Debdut Mandal, Anand A. Joshi, David W. Shattuck, Justin P. Haldar
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

function plot_beta_sweep(varargin)
programTimer=tic;
p = inputParser;
%required i/p
addParameter(p, 'imgfile', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'spect_infofile', '', @(x)ischar(x) || isstring(x));%required
addParameter(p, 'outprefix', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'configfile', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'spatmaskfile', '', @(x)ischar(x) || isstring(x));
%optional i/p
addParameter(p, 'betafile', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'file_types', '', @(x)ischar(x) || isstring(x)|| iscell(x));

parse(p, varargin{:});
spect_infofile = p.Results.spect_infofile;
imgfile = p.Results.imgfile;
betafile = p.Results.betafile;
outprefix = p.Results.outprefix;
configfile = p.Results.configfile;
spatmaskfile = p.Results.spatmaskfile;
file_types = p.Results.file_types;

if isempty(imgfile) ||  ~isfile(imgfile)
    error('Please provide valid file containing MR data...')
else
    img=load(imgfile);
end
if isempty(configfile) ||  ~isfile(configfile)
    error('Please provide valid file containing algorithm configuration...')
else
    params=ini2struct(configfile);
    if ~isfield(params,'solver')
        error("Please provide solver information.")
    else
        if ~isfield(params.solver,'name')
            error('Please provide solver algorithm name in config file.');
        end
        if strcmpi(params.solver.name,"LADMM") || strcmpi(params.solver.name,"ADMM")
            if ~isfield(params,'lambda')
                error('Please provide lambda value in the config file.');
            end
            if ~isfield(params,'dc_comp')
                error("DC component flag not present, choosing 1.")
                % params.dc_comp=1;
            end
            if ~isfield(params.solver,'num_iter')
                error('Please provide max number of iteration value in the config file.');
            end
            if ~isfield(params.solver,'beta')
                error('Please provide beta value in the config file.');
            end
            if ~isfield(params.solver,'tol')
                params.solver.tol=1e-5;
            end
            if ~isfield(params.solver,'check_tol')
                params.solver.check_tol=round(params.solver.num_iter/2);
            end
            if ~isfield(params.solver,'save_inter')
                params.solver.save_inter=round(params.solver.num_iter/10);
            end
        else
            error("Unrecognised solver, exiting...")
        end
        if strcmpi(params.solver.name,"LADMM")
            if ~isfield(params,'low_rank')
                error('Low rank field doesnt exist in config file, solving using full rank dictionary matrix.');
                % params.low_rank.flag=false;
            else
                if ~isfield(params.low_rank,'flag')
                    error("Please provide 'flag' for the low_rank field.")
                else
                    if params.low_rank.flag && ~isfield(params.low_rank,'rank')
                        error("Please provide 'rank' for the low_rank field.")
                    end
                end
            end
        end
    end
end
if isempty(betafile) ||  ~isfile(betafile)
    disp(strcat("beta file not provided, Choosing beta values around ",num2str(params.solver.beta)))
    beta_vals=params.solver.beta*[0.01 0.1 1 10 100];
    params.solver.beta=beta_vals;
else
    txt = fileread(betafile);
    eval(txt);
    params.solver.beta=beta_vals;

end

if isempty(spect_infofile) || ~isfile(spect_infofile)
     error('Please provide valid file containing Spectrum Information...')
else
    spectInfo= load(spect_infofile);
end

if isempty(spatmaskfile) || ~isfile(spatmaskfile)
    error('No spatial mask provided...')
else
    maskfile=load(spatmaskfile);
    spatROImask=maskfile.im_mask;
end

if isempty(file_types)
    %Input for figure extension types. Default is png. If user gives input
    %among the available types (not case sensitive), it plots them in the
    %available formats, if no valid inputs given, it plots a png file
    plot_info.file_types="png";
else
    file_types=string(file_types);
    validExts = ["fig","m","eps","epsc","ai","pdf","bmp","jpg","jpeg","png","tif","tiff"];
    idx = ismember(lower(file_types), validExts);
    validOnes   = file_types(idx);
    if isempty(validOnes)
        error('No valid extension provided for plotting.')
        % plot_info.file_types="png";
    else
        fprintf('Saving files with the following extensions: %s\n', strjoin(validOnes));
        plot_info.file_types=lower(validOnes);
    end

end
fprintf(1,'Saving CostFunction vs iter plot for multiple beta to %s*.\n',outprefix);
plot_and_save_for_beta_calc(img,spatROImask,spectInfo,params,outprefix,plot_info.file_types)
fprintf(1,'Total program time: %f seconds\n',toc(programTimer))
return