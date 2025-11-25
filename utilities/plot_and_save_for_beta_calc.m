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
function plot_and_save_for_beta_calc(img,spatROImask,spectInfo,params,outputPrefix_beta,figure_types)
plottypes=figure_types;
beta_all=params.solver.beta;
for j=1:length(beta_all)
    params.beta_calc=1;
    params.solver.beta=beta_all(j);
    fprintf(1,'Running %s solver for beta=%f...\n',params.solver.name,beta_all(j))
    [~,out]=run_solver(img,spatROImask,spectInfo,params);
    out_sum=0;
    for i=1:length(out)
        out_sum=out_sum+out(i).cost1+out(i).cost2;
    end
    out_all(:,j)=out_sum;
    legendEntries{j} = sprintf('beta=%.02d', beta_all(j));
end

% figure();
fig = figure('Color','w','Units','pixels','Position',[200 200 400 800],'Visible', 'off');
ax1 = subplot(2,1,1,'Parent',fig);
semilogy(ax1,0:size(out_all,1)-1,out_all);
xlabel(strcat("iteration number x",num2str(params.solver.save_inter),""));
ylim([0.85*min(out_all(:)) 1.15*max(out_all(:))])
xlim([0 size(out_all,1)-1])
ylabel('cost function');
leg=legend(legendEntries, 'Location', 'northeast', 'Box', 'off');
set(leg, 'TextColor', 'k');
set(gca,'YScale','log')
title('Averaged Cost Function vs iter no.')
axis square
set(ax1, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k');
set(findall(fig, 'Type', 'text'), 'Color', 'k');
ax2 = subplot(2,1,2,'Parent',fig);
semilogy(ax2,0:size(out_all,1)-1,out_all);
xlabel(strcat("iteration number x",num2str(params.solver.save_inter),""));
ylim([0.99*min(out_all(:)) 1.05*min(out_all(:))])
xlim([size(out_all,1)/2 size(out_all,1)-1])
% grid('on'); box('off');
ylabel('cost function');%legend(legendEntries, 'Location', 'northeast');
set(gca,'YScale','log')
title('Zoomed in plot')
axis square
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k');
set(findall(gcf, 'Type', 'text'), 'Color', 'k');

for plottype=1:length(plottypes)
    saveas(fig, sprintf('%s_costVSiter_multi_beta',outputPrefix_beta),plottypes{plottype});
end
return
