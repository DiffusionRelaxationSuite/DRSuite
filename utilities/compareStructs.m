function report = compareStructs(A, B, varargin)
%COMPARESTRUCTS Deep diff of two MATLAB structs (or tables).
%   REPORT = compareStructs(A,B, 'RelTol',1e-9, 'AbsTol',0, ...
%                           'IgnoreNaN',true, 'IgnoreFieldOrder',true, ...
%                           'NumericMode','tolerant'|'exact')
%
% REPORT has fields:
%   equal           : logical
%   addedFields     : cellstr  (present only in B)
%   removedFields   : cellstr  (present only in A)
%   diffs           : struct array with fields:
%       path, type, detail, aSample, bSample
%
% Notes:
% - Tables/timetables are compared by converting to scalar structs.
% - Numerical comparison can be exact or tolerance-based.
% - Field order can be ignored.

opts = struct('RelTol',1e-9,'AbsTol',0,'IgnoreNaN',true, ...
              'IgnoreFieldOrder',true,'NumericMode','tolerant');
opts = parseOpts(opts, varargin{:});

% Normalize tables/timetables -> scalar struct
if istable(A), A = table2struct(A, "ToScalar", true); end
if istimetable(A), A = table2struct(timetable2table(A,'ConvertRowTimes',true), "ToScalar", true); end
if istable(B), B = table2struct(B, "ToScalar", true); end
if istimetable(B), B = table2struct(timetable2table(B,'ConvertRowTimes',true), "ToScalar", true); end

% Enforce field order neutrality if requested
if isstruct(A) && isstruct(B) && opts.IgnoreFieldOrder
    try
        A = orderfields(A); B = orderfields(B);
    catch
        % orderfields fails on non-scalar struct arrays with mismatched fields
    end
end

diffs = [];
[diffs, added, removed] = cmp(A, B, '', diffs, opts);

report.equal = isempty(diffs) && isempty(added) && isempty(removed);
report.addedFields   = added;
report.removedFields = removed;
report.diffs = diffs;

end

%-------------------- helpers --------------------%
function [diffs, added, removed] = cmp(a,b, path, diffs, opts)
added = {}; removed = {};

% Class/type check
if ~strcmp(class(a), class(b))
    diffs(end+1) = mk(path,'type-change',sprintf('class %s -> %s', class(a), class(b)), a, b); %#ok<AGROW>
    return;
end

% Structs
if isstruct(a)
    % First compare sizes of struct arrays
    if ~isequal(size(a), size(b))
        diffs(end+1) = mk(path,'size-change',sprintf('size %s -> %s', mat2str(size(a)), mat2str(size(b))),a,b); %#ok<AGROW>
        return;
    end

    % Collect field sets (across scalar or array)
    aFields = fieldnames(a);
    bFields = fieldnames(b);
    aOnly = setdiff(aFields, bFields);
    bOnly = setdiff(bFields, aFields);

    % Record added/removed at this node
    for i = 1:numel(aOnly)
        removed{end+1} = joinPath(path, aOnly{i}); %#ok<AGROW>
    end
    for i = 1:numel(bOnly)
        added{end+1} = joinPath(path, bOnly{i}); %#ok<AGROW>
    end

    common = intersect(aFields, bFields);
    % Iterate elements of struct array
    for idx = 1:numel(a)
        idxPath = path;
        if numel(a) > 1
            idxPath = sprintf('%s(%s)', path, idxStr(idx, size(a)));
        end
        for f = 1:numel(common)
            fpath = joinPath(idxPath, common{f});
            av = a(idx).(common{f});
            bv = b(idx).(common{f});
            [diffs, add2, rem2] = cmp(av, bv, fpath, diffs, opts);
            added = [added, add2]; %#ok<AGROW>
            removed = [removed, rem2]; %#ok<AGROW>
        end
    end
    return;
end

