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

function CRB_val=calc_CRLB(func,spect_params,acq_params,exp_vals,components,noise_std)
%% code for CRLB calculation

exprSym  = str2sym(strtrim(func));
vars2 = strsplit(spect_params,',');
Spectvar = sym(vars2);
vars3 = strsplit(acq_params,',');
acq = sym(vars3);
SpectvarStr=string(Spectvar);
numComp=size(components,1);
for i=1:length(SpectvarStr)
    M{i}=sym(strcat(SpectvarStr(1,i),'_vec'),[1 numComp]);
end
for j=1:numComp
    M_in=[];
    for i=1:length(SpectvarStr)
        M_in=[M_in M{i}(j)];
    end
    exprSymTmp2(j,1)=subs(exprSym,Spectvar,M_in);

end
syms w [1 numComp]
model_expression=w*exprSymTmp2;
all_param_spec=w;
for i=1:length(SpectvarStr)
    all_param_spec=[all_param_spec, M{i}];
end
grad = gradient(model_expression, all_param_spec);
FisherMx=grad*(grad.');
fishermx_sum=0;
for i=1:size(exp_vals,1)
    fishermx_sub=FisherMx;
    for var=1:length(acq)
        var_name=acq(var);
        fishermx_sub=subs(fishermx_sub,var_name,exp_vals(i,var));
    end
    fishermx_sum=fishermx_sum+fishermx_sub;
end

fishermx_val=(1/noise_std^2)*double(subs(fishermx_sum,all_param_spec,components(:)'));
CRB_mx=inv(fishermx_val);
CRB_val=reshape(diag(CRB_mx),numComp,[]);
return
