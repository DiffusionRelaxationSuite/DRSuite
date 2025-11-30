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

function plot_comp_maps(varargin)

progtime=tic;
p = inputParser;
%required i/p
addParameter(p, 'spect_imfile', '', @(x)ischar(x) || isstring(x));%required
addParameter(p, 'outprefix', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'spectmaskfile', '', @(x)ischar(x) || isstring(x));
%optional i/p
addParameter(p, 'color', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'weights', '', @(x)ischar(x)|| isstring(x) ||isvector(x));
addParameter(p, 'cbar', '', @(x)ischar(x)|| isstring(x) ||isnumeric(x));
addParameter(p, 'file_types', '', @(x)ischar(x) || isstring(x)|| iscell(x));
parse(p, varargin{:});
spect_imfile = p.Results.spect_imfile;
outprefix = p.Results.outprefix;
spectmaskfile = p.Results.spectmaskfile;
file_types = p.Results.file_types;
colorfile = p.Results.color;
cbar = p.Results.cbar;
weights=p.Results.weights;
if isempty(spect_imfile) ||  ~isfile(spect_imfile)
    error('Please provide valid file containing spectroscopic image...')
else
    spectfile=load(spect_imfile);
    if length(spectfile.spectral_dim)>=3
        error('Please provide data with spectral dimension less than 3...')
    end
    if isscalar(spectfile.spatial_dim)
        error('Please provide data with spatial dimension more than 1...')
    end
end
if isempty(outprefix)
    error('Please provide file-name to store Averaged spectra...')
end

if isempty(spectmaskfile) || ~isfile(spectmaskfile)
    error('Please provide spectral mask')
else
    maskfile=load(spectmaskfile);
end
if isempty(colorfile)
    plot_info.cmap=[
        0.0000 0.4470 0.7410;  % MATLAB Blue
        0.8500 0.3250 0.0980; % Orange
        0.9290 0.6940 0.1250;  % Yellow
        0.4940 0.1840 0.5560;  % Purple
        0.4660 0.6740 0.1880;  % Green
        0.3010 0.7450 0.9330;  % Light Blue (Cyan-ish)
        0.6350 0.0780 0.1840;  % Maroon
        1.0000 1.0000 1.0000;  % White
        0.0000 1.0000 1.0000;  % Aqua
        1.0000 0.0000 1.0000;  % Magenta
        1.0000 0.0000 0.0000;  % Red
        0.0000 1.0000 0.0000;  % Lime
        0.8000 0.8000 0.8000;  % Light Gray
        ]';
else
    c=load(colorfile,'color');
    plot_info.cmap=c.color;
    if (maskfile.num_comp>size(c.color,2))
        error("Please provide valid number of colors for each components");
    end
end
if isempty(cbar)
    plot_info.cbar=0;
else
    if ischar(cbar)|| isstring(cbar)
        cbar=str2double(cbar);
    end
    plot_info.cbar=cbar;
end
if isempty(file_types)
    %Input for figure extension types. Default is png. If user gives input
    %among the available types (not case sensitive), it plots them in the
    %available formats, if no valid inputs given, it plots a png file
    plot_info.file_types="png";
else
    file_types=split(string(file_types));
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
if isempty(weights)
    plot_info.weights=ones(maskfile.num_comp,1);
else
    if ischar(weights) || isstring(weights)
        weights=eval(weights);
    end
    if length(weights)==maskfile.num_comp
        plot_info.weights=weights;
    else
        error("Number of weights doesn't match with the number of components");
    end
end
resolution=spectfile.resolution;
transform=spectfile.transform;
spatial_dim=spectfile.spatial_dim;
num_comp=maskfile.num_comp;
fprintf(1,'Saving composite maps to %s*.\n',outprefix);
data=plot_and_save_comp_maps(spectfile, maskfile,outprefix,plot_info);
save(strcat(outprefix,'.mat'),"data","resolution","transform","spatial_dim","num_comp",'-v7.3')
disp('Finished saving composite maps plot and the data');
if (ismcc || isdeployed)
    close all
end
fprintf(1,'Program took %f seconds.\n',toc(progtime));
return
