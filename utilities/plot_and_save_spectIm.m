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

function plot_and_save_spectIm(spectfile,img,enc_idx,spatROImask, outprefix, plot_info)
map=plot_info.cmap;
sz=spectfile.spectral_dim;
data=img.data;
if length(spectfile.spatial_dim)<3
    slice_no=1;
else, slice_no=spectfile.spatial_dim(3);
end
if length(sz)==2 %for 2D spectra
    spectIm=spectfile.spectral_image;
    dim1_points=intersect(find(spectfile.axes(1).sample>=plot_info.lim.y(1)),find(spectfile.axes(1).sample<=plot_info.lim.y(2)));
    dim2_points=intersect(find(spectfile.axes(2).sample>=plot_info.lim.x(1)),find(spectfile.axes(2).sample<=plot_info.lim.x(2)));
    sz_new=[length(dim1_points) length(dim2_points)];
    for sl=1:slice_no
        Z=squeeze(spectIm(dim1_points,dim2_points,:,:,sl));
        if plot_info.normalise
            min_Z=min(Z(:));
            max_Z=max(Z(:));
        end
        bgGray=squeeze(mat2gray(data(enc_idx,:,:,sl)));
        [ix,iy]=ind2sub([spectfile.spatial_dim(1),spectfile.spatial_dim(2)],find(spatROImask(:,:,sl)));
        Ms=min(ix);Mf=max(ix);
        Ns=min(iy);Nf=max(iy);
        ff2=[];
        for m = Ms:Mf
            ff=[];
            for n = Ns:Nf
                if spatROImask(m,n,sl)==1 && any(any(Z(:,:,m,n)))
                    bg = bgGray(m,n);
                    Z2=flipud(squeeze(Z(:,:,m,n)));
                    if plot_info.normalise
                        z2=ind2rgb(gray2ind(mat2gray(Z2,[min_Z max_Z]),size(map,1)),map);
                    else
                        z2=ind2rgb(gray2ind(mat2gray(Z2),size(map,1)),map);
                    end
                    threshold=(plot_info.threshold*max(Z2(:)));
                    z2_zr_id=find(Z2<=threshold);
                    for i=1:length(z2_zr_id)
                        [i1,i2]=ind2sub(sz_new,z2_zr_id(i));
                        z2(i1,i2,:)=bg;
                    end
                    z2=imresize(z2,[max(size(z2)) max(size(z2))]);
                    ff=cat(2,ff,z2);
                else
                    z2=repmat(zeros(sz_new),[1 1 3]);
                    z2=imresize(z2,[max(size(z2)) max(size(z2))]);
                    ff=cat(2,ff,z2);
                end
            end
            ff2=cat(1,ff2,ff);
        end
        newSize = [round(size(ff2,1)*(spectfile.resolution(2)/spectfile.resolution(1))), size(ff2,2)];
        ff2 = imresize(ff2, newSize);
        for plot_index = 1:numel(plot_info.file_types)
            ext = lower(plot_info.file_types{plot_index});
            filename = sprintf('%s_%d.%s', outprefix, sl, ext);

            switch ext
                case {'png','jpg','jpeg','tif','tiff','bmp'}
                    imwrite(ff2, filename);
                case {'pdf','eps','svg','fig'}
                    f = figure('Visible','off','Units','pixels', ...
                        'Position',[100 100 size(ff2,2) size(ff2,1)]);
                    ax = axes('Parent',f);
                    imshow(ff2, 'Parent', ax, 'Border','tight');
                    axis(ax, 'off');
                    set(ax, 'LooseInset', [0 0 0 0]);  

                    switch ext
                        case 'pdf'
                            exportgraphics(f, filename, 'ContentType','vector', ...
                                'BackgroundColor','white'); 

                        case 'eps'
                            print(f, filename, '-depsc', '-vector', '-r300');   

                        case 'svg'
                            print(f, filename, '-dsvg', '-vector', '-r300');   
                        case 'fig'  
                            savefig(f, filename); 
                    end
                    close(f);

                otherwise
                    warning('Unsupported file type: %s', ext);
            end
        end
    end
elseif isscalar(sz) %for 1D spectra
    X=spectfile.axes(1).sample;
    spectIm=spectfile.spectral_image;
    for sl=1:slice_no
        Z=squeeze(spectIm(:,:,:,sl));
        if plot_info.normalise
            max_val=max(Z(:));
        end
        bgGray=squeeze(mat2gray(data(enc_idx,:,:,sl)));
        [ix,iy]=ind2sub([spectfile.spatial_dim(1),spectfile.spatial_dim(2)],find(spatROImask(:,:,sl)));
        Ms=min(ix);Mf=max(ix);
        Ns=min(iy);Nf=max(iy);
        nrows = Mf-Ms+1; ncols = Nf-Ns+1;
        max_pix=1000;
        if nrows*spectfile.resolution(2)>ncols*spectfile.resolution(1)
            tile_h=round(max_pix/nrows);
            tile_w=round((max_pix/nrows)*spectfile.resolution(1)/spectfile.resolution(2));
        else
            tile_w=round(max_pix/ncols);
            tile_h=round((max_pix/ncols)*spectfile.resolution(2)/spectfile.resolution(1));
        end

        f = figure('Units','pixels',...
            'Position',[100 100 ncols*tile_w nrows*tile_h],'Color','w','Visible','off');

        t = tiledlayout(f, nrows, ncols, 'TileSpacing','none','Padding','none');
        for m = Ms:Mf
            for n = Ns:Nf
                ax = nexttile(t); hold(ax,'on');
                set(ax,'LooseInset',[0 0 0 0]);
                ax.Color = repmat(bgGray(m,n),1,3);
                if spatROImask(m,n,sl)==1 && any(Z(:,m,n))
                    Z2 = squeeze(Z(:,m,n));
                    plot(ax, X(:), Z2, plot_info.cmap,'LineWidth',plot_info.linewidth);
                    if plot_info.normalise
                        ylim(ax,[-0.05*max_val 1.05*max_val])
                    end
                    xlim(ax,plot_info.lim.x)
                    set(ax,'XScale',plot_info.scale.x,'YScale',plot_info.scale.y);
                end

                set(ax,'XTick',[],'YTick',[]);
                ax.YColor = 'none';
                ax.XColor = 'none';
                box(ax,'off');
            end
        end
        for k = 1:numel(plot_info.file_types)
            filename = sprintf('%s_%d.%s', outprefix, sl, plot_info.file_types{k});
            exportgraphics(f, filename, 'Resolution', 300, 'BackgroundColor','current');
        end
    end
end