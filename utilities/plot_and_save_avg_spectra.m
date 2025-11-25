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
function plot_and_save_avg_spectra(spectfile,spatROImask,outprefix, plot_info)

dim_spat=1;
for i=1:length(spectfile.spatial_dim)
    dim_spat=dim_spat*spectfile.spatial_dim(i);
end
dim_spec=1;
for i=1:length(spectfile.spectral_dim)
    dim_spec=dim_spec*spectfile.spectral_dim(i);
end
spectIm=reshape(spectfile.spectral_image,dim_spec,dim_spat);
idx = find(spatROImask);
roi_avg_spect=sum(spectIm(:,idx),2)/length(idx);
if length(spectfile.spectral_dim)~=1
    roi_avg_spect=reshape(roi_avg_spect,spectfile.spectral_dim);
end
if ~isscalar(spectfile.spectral_dim)
    figure('Visible','off','Color','w')
    contour(spectfile.axes(2).sample,spectfile.axes(1).sample,roi_avg_spect,plot_info.nlevel,'LineWidth',plot_info.linewidth);
    ylabel(strcat(spectfile.axes(1).name,'(',spectfile.axes(1).unit,')'));
    xlabel(strcat(spectfile.axes(2).name,'(',spectfile.axes(2).unit,')'))
    set(gca,'XScale',plot_info.scale.x,"YScale",plot_info.scale.y)
    xlim(plot_info.lim.x);ylim(plot_info.lim.y)
    colormap(plot_info.cmap);
    if plot_info.cbar
        cb = colorbar;
        cb.Location = 'eastoutside';
    end
    title("Spatially averaged Spectra");axis square;
    set(gca, 'Color', 'w'); 
    set(findall(gcf, 'Type', 'text'), 'Color', 'k');
    % Make axis tick labels and axes lines black
    set(gca, 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k');
    for plot_index=1:length(plot_info.file_types)
        ofname=sprintf('%s',outprefix);
        fprintf(1,'Saving %s.%s.\n', ofname, plot_info.file_types{plot_index});
        saveas(gcf, ofname, plot_info.file_types{plot_index})
    end
else
    figure('Visible','off','Color','w')
    plot(spectfile.axes(1).sample,roi_avg_spect,'Color',plot_info.cmap,'LineWidth',plot_info.linewidth)
    xlabel(strcat(spectfile.axes(1).name,'(',spectfile.axes(1).unit,')'))
    set(gca,'XScale',plot_info.scale.x,"YScale",plot_info.scale.y)
    xlim(plot_info.lim.x);
    %     ylim(plot_info.lim.y)
    title("Spatially averaged Spectra");axis square;
    title("Spatially averaged Spectra");axis square;
    set(gca, 'Color', 'w'); 
    set(findall(gcf, 'Type', 'text'), 'Color', 'k');
    % Make axis tick labels and axes lines black
    set(gca, 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k');
    for plot_index=1:length(plot_info.file_types)
        ofname=sprintf('%s',outprefix);
        fprintf(1,'Saving %s.%s.\n', ofname, plot_info.file_types{plot_index});
        saveas(gcf, ofname, plot_info.file_types{plot_index})
    end
end
