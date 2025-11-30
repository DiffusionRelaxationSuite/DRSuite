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

function plot_spect_im(varargin)
progtime=tic;
p = inputParser;
p.CaseSensitive = true;     
p.PartialMatching = false; 
%required i/p
addParameter(p, 'spect_imfile', '', @(x)ischar(x) || isstring(x));%required
addParameter(p, 'imgfile', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'outprefix', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'spatmaskfile', '', @(x)ischar(x) || isstring(x));
%optional i/p
addParameter(p, 'ax_scale', '', @(x)ischar(x) || isstring(x) || iscell(x));
addParameter(p, 'ax_lims', '', @(x)isvector(x)||ischar(x) || isstring(x));
addParameter(p, 'color', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'enc_idx', '', @(x)ischar(x)|| isstring(x) ||isnumeric(x));
addParameter(p, 'linewidth', '', @(x)ischar(x)|| isstring(x) ||isnumeric(x));
addParameter(p, 'threshold', '', @(x)ischar(x)|| isstring(x) ||isnumeric(x));
addParameter(p, 'file_types', '', @(x)ischar(x) || isstring(x)|| iscell(x));
parse(p, varargin{:});
spect_imfile = p.Results.spect_imfile;
imgfile = p.Results.imgfile;
outprefix = p.Results.outprefix;
spatmaskfile = p.Results.spatmaskfile;
ax_scale = p.Results.ax_scale;
ax_lims = p.Results.ax_lims;
cmap = p.Results.color;
enc_idx = p.Results.enc_idx;
linewidth = p.Results.linewidth;
file_types = p.Results.file_types;
threshold = p.Results.threshold;
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
if isempty(imgfile) ||  ~isfile(imgfile)
    error('Please provide valid file containing MR data...')
else
    img=load(imgfile);
end
if isempty(outprefix)
    error('Please provide file-name to store Averaged spectra...')
end

if isempty(spatmaskfile) || ~isfile(spatmaskfile)
    error('Please provide valid spatial Mask...')
else
    maskfile=load(spatmaskfile);
    spatROImask=maskfile.im_mask;
end
if isempty(ax_scale)
    % this code checks the input axes scale; If nothing provided, it takes
    % the value from axes(i).spacing inside spectfile. If given an input,
    % it checks if there is only one string input of multiple string input.
    % For 1 string input it assigns that value to all the independent
    % variable axes (for 1D line plot its just X-axis and 2D contour plot
    % its both X and Y axis)but the dependent axes are assigned linear by
    % default(i.e., Y axis for line plot and the Z axis for contour line
    % plots) and if two string inputs are given, then for 1D  line plot, the
    % first string value is assigned to the independent axis and the second
    % value is assigned to the dependent axis and for 2D contour plot,
    % first value is assigned to the verticle axis and second value is
    % assigned to the horizontal axis.If mopre than two inputs given it
    % shows error.
    if isscalar(spectfile.spectral_dim)
        plot_info.scale.x=getscale(spectfile.axes(1).spacing);
        plot_info.scale.y='linear';
    end
else
    ax_scale=string(ax_scale);
    if isscalar(ax_scale)
        if isscalar(spectfile.spectral_dim)
            plot_info.scale.x=getscale(ax_scale);
            plot_info.scale.y='linear';
        else
            disp("Axes scaling not available...")
        end
    else
        error('Please provide valid axes scaling...')
    end
end
if isempty(ax_lims)
    %This is the code to check axis limits. If nothing provided, for 1D
    %plot it takes the two end point of the sample points for the independent
    %axis and for 2D plot the independent axis limits are defaulted to the four end
    %points of the sampling points of the two dimensions. When a vector
    %array is given it checks if the user has given valid inputs, i.e., for
    %1D plot it only takes two axis limits, for 2D plot it take 4 axis
    %limits, first two for the vericle axis and second 2 for horizontal
    %axis. it shows error otherwise
    if isscalar(spectfile.spectral_dim)
        plot_info.lim.x=[spectfile.axes(1).sample(1) spectfile.axes(1).sample(end)];
    else
        plot_info.lim.y=[spectfile.axes(1).sample(1) spectfile.axes(1).sample(end)];
        plot_info.lim.x=[spectfile.axes(2).sample(1) spectfile.axes(2).sample(end)];
    end
