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

function create_phantom(varargin)
%example
%create_phantom() or create_phantom('acqfile','data/acq_phantom.txt','spectfile','data/Phantom_spect.txt','outfolder','Phantom1')
p = inputParser;
p.CaseSensitive = true;     
p.PartialMatching = false; 
addParameter(p, 'acqfile', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'spectfile', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'outfolder', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'multislice', '', @(x)ischar(x) || isstring(x)|| isnumeric(x));
parse(p, varargin{:});
acqfile   = p.Results.acqfile;
spectfile = p.Results.spectfile;
multislice=p.Results.multislice;
outputfolder_name=p.Results.outfolder;
if ~isempty(acqfile) && ~isempty(spectfile)% when both the acqfile and spectfile is provided
    acq = readmatrix(acqfile);
    fid = fopen(spectfile,'r');
    txt = fread(fid,'*char')';
    fclose(fid);
    eval(txt);
    if (size(acq,2))~=2
        error('Please provide (b,TE) combination');
    else
        acq_diff=sum(diff(acq,1,1),1);
        if acq_diff(1,1)==0 && acq_diff(1,2)~=0
            flag=1; %1 if b values arent changing but TE values are changing
        elseif acq_diff(1,2)==0 && acq_diff(1,1)~=0
            flag=2; %2 if TE values arent changing but b values are changing
        elseif acq_diff(1,2)~=0 && acq_diff(1,1)~=0
            flag=3; %3 if both b and TE values are changing
        else
            error('Please provide MR data with multiple encoding') %if none of the values are changing-> can't generate phantom
        end
    end
    if flag==1 % if detects only TE changing, so will create dictionary with T2 values
        vars = who;                          % all variables in workspace
        varNames = {'T2_spacing','T2_min','T2_max','T2_num'};
        check = ~ismember(varNames, vars); % checking what variables are present in the txt file. If not
        % it will create the dictionary with default T2 values
        % setting default values
        not_present=varNames(check);
        if ~isempty(not_present)
            error("Please provide variables named %s in the acqfile",strjoin(not_present));
        end
        % if check(1)==0
        %     T2_spacing='log';
        % end
        % if check(2)==0
        %     T2_min=3;
        % end
        % if check(3)==0
        %     T2_max=1000;
        % end
        % if check(4)==0
        %     T2_num=300;
        % end
        if strcmpi(T2_spacing,'linear')
            T2_dic= linspace(T2_min, T2_max, T2_num);
        elseif strcmpi(T2_spacing, 'log')
            T2_dic= logspace(log10(T2_min), log10(T2_max), T2_num);
        else
            error("Unknown spacing type for T2: %s, please provide either 'log' or 'linear'", T2_spacing);
        end
        spectral_dim=T2_num;
        D_dic=0;
        D_spacing='none';
    end
    if flag==2
        vars = who;                          % all variables in workspace
        varNames = {'D_spacing','D_min','D_max','D_num'};
        check = ~ismember(varNames, vars);
        not_present=varNames(check);
        if ~isempty(not_present)
            error("Please provide variables named %s in the acqfile",strjoin(not_present));
        end
        % if check(1)==0
        %     D_spacing='log';
        % end
        % if check(2)==0
        %     D_min=0.01;
        % end
        % if check(3)==0
        %     D_max=10;
        % end
        % if check(4)==0
        %     D_num=300;
        % end
        if strcmpi(D_spacing,'linear')
            D_dic= linspace(D_min, D_max, D_num);
        elseif strcmpi(D_spacing, 'log')
            D_dic= logspace(log10(D_min), log10(D_max), D_num);
        else
            error("Unknown spacing type for D: %s, please provide either 'log' or 'linear'", D_spacing);
        end
        T2_dic=inf;
        T2_spacing='none';
        spectral_dim=D_num;
    end
    if flag==3
        vars = who;                          % all variables in workspace
        varNames = {'T2_spacing','T2_min','T2_max','T2_num','D_spacing','D_min','D_max','D_num'};
        check = ~ismember(varNames, vars);
        not_present=varNames(check);
        if ~isempty(not_present)
            error("Please provide variables named %s in the acqfile",strjoin(not_present));
        end
        % if check(1)==0
        %     T2_spacing='log';
        % end
        % if check(2)==0
        %     T2_min=3;
        % end
        % if check(3)==0
        %     T2_max=300;
        % end
        % if check(4)==0
        %     T2_num=70;
        % end
        % if check(5)==0
        %     D_spacing='log';
        % end
        % if check(6)==0
        %     D_min=0.01;
        % end
        % if check(7)==0
        %     D_max=5;
        % end
        % if check(8)==0
        %     D_num=70;
        % end
        if strcmpi(D_spacing,'linear')
            D_dic= linspace(D_min, D_max, D_num);
        elseif strcmpi(D_spacing, 'log')
            D_dic= logspace(log10(D_min), log10(D_max), D_num);
        else
            error("Unknown spacing type for D: %s, please provide either 'log' or 'linear'", D_spacing);
        end
        if strcmpi(T2_spacing,'linear')
            T2_dic= linspace(T2_min, T2_max, T2_num);
        elseif strcmpi(T2_spacing, 'log')
            T2_dic= logspace(log10(T2_min), log10(T2_max), T2_num);
        else
            error("Unknown spacing type for T2: %s, please provide either 'log' or 'linear'", T2_spacing);
        end
        spectral_dim=[D_num T2_num];
    end
