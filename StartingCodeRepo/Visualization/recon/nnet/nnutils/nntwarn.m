function flag = nntwarn(cmd)
%NNTWARN
%
%  Syntax
%
%    nntwarn on
%    nntwarn off
%
%  Description
%
%    NNTWARN allows Neural Network Toolbox warnings to be temporarily
%    turned off.
%
%    Code using obsolete Neural Network Toolbox functionality can
%    generate a lot of warnings.  This function allows you to skip
%    those warnings.  However, we encourage you to update your code
%    to ensure that it will run under future versions of the toolbox.

% Mark Beale, 11-31-97
% Copyright 1992-2010 The MathWorks, Inc.
% $Revision: 1.8.4.6 $

if nargin < 1, error(message('nnet:Args:NotEnough')),end

persistent NNTWARNFLAG;

switch(lower(cmd))
  case 'on'
    NNTWARNFLAG = [];
  case 'off'
    NNTWARNFLAG = 'off';
  case 'error'
    NNTWARNFLAG = 'error';
  case 'query'
    flag = NNTWARNFLAG;
  otherwise
    error(message('nnet:Args:Unrec'))
end