% Cells
if iscell(a)
    if ~isequal(size(a), size(b))
        diffs(end+1) = mk(path,'size-change',sprintf('size %s -> %s', mat2str(size(a)), mat2str(size(b))),a,b); %#ok<AGROW>
        return;
    end
    for i = 1:numel(a)
        elemPath = sprintf('%s{%s}', path, idxStr(i, size(a)));
        [diffs, add2, rem2] = cmp(a{i}, b{i}, elemPath, diffs, opts);
        added = [added, add2]; %#ok<AGROW>
        removed = [removed, rem2]; %#ok<AGROW>
    end
    return;
end

% Strings/char
if isstring(a) || ischar(a) || isdatetime(a) || isduration(a) || iscalendarduration(a) || iscategorical(a)
    if ~isequalwithequalnans(a,b) % equalwithequalnans covers NaN categories/datetimes
        diffs(end+1) = mk(path,'value-change','non-numeric mismatch', sample(a), sample(b)); %#ok<AGROW>
    end
    return;
end

% Numerics / logicals
if isnumeric(a) || islogical(a)
    if ~isequal(size(a), size(b))
        diffs(end+1) = mk(path,'size-change',sprintf('size %s -> %s', mat2str(size(a)), mat2str(size(b))),a,b); %#ok<AGROW>
        return;
    end
    if strcmpi(opts.NumericMode,'exact')
        eq = isequaln(a,b);
        if ~opts.IgnoreNaN, eq = isequal(a,b); end
        if ~eq
            diffs(end+1) = mk(path,'value-change','numeric mismatch (exact)', sample(a), sample(b)); %#ok<AGROW>
        end
    else
        % tolerant compare
        eqMask = tolerantEqual(a,b,opts.RelTol,opts.AbsTol,opts.IgnoreNaN);
        if ~all(eqMask(:))
            detail = sprintf('%.3g%% elements differ beyond tol (RelTol=%g, AbsTol=%g)', ...
                100*nnz(~eqMask)/numel(eqMask), opts.RelTol, opts.AbsTol);
            diffs(end+1) = mk(path,'value-change',detail, sample(a), sample(b)); %#ok<AGROW>
        end
    end
    return;
end

% Fallback for other classes
if ~isequal(a,b)
    diffs(end+1) = mk(path,'value-change','mismatch (unsupported class handler)', sample(a), sample(b)); %#ok<AGROW>
end

end

function tf = tolerantEqual(a,b,rt,at,ignoreNaN)
% elementwise tolerant equality
if ignoreNaN
    nanBoth = isnan(a) & isnan(b);
else
    nanBoth = false(size(a));
end
absa = abs(a); absb = abs(b);
tol = max(rt*max(absa, absb), at);
diff = abs(a - b);
tf = (diff <= tol) | nanBoth;
% handle Infs: exact match required
tf(isinf(a) | isinf(b)) = (a(isinf(a)|isinf(b)) == b(isinf(a)|isinf(b)));
end

function s = sample(x)
try
    if isscalar(x) || (isstring(x) && isscalar(x))
        s = x;
    elseif isnumeric(x) || islogical(x)
        s = x(1);
    elseif ischar(x)
        s = x(1:min(end,40));
    elseif iscell(x)
        s = x{1};
    else
        s = [];
    end
catch
    s = [];
end
end

function d = mk(path,type,detail,a,b)
d = struct('path',path,'type',type,'detail',detail,'aSample',a,'bSample',b);
end

function p = joinPath(base, field)
if isempty(base), p = ['.' field];
else,            p = [base '.' field];
end
end

function s = idxStr(i, sz)
% Convert linear index to subscript string like '2,3,1' for display
subs = cell(1,numel(sz));
[subs{:}] = ind2sub(sz, i);
s = strjoin(cellfun(@num2str, subs, 'UniformOutput', false), ',');
end

function opts = parseOpts(opts, varargin)
if mod(numel(varargin),2)~=0
    error('Options must be name/value pairs.');
end
for k = 1:2:numel(varargin)
    name = varargin{k}; val = varargin{k+1};
    if ~isfield(opts,name)
        error('Unknown option "%s".', name);
    end
    opts.(name) = val;
end
if ~any(strcmpi(opts.NumericMode, {'tolerant','exact'}))
    opts.NumericMode = 'tolerant';
end
end
