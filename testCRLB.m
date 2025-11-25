addpath("data","solvers","utilities","ini2struct")

% successful run
estimate_crlb('funcfile','data/func_expression_diffT2_1.txt','outprefix','Result/CRLB_values')

% unsuccessful run because function expression does not contain a
% particular variable