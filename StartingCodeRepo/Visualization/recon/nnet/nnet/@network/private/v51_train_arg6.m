function [net,tr,Y,E,Pf,Af] = v51_train_arg6(net,P,T,Pi,Ai,VV)
%V5_TRAIN_ARG6 - Supports way of calling TRAIN made obsolete in NNT 5.1

% Copyright 2007-2012 The MathWorks, Inc.

[err,P,T,Pi,Ai,Q,TS,matrixForm] = trainargs(net,P,T,Pi,Ai);
if ~isempty(err), disp('??? Error with training vectors'), nnerr.throw(err), end
if isempty(VV)
  VV = [];
else
  if ~hasfield(VV,'P'), error(message('nnet:ObsErr:VVPUndefined')), end
  if ~hasfield(VV,'T'), VV.T = []; end
  if ~hasfield(VV,'Pi'), VV.Pi = []; end
  if ~hasfield(VV,'Ai'), VV.Ai = []; end
  [err,VV.P,VV.T,VV.Pi,VV.Ai,VV.Q,VV.TS] = trainargs(net,VV.P,VV.T,VV.Pi,VV.Ai);
  if ~isempty(err), disp('??? Error with validation vectors'), nnerr.throw(err), end
end
saveDivideFcn = net.divideFcn;
saveDivideParam = net.divideParam;
net.divideFcn = 'divideind';
net.divideParam.trainInd = 1:Q;
if isempty(VV)
  net.divideParam.valInd = [];
else
  net.divideParam.valInd = Q+(1:VV.Q);
  P = cellmat_mergecols(P,VV.P);
  T = cellmat_mergecols(T,VV.T);
  Pi = cellmat_mergecols(Pi,VV.Pi);
  Ai = cellmat_mergecols(Ai,VV.Ai);
end
net.divideParam.testInd = [];
if (matrixForm)
  P = cell2mat(P);
  T = cell2mat(T);
  Pi = cell2mat(Pi);
  Ai = cell2mat(Ai);
end
if net.numInputDelays == 0
  Pi = cell(net.numInputs,0);
end
if net.numLayerDelays == 0
  Ai = cell(net.numLayers,0);
end
[net,tr,Y,E,Pf,Af] = train(net,P,T,Pi,Ai);
net.divideFcn = saveDivideFcn;
net.divideParam = saveDivideParam;

%% ============================================================
function [err,P,T,Pi,Ai,Q,TS,matrixForm] = trainargs(net,P,T,Pi,Ai)

% Check signals: all matrices or all cell arrays
% Change empty matrices/arrays to proper form
switch class(P)
  case 'cell', matrixForm = 0; name = 'cell array'; default = {};
  case {'double','logical'}, matrixForm = 1; name = 'matrix'; default = [];
  otherwise, err = 'X must be a matrix or cell array.'; return
end

if isempty(T), T = default; end
if isempty(Pi), Pi = default; end
if isempty(Ai), Ai = default; end

if ((isnumeric(T) | islogical(T)) ~= matrixForm)
  err = ['X is a ' name ', so T must be a ' name ' too.']; return
end
if ((isnumeric(Pi)|islogical(Pi)) ~= matrixForm)
  err = ['X is a ' name ', so Xi must be a ' name ' too.']; return
end
if ((isnumeric(Ai)|islogical(Ai)) ~= matrixForm)
  err = ['X is a ' name ', so Ai must be a ' name ' too.']; return
end

% Check Matrices, Matrices -> Cell Arrays
if (matrixForm)
  Q = size(P,2);
  TS = 1;
  [err,P] = formatp(net,P,Q); if ~isempty(err), return, end
  [err,T] = formatt(net,T,Q,TS); if ~isempty(err), return, end
  [err,Pi] = formatpi(net,Pi,Q); if ~isempty(err), return, end
  [err,Ai] = formatai(net,Ai,Q); if ~isempty(err), return, end
  
% Check Cell Arrays
else
  TS = size(P,2);
  Q = size(P{1,1},2);
  [err] = checkp(net,P,Q,TS); if ~isempty(err), return, end
  [err,T] = checkt(net,T,Q,TS); if ~isempty(err), return, end
  [err,Pi] = checkpi(net,Pi,Q); if ~isempty(err), return, end
  [err,Ai] = checkai(net,Ai,Q); if ~isempty(err), return, end
end
err = '';


%% ============================================================
function c = cellmat_mergecols(c,varargin)

sources = length(varargin);
[rows,cols] = size(c);
for i=1:rows
  for j=1:cols
    for k=1:sources
      c{i,j} = [c{i,j} varargin{k}{i,j}];
    end
  end
end
