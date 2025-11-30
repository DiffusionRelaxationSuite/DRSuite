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

function estimate_spectra(varargin)
programTimer=tic;
p = inputParser;
p.CaseSensitive = true;     
p.PartialMatching = false; 
%required i/p
addParameter(p, 'imgfile', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'spect_infofile', '', @(x)ischar(x) || isstring(x));%optional
addParameter(p, 'outprefix', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'configfile', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'spatmaskfile', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'cost_calc', '', @(x)ischar(x)|| isstring(x) ||isnumeric(x));

parse(p, varargin{:});
spect_infofile = p.Results.spect_infofile;
imgfile = p.Results.imgfile;
outprefix = p.Results.outprefix;
configfile = p.Results.configfile;
spatmaskfile = p.Results.spatmaskfile;
cost_calc = p.Results.cost_calc;
if isempty(imgfile) ||  ~isfile(imgfile)
    error('Please provide valid file containing MR data...')
else
    img=load(imgfile);
    spatial_dim=img.spatial_dim;
    resolution=img.resolution;
    transform=img.transform;
end

if isempty(spect_infofile) ||  ~isfile(spect_infofile)
    error('Please provide valid file containing Spectrum Information...')
else
    spectInfo= load(spect_infofile);
    spectral_dim=spectInfo.spectral_dim;
end
if isempty(configfile) ||  ~isfile(configfile)
    error('Please provide valid file containing algorithm configuration...')
else
    params=ini2struct(configfile);
    params.spect_est=1;
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
                disp("DC component flag not present, choosing 1.")
                params.dc_comp=1;
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
                params.solver.check_tol=params.solver.num_iter/2;
            end
            if ~isfield(params.solver,'save_inter')
                params.solver.save_inter=params.solver.num_iter/10;
            end
        end
        if strcmpi(params.solver.name,"LADMM")
            if ~isfield(params,'low_rank')
                disp('Low rank field doesnt exist in config file, solving using full rank dictionary matrix.');
                params.low_rank.flag=false;
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
if isempty(spatmaskfile) || ~isfile(spatmaskfile)
    sprintf('No valid spatial mask provided, calculating spectra over all voxels...')
    spatROImask=ones(spectfile.spatial_dim);
else
    maskfile=load(spatmaskfile);
    spatROImask=maskfile.im_mask;
end
if isempty(cost_calc)
    params.beta_calc=1;
else
    if ischar(cost_calc)|| isstring(cost_calc)
        cost_calc=str2double(cost_calc);
    end
    params.beta_calc=cost_calc;
end
fprintf(1,'Running %s solver...\n',params.solver.name)
solverTimer=tic;
if  params.beta_calc && ~strcmpi(params.solver.name,'nnls')
    [spectral_image,out]=run_solver(img,spatROImask,spectInfo,params);
    plot_cost_vs_iter(out,params,outprefix)
    if (ismcc || isdeployed)
        close all
    end
    % out_sum=0;
    % min_len=Inf;
    % for i=1:length(out)
    %     min_len=min(min_len,length(out(i).cost1));
    % end
    % for i=1:length(out)
    %     out_sum=out_sum+out(i).cost1(1:min_len)+out(i).cost2(1:min_len);
    % end
    % fig = figure('Color','w','Units','pixels','Position',[200 200 400 800],'Visible', 'off');
    % ax = axes('Parent',fig);
    % figure(fig);
    % semilogy(0:length(out_sum)-1,out_sum);
    % xlabel(strcat("iteration number x",num2str(params.solver.save_inter),""));
    % ylim([0.85*min(out_sum(:)) 1.15*max(out_sum(:))])
    % xlim([0 length(out_sum)-1])
    % ylabel('cost function');
    % title('Averaged Cost Function vs iter no.')
    % set(gca, 'Color', 'w');
    % set(findall(gcf, 'Type', 'text'), 'Color', 'k');
    %
    % % Make axis tick labels and axes lines black
    % set(gca, 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k');
    %
    % axis square
    % ofname=sprintf('%s_costVsiter_single_beta',outprefix);
    % fprintf(1,'Saving %s.png\n', ofname);
    % saveas(fig,ofname,'png')
    % close all
else
    spectral_image=run_solver(img,spatROImask,spectInfo,params);
end
fprintf(1,'%s solver took %f seconds\n',params.solver.name,toc(solverTimer))
k=1;
for i=1:length(spectral_dim)
    axes(i).type='spectral';
    axes(i).sample=spectInfo.axes(i).sample;
    axes(i).spacing=spectInfo.axes(i).spacing;
    axes(i).unit=spectInfo.axes(i).unit;
    axes(i).name=spectInfo.axes(i).name;
    k=k+1;
end
j=1;
for i=k:k-1+length(spatial_dim)
    axes(i).type='spatial';
    switch j
        case 1, axes(i).name='x';
        case 2, axes(i).name='y';
        case 3, axes(i).name='z';
    end
    axes(i).unit='mm';
    axes(i).spacing='linear';
    j=j+1;
end
save(outprefix,"spectral_image","axes","spectral_dim","spatial_dim","resolution","transform",'-v7.3')
fprintf(1,'Saved result to %s\n',outprefix)
fprintf(1,'Total program time: %f seconds\n',toc(programTimer))
return