else
    if ischar(ax_lims) || isstring(ax_lims)
        ax_lims=eval(ax_lims);
    end
    if isscalar(spectfile.spectral_dim)
        if length(ax_lims)==2
            plot_info.lim.x=[ax_lims(1) ax_lims(2)];
        else
            error('please provide valid axes limits')
        end
    else
        if length(ax_lims)==4
            plot_info.lim.y=[ax_lims(1) ax_lims(2)];
            plot_info.lim.x=[ax_lims(3) ax_lims(4)];
        else
            error('please provide valid axes limits')
        end
    end
end
if isempty(cmap)
    % this is the color or colormap input for the plotting. For 1D plot it
    % defaults to red for 2D plot it defaults to jet. If for 1D line plot a matrix input is
    % given it shows text telling matrix is not required
    % and uses default red coloR but if a vector with rgb value in [0,1] is given it takes that color to plot
    % and for 2D plot it uses that colormap
    % matrix to plot the contour map. And if a string is given, for 1D it
    % checks if its among the matlab color table for line plot and for 2D
    % it checks for the matlab default colormaps. If the user provided
    % string is not present, then it uses the default red and jet for 1D
    % and 2D plots respectively
    if isscalar(spectfile.spectral_dim)
        plot_info.cmap='r';
    else
        plot_info.cmap=jet(128);
    end
else
    cmap=string(cmap);
    if isscalar(spectfile.spectral_dim)
        colors_builtin = {'r','g','b','c','m','y','k','w','red',...
            'green','blue','cyan','magenta','yellow','black','white'};
        if ismember(cmap,colors_builtin)
            plot_info.cmap=cmap;
        else
            error("Not a valid color.");
        end
    else
        cmap_builtin = {'parula','jet','hsv','hot','cool','spring','summer','autumn',...
            'winter','gray','bone','copper','pink','lines','colorcube',...
            'prism','flag','white','turbo'};
        if ismember(cmap, cmap_builtin)
            plot_info.cmap=colormap(cmap);
        else
            error("Not a valid colormap");
        end
    end
end
if isempty(enc_idx)
    %This tells what slice among the several encodings will be shown in the background
    enc_idx=1;
else
    if ischar(enc_idx)||isstring(enc_idx)
        enc_idx=str2double(enc_idx);
    end
    if enc_idx>size(img.data,1)
        error(strcat("Encoding index exceeds total number of encoding (",num2str(size(img.data,1)),")"))
    end
end
plot_info.normalise=1;
if isempty(linewidth)
    %This tells about the line width, defaults to 1.2, else uses user
    %defined value
    plot_info.linewidth=1.2;

else
    if isscalar(spectfile.spectral_dim)
        if ischar(linewidth)|| isstring(linewidth)
            linewidth=str2double(linewidth);
        end
        plot_info.linewidth=linewidth;
    else
        disp('Linewidth value not required for 2D spectrum...')
    end

end
if isempty(threshold)
    plot_info.threshold=0.1;
else
    if isscalar(spectfile.spectral_dim)
        disp('Threshold value not required for 1D spectrum...')
    else
        if ischar(threshold)||isstring(threshold)
            threshold=str2double(threshold);
        end
        plot_info.threshold=threshold;
    end
end

if isempty(strtrim(file_types))
    %Input for figure extension types. Default is png. If user gives input
    %among the available types (not case sensitive), it plots them in the
    %available formats, if no valid inputs given, it plots a png file
    plot_info.file_types="png";
else
    file_types=split(string(file_types));
    validExts = ["fig","eps","svg","pdf","bmp","jpg","jpeg","png","tif","tiff"];
    idx = ismember(lower(file_types), validExts);
    validOnes   = file_types(idx);
    if isempty(validOnes)
        disp('No valid extension provided for plotting.')
    else
        fprintf('Saving files with the following extensions: %s\n', strjoin(validOnes));
        plot_info.file_types=lower(validOnes);
    end

end
fprintf(1,'Saving slicewise spectroscopic image to %s*.\n',outprefix);
plot_and_save_spectIm(spectfile,img,enc_idx,spatROImask, outprefix, plot_info)
disp('Finished saving graphics.')
if (ismcc || isdeployed)
    close all
end
fprintf(1,'Program took %f seconds.\n',toc(progtime));
return
