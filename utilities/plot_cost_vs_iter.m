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

function plot_cost_vs_iter(out,params,outprefix)
out_sum=0;
min_len=Inf;
for i=1:length(out)
    min_len=min(min_len,length(out(i).cost1));
end
for i=1:length(out)
    out_sum=out_sum+out(i).cost1(1:min_len)+out(i).cost2(1:min_len);
end
fig = figure('Color','w','Units','pixels','Position',[200 200 400 800],'Visible', 'off');
ax = axes('Parent',fig);
semilogy(ax,0:length(out_sum)-1,out_sum);
xlabel(strcat("iteration number x",num2str(params.solver.save_inter),""));
ylim([0.85*min(out_sum(:)) 1.15*max(out_sum(:))])
xlim([0 length(out_sum)-1])
ylabel('cost function');
title('Averaged Cost Function vs iter no.')
set(ax, 'Color', 'w');
set(findall(fig, 'Type', 'text'), 'Color', 'k');

% Make axis tick labels and axes lines black
set(gca, 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k');
if endsWith(outprefix, '.mat', 'IgnoreCase', true)
    fname_no_ext = extractBefore(outprefix, '.mat');
else
    fname_no_ext = outprefix;
end
axis square
ofname=sprintf('%s_costVsiter_single_beta',fname_no_ext);
fprintf(1,'Saving %s.png\n', ofname);
saveas(fig,ofname,'png')
