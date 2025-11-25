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
function [spectIm,out_slice]=run_solver(img,im_mask,spectInfo,params)
data=double(img.data);
K=reshape(spectInfo.K,size(spectInfo.K,1),[]);

if strcmpi(params.solver.name,'ADMM')
    lambda=params.lambda;
    numIter=params.solver.num_iter;
    beta=params.solver.beta;
    [num_tps,row,col,slice_no] = size(data);
    if params.dc_comp==1
        K=[K,ones(size(K,1),1)];
    end
    Q = size(K,2);
    if params.dc_comp==1
        spectIm=zeros(Q-1,size(data,2),size(data,3),size(data,4));
    else
        spectIm=zeros(Q,size(data,2),size(data,3),size(data,4));
    end
    for sl=1:slice_no
        solverTimer=tic;
        if isfield(params,'spect_est')
            disp(strcat("Solving for slice no:",num2str(sl)));
        end
        m_slice = reshape(squeeze(data(:,:,:,sl)),num_tps,row*col);
        mask_sl=squeeze(im_mask(:,:,sl));
        [N1,N2] = size(mask_sl);
        mInd = find(mask_sl(:));
        m_slice = m_slice(:,mInd);
        e = ones(N1,1);
        T = spdiags([e,-e],[0,1],N1-1,N1);
        E = speye(N2);
        D1 = kron(E,T);
        D2=[];
        if N2>1 % if the image is 2D
            e = ones(N2,1);
            T = spdiags([e,-e],[0,1],N2-1,N2);
            E = speye(N1);
            D2 = kron(T,E);
            D = [D1;D2];%finite difference operator
        end
        clear e T E D1 D2
        D = D(:,mInd); % remove columns that are outside of the mask
        i = find(not(sum(D,2)));
        D = D(i,:); % remove rows for finite differences that cross the mask boundary
        clear i;
        Nn = numel(mInd);
        Dinv = inv(lambda*(D'*D) + beta*eye(Nn))';
        %% initialising ADMM variables
        f = zeros(Q,Nn);
        x = zeros(Q,Nn);
        y = zeros(Q,Nn);
        z = zeros(Q,Nn);
        dx = zeros(Q,Nn);
        dy = zeros(Q,Nn);
        dz = zeros(Q,Nn);
        %% ADMM
        M = inv(K'*K + beta*eye(Q));
        g = K'*m_slice;
        cnt = 1;
        cnt2 = 1;
        if (params.beta_calc) % will calculate the cost function when beya_calc field is present in the params
            f_curr = f;
            f_curr(f_curr<0) = 0;
            out_ADMM.cost1(cnt) = 0.5*norm(K*f_curr-m_slice,'fro')^2;
            out_ADMM.cost2(cnt) = lambda*0.5*norm(f_curr*D','fro')^2;
            out_ADMM.iterTime(cnt) = toc(solverTimer);
            cnt = cnt+1;
        end
        if isfield(params,'spect_est')
            f_old = f;
            f_old(f_old<0) = 0;
        end
        for i = 1:numIter
            f = (beta*x + dx + beta*y + dy+ beta*z+ dz)/(3*beta);
            x = M*(g + beta*f - dx);
            y = f - dy/beta;
            y(y<0) = 0;
            z = (beta*f - dz)*Dinv;
            dx = dx - beta*(f-x);
            dy = dy - beta*(f-y);
            dz = dz - beta*(f-z);
            if params.beta_calc
                if mod(i,params.solver.save_inter)==0
                    f_curr = f;
                    f_curr(f_curr<0) = 0;
                    out_ADMM.cost1(cnt) = 0.5*norm(K*f_curr-m_slice,'fro')^2;
                    out_ADMM.cost2(cnt) = lambda*0.5*norm(f_curr*D','fro')^2;
                    out_ADMM.iterTime(cnt) = toc(solverTimer);
                    cnt = cnt+1;
                end
            end
            if isfield(params,'spect_est')
                if mod(i,params.solver.save_inter)==0
                    f_curr = f;
                    f_curr(f_curr<0) = 0;
                    succ_norm_dist(cnt2)=norm(f_curr-f_old)/(eps+min(norm(f_curr),norm(f_old)));
                    disp(strcat("Time taken for ",num2str(i)," iter:",num2str(toc(solverTimer)),"s," + ...
                        " normalised successive error:",num2str(succ_norm_dist(cnt2)),""))
                    if i>params.solver.check_tol
                        if succ_norm_dist(cnt2)<params.solver.tol
                            disp(strcat("Normalised successive error reached required tolerance of ",num2str(params.solver.tol)," " + ...
                                " after ",num2str(i)," iteration"))
                            break;
                        end
                    end
                    f_old = f_curr;
                    cnt2 = cnt2+1;
                end
            end

        end
        if params.dc_comp==1
            f(f<0)=0;
            f_ADMM=zeros(Q-1,row*col);
            f_ADMM(:,mInd)=f(1:end-1,:);
        else
            f(f<0)=0;
            f_ADMM=zeros(Q,row*col);
            f_ADMM(:,mInd)=f;
        end
        f_ADMM=reshape(f_ADMM,[],row,col);
        spectIm(:,:,:,sl)=f_ADMM;
        if params.beta_calc 
            out_slice(sl)=out_ADMM;
        end
    end
elseif strcmpi(params.solver.name,'LADMM')
    lambda=params.lambda;
    numIter=params.solver.num_iter;
    beta=params.solver.beta;
    rnk=params.low_rank.rank;
    [num_tps,row,col,slice_no] = size(data);
    if params.dc_comp==1
        K=[K,ones(size(K,1),1)];
    end
    Q = size(K,2);
    if params.dc_comp==1
        spectIm=zeros(Q-1,size(data,2),size(data,3),size(data,4));
    else
        spectIm=zeros(Q,size(data,2),size(data,3),size(data,4));
    end
    for sl=1:slice_no
        solverTimer=tic;
        if isfield(params,'spect_est')
            disp(strcat("Solving for slice no:",num2str(sl)));
        end
        m_slice = reshape(squeeze(data(:,:,:,sl)),num_tps,row*col);
        mask_sl=squeeze(im_mask(:,:,sl));
        [N1,N2] = size(mask_sl);
        mInd = find(mask_sl(:));
        m_slice = m_slice(:,mInd);
        e = ones(N1,1);
        T = spdiags([e,-e],[0,1],N1-1,N1);
        E = speye(N2);
        D1 = kron(E,T);
        e = ones(N2,1);
        T = spdiags([e,-e],[0,1],N2-1,N2);
        E = speye(N1);
        D2 = kron(T,E);
        D = [D1;D2];
        clear e T E D1 D2
        D = D(:,mInd); % remove columns that are outside of the mask
        ii = find(not(sum(D,2)));
        D = D(ii,:); % remove rows for finite differences that cross the mask boundary
        clear ii;
        Nn = numel(mInd);
        epsilon = 1e-10;
        xip = 0.75*lambda*norm(full(D'*D)) + epsilon;
        f = zeros(Q,Nn);
        z = zeros(Q,Nn);
        d = zeros(Q,Nn);
        if params.low_rank.flag
            [U,S,V] = svd(K,'econ');
            S = S(1:rnk,1:rnk);
            V = V(:,1:rnk);
            U = U(:,1:rnk);
            s = diag(S);
            VS = V*spdiags(s.^2./(beta^2+beta*s.^2),0,rnk,rnk);
            K1 = U*S*V';
        else
            M = inv(K'*K+ beta*eye(Q));
            K1=K;
        end
        g =  K1'*m_slice;
        D_primeD = D'*D;
        cnt = 1;
        cnt2 = 1;
        if params.beta_calc
            f_curr = f;
            f_curr(f_curr<0) = 0;
            out_LADMM.cost1(cnt) = 0.5*norm(K*f_curr-m_slice,'fro')^2;
            out_LADMM.cost2(cnt) = lambda*0.5*norm(f_curr*D','fro')^2;
            out_LADMM.iterTime(cnt) = toc(solverTimer);
            cnt = cnt+1;
        end
        if isfield(params,'spect_est')
            f_old = f;
            f_old(f_old<0) = 0;
        end
        for i = 1:numIter
            if params.low_rank.flag
                f = (g+ beta*z- d);
                f = (f/beta - VS*(V'*f));
            else
                f = M*(g+ beta*z- d);
            end
            z = (xip*z - lambda*(z*D_primeD) + beta*f + d)/(xip+beta);
            z(z<0) = 0;
            d = d - beta*(z-f);
            if params.beta_calc
                if mod(i,params.solver.save_inter)==0
                    f_curr = f;
                    f_curr(f_curr<0) = 0;
                    out_LADMM.cost1(cnt) = 0.5*norm(K*f_curr-m_slice,'fro')^2;
                    out_LADMM.cost2(cnt) = lambda*0.5*norm(f_curr*D','fro')^2;
                    out_LADMM.iterTime(cnt) = toc(solverTimer);
                    cnt = cnt+1;
                end
            end
            if isfield(params,'spect_est')
                if mod(i,params.solver.save_inter)==0
                    f_curr = f;
                    f_curr(f_curr<0) = 0;
                    succ_norm_dist(cnt2)=norm(f_curr-f_old)/(eps+min(norm(f_curr),norm(f_old)));
                    disp(strcat("Time taken for ",num2str(i)," iter:",num2str(toc(solverTimer)),"s," + ...
                        " normalised successive error:",num2str(succ_norm_dist(cnt2)),""))
                    if i>params.solver.check_tol
                        if succ_norm_dist(cnt2)<params.solver.tol
                            disp(strcat("Normalised successive error reached required tolerance of ",num2str(params.solver.tol)," " + ...
                                " after ",num2str(i)," iteration"))
                            break;
                        end
                    end
                    f_old = f_curr;
                    cnt2 = cnt2+1;
                end
            end
        end
        if params.dc_comp==1
            f(f<0)=0;
            f_LADMM=zeros(Q-1,row*col);
            f_LADMM(:,mInd)=f(1:end-1,:);
        else
            f(f<0)=0;
            f_LADMM=zeros(Q,row*col);
            f_LADMM(:,mInd)=f;
        end
        f_LADMM=reshape(f_LADMM,[],row,col);
        spectIm(:,:,:,sl)=f_LADMM;
        if params.beta_calc
            out_slice(sl)=out_LADMM;
        end
    end

elseif strcmpi(params.solver.name,'NNLS')
    Q = size(K,2);
    spectIm=zeros(Q,size(data,2),size(data,3),size(data,4));
    for sl=1:size(data,4)
        if isfield(params,'spect_est')
            disp(strcat("Solving for slice no:",num2str(sl)));
        end
        for row=1:size(data,2)
            for col=1:size(data,3)
                mid=im_mask(row,col,sl);
                if mid==1
                    spectIm(:,row,col,sl) = lsqnonneg(K,squeeze(data(:,row,col,sl)));
                end
            end
        end
    end
    spectIm(spectIm<0)=0;
end
spectIm=reshape(spectIm,[spectInfo.spectral_dim(:).' img.spatial_dim(:).']);

