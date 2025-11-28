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

function [data,im_mask,axes,K] = generate_phantom(acq,D_dic,T2_dic,D_spacing,T2_spacing,multislice)
% Generates a phantom data_noisy
% Input: wei_roi: 'row x col x Nc' of weighted roi's consisting 'Nc' components
%        TE: TE values in ms
%        b: b values in ms/um^2
%        SNR: SNR of the resultant data calculated using the method defined
% Output: F:Original spectral peak locations
%         data: 2D decay data for each of the 'Nc' components
%         data_noisy: noisy phantom data of dimension length(b) x length(TE) x row x col
load('data/Weighted_com_roi_5slice_rewei_final.mat','wei_roi');
if ~multislice
    wei_roi=squeeze(wei_roi(:,:,3,:));
    im_mask=~(~sum(wei_roi,3));

else

    for i=1:size(wei_roi,3)
        im_mask(:,:,i)=~(~sum(squeeze(wei_roi(:,:,i,:)),3));
    end

end
C_T2=[60 70 20];
C_D=[1 .1 0.5];
std_T2=[10 15 10];
std_D=[0.01 0.0003 .005];
N1 = 100; N2 = 100;
D = logspace(log10(0.01), log10(5), N1);
T2 = logspace(log10(3), log10(300), N2);
[y, x] = meshgrid(T2,D);
for i=1:size(wei_roi,ndims(wei_roi))
    Fs(:,:,i) = exp((-(y- C_T2(i)).^2)/std_T2(i) +(-(x-C_D(i)).^2)/std_D(i));
end
[y_dic, x_dic] = meshgrid(T2_dic,D_dic);
spect_sample=[x_dic(:) y_dic(:)];
K=zeros(size(acq,1),size(spect_sample,1));
for i=1:size(acq,1)
    K(i,:)=exp(-acq(i,1)*spect_sample(:,1)).*exp(-acq(i,2)./spect_sample(:,2));
end
K=squeeze(reshape(K,[],length(D_dic),length(T2_dic)));

data_tmp=zeros(size(acq,1),size(wei_roi,ndims(wei_roi)));
for comp=1:size(wei_roi,ndims(wei_roi))
    for i=1:length(D)
        for j=1:length(T2)
            for m=1:size(acq,1)
                data_tmp(m,comp)=data_tmp(m,comp)+Fs(i,j,comp)*exp(-acq(m,1)*D(i))*exp(-acq(m,2)/T2(j));
            end
        end
    end
end
if ~multislice
    data=reshape(data_tmp*reshape(wei_roi,[],size(wei_roi,3))',size(acq,1),size(wei_roi,1),size(wei_roi,2));
else
    for i=1:size(wei_roi,3)
        wei_roi2=squeeze(wei_roi(:,:,i,:));
        data(:,:,:,i)=reshape(data_tmp*reshape(wei_roi2,[],size(wei_roi2,3))',size(acq,1),size(wei_roi2,1),size(wei_roi2,2));
    end
end
if strcmp(D_spacing,'none')
    axes.sample=T2_dic;
    axes.name='T_2';
    axes.unit='ms';
    axes.spacing=T2_spacing;
elseif strcmp(T2_spacing,'none')
    axes.sample=D_dic;
    axes.name='D';
    axes.unit='um2/ms';
    axes.spacing=D_spacing;
else
    axes(1).sample=D_dic;
    axes(1).name='D';
    axes(1).unit='um2/ms';
    axes(1).spacing=D_spacing;
    axes(2).sample=T2_dic;
    axes(2).name='T_2';
    axes(2).unit='ms';
    axes(2).spacing=T2_spacing;
end
return