elseif ~isempty(acqfile) && isempty(spectfile)% if acq file is present but not the spectfile
    acq = readmatrix(acqfile);
    if (size(acq,2))~=2
        error('Please provide (b,TE) combination');
    else
        acq_diff=sum(diff(acq,1,1),1);
        if acq_diff(1,1)==0 && acq_diff(1,2)~=0
            flag=1; %1 if b values arent changing but TE values are changing
        elseif acq_diff(1,2)==0 && acq_diff(1,1)~=0
            flag=2; %2 if TE values arent changing but b values are changing
        elseif acq_diff(1,2)~=0 && acq_diff(1,1)~=0
            flag=3; %3 if both b and TE values are changing
        else
            error('Please provide MR data with multiple encoding') %if none of the values are changing-> can't generate phantom
        end
    end
    if flag==1 % if detects only TE changing, so will create dictionary with T2 values
        T2_spacing='log';
        T2_num=300;
        T2_dic = logspace(log10(3), log10(1000), T2_num)';
        D_dic=0;
        D_spacing='none';
        spectral_dim=T2_num;
    end
    if flag==2
        D_spacing='log';
        D_num=300;
        D_dic = logspace(log10(0.01), log10(10), D_num)';
        T2_dic=inf;
        T2_spacing='none';
        spectral_dim=D_num;
    end
    if flag==3
        T2_spacing='log';
        T2_num=70;
        T2_dic = logspace(log10(3), log10(300), T2_num)';
        D_spacing='log';
        D_num=70;
        D_dic = logspace(log10(0.01), log10(5), D_num)';
        spectral_dim=[D_num T2_num];
    end


elseif isempty(acqfile) && ~isempty(spectfile)
    error('Please provide file containing acquisition parameters')
else
    T2_spacing='log';
    T2_num=70;
    T2_dic = logspace(log10(3), log10(300), T2_num)';
    D_spacing='log';
    D_num=70;
    D_dic = logspace(log10(0.01), log10(5), D_num)';
    TE = [99 120 160 200 250 300 400];
    b= [0 200 500 1000 1500 2500 5000]*1e-3;
    [b_grid,T2_grid]=meshgrid(b,TE);
    acq=[b_grid(:) T2_grid(:)];
    spectral_dim=[D_num T2_num];
end
if isempty(multislice)
    multislice=0;
else
    if ischar(multislice)|| isstring(multislice)
        multislice=str2double(multislice);
    end
end
if isempty(outputfolder_name)
    outputfolder_name='Phantom';
    if isfolder(outputfolder_name)
        disp('Directory exists! Overwriting the contents');
    else
        mkdir(outputfolder_name)
    end
else
    mkdir(outputfolder_name)
end
programTimer=tic;
[data,im_mask,axes,K] = generate_phantom(acq,D_dic,T2_dic,D_spacing,T2_spacing,multislice);
resolution=[.078 .078 1];
transform=eye(4);
if multislice
    spatial_dim=[size(data,2) size(data,3) size(data,4)];
else
    spatial_dim=[size(data,2) size(data,3)];
end
im_mask2=zeros(size(im_mask));
im_mask2(8:10,7:9,1)=1;
im_mask2(14:16,20:22,:)=1;
im_mask2(8:10,6:8,[2 5])=1;
im_mask2(7:9,6:8,3:4)=1;
% spectral_dim=[size(K,2) size(K,3)];
save(fullfile(outputfolder_name,'Phantom_data.mat'),"data","resolution","spatial_dim","transform",'-v7.3')
save(fullfile(outputfolder_name,'Phantom_spectrm_info.mat'),"K","axes","spectral_dim",'-v7.3')
save(fullfile(outputfolder_name,'Phantom_mask.mat'),'im_mask','-v7.3')
im_mask=im_mask2;
save(fullfile(outputfolder_name,'Phantom_mask_beta_calc.mat'),'im_mask','-v7.3')
fprintf(1,'Saved result to %s\n',outputfolder_name)
fprintf(1,'Total program time: %f seconds\n',toc(programTimer))
return