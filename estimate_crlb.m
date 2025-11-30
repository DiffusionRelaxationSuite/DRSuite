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

function estimate_crlb(varargin)

programTimer=tic;
p = inputParser;
p.CaseSensitive = true;     
p.PartialMatching = false; 
%required i/p
addParameter(p, 'funcfile', '', @(x)ischar(x) || isstring(x));
addParameter(p, 'outprefix', '', @(x)ischar(x) || isstring(x));
parse(p, varargin{:});
funcfile = p.Results.funcfile;
outprefix = p.Results.outprefix;
if isempty(funcfile) ||  ~isfile(funcfile)
    error('Please provide valid file with required function expressions...')
else
    fid = fopen(funcfile,'r');
    txt = fread(fid,'*char')';
    fclose(fid);
    eval(txt);
    varsToCheck = {'func','spect_params','acq_params','exp_vals','components'};
    m=[];
    for k = 1:numel(varsToCheck)
        if ~exist(varsToCheck{k},'var')
            m=[m k];
        end
    end
    varsNotpresent=varsToCheck(m);
    if ~isempty(varsNotpresent)
        error(strcat("These variables not present in the expression file: ",strjoin(varsNotpresent),". Exiting..."))
    end
end
if isempty(outprefix)
    error('Please provide file-name to store the CRLB results...')
end
if ~exist('noise_std', 'var')
    noise_std=1;
end
CRB_val=calc_CRLB(func,spect_params,acq_params,exp_vals,components,noise_std);
writematrix(CRB_val, strcat(outprefix,'.txt'), 'Delimiter', '\t')
fprintf(1,'Saved result to %s\n',outprefix)
fprintf(1,'Total program time: %f seconds\n',toc(programTimer))
return