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
function data=plot_and_save_comp_maps(spectfile, maskfile,outprefix, plot_info)

if ~isscalar(spectfile.spatial_dim) % checks if the image is 2D or 3D
    dim_spec=1;
    for i=1:length(spectfile.spectral_dim)
        dim_spec=dim_spec*spectfile.spectral_dim(i);
    end
    spec_mask=reshape(maskfile.spec_mask,[dim_spec,maskfile.num_comp]);
    L=maskfile.num_comp+1;
    if L==2 % dynamically creates subplots 
        row_no=1;col_no=1;
    elseif L<=5
        row_no=1;col_no=L;
    elseif L>5
        row_no=ceil(L/5);col_no=5;
    end
    im_resz = 8;
    num_colr = 128; scale_fact = reshape(linspace(0,1,num_colr),[],1);
    if length(spectfile.spatial_dim)<3
        slice_no=1;
    else, slice_no=spectfile.spatial_dim(3);
    end
    spectIm=reshape(spectfile.spectral_image,[dim_spec,spectfile.spatial_dim(:).']);
    for sl=1:slice_no
        fig_SpaMap = figure('color','w','Visible','off'); %fig_SpaMap.WindowState = 'maximized';
%         tiledlayout(row_no,col_no);
        t = tiledlayout(fig_SpaMap,row_no,col_no,'TileSpacing','compact','Padding','compact');
        tl =title(t,strcat("Component Maps for slice:",num2str(sl)));
        tl.Color = 'k'; 
        for Nc = 1:maskfile.num_comp
            mm = spec_mask(:,Nc);
            comp_spec_idx = find(mm);
            SpaMap=0;
            for i=1:length(comp_spec_idx)
                SpaMap=SpaMap+squeeze(spectIm(comp_spec_idx(i),:,:,sl));
            end
            max_val(Nc)=max(SpaMap(:));
        end
        for Nc = 1:size(spec_mask,2)
            mm = spec_mask(:,Nc);
            comp_spec_idx = find(mm);
            SpaMap=0;
            for i=1:length(comp_spec_idx)
                SpaMap=SpaMap+squeeze(spectIm(comp_spec_idx(i),:,:,sl));
            end
            data(Nc,:,:,sl)=SpaMap;
            SpaMap=SpaMap/max(max_val);%normalising all the voxel by the maximum voxel value among all the components
            ax=nexttile(t);
            axis image
            [im_ind,~] = gray2ind(mat2gray(imresize(SpaMap,im_resz,'nearest'),[0 1/plot_info.weights(Nc)]),num_colr);
            mycmap=plot_info.cmap(:,Nc)'.*scale_fact;
            SpaMap_colr(:,:,:,Nc) = ind2rgb(im_ind,mycmap);
            [m,n,~] = size(SpaMap_colr(:,:,:,Nc));
            x = (0:n-1)*spectfile.resolution(2);             % column coordinates
            y = (0:m-1)*spectfile.resolution(1);             % row coordinates
            imagesc(x, y,SpaMap_colr(:,:,:,Nc));
            axis equal tight   
            colormap(ax, mycmap);
            clim([0 1/plot_info.weights(Nc)])%plotting different components
            if plot_info.cbar
                cb = colorbar;
                cb.Location = 'southoutside';
            end
            set(ax, 'XTick', [], 'XTickLabel', []);
            set(ax, 'YTick', [], 'YTickLabel', []);
            xlabel("Comp "+num2str(Nc)+"");
        end
        if L>2
            weight_comp = ones(1,size(spec_mask,2));
            SpaMap_compo = zeros(size(SpaMap_colr,1),size(SpaMap_colr,2),3);% creating composite image
            for Nc=1:size(spec_mask,2)
                SpaMap_compo = SpaMap_compo + weight_comp(Nc)*SpaMap_colr(:,:,:,Nc);
            end
            ax=nexttile(t);
            imagesc(SpaMap_compo);axis image;colormap(ax, mycmap);
            axis image
            set(ax, 'XTick', [], 'XTickLabel', []);
            set(ax, 'YTick', [], 'YTickLabel', []);
            xlabel("Composite");
        end
        set(findall(gcf, 'Type', 'text'), 'Color', 'k');

    % Make axis tick labels and axes lines black
        set(gca, 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k');
        for plottype=1:length(plot_info.file_types)
            fprintf(1,'Saving %s_%d.%s\n',outprefix,sl,plot_info.file_types{plottype});
            saveas(gcf, sprintf('%s_%d',outprefix,sl),plot_info.file_types{plottype});
        end
    end
else
    sprintf('Please provide data with 2D or 3D spatial dimension\n');
end