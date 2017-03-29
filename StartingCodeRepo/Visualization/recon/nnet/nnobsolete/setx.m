function net=setx(net,x)
%SETX Set all network weight and bias values with a single vector.
%
% Obsoleted in R2010b NNET 7.0.  Last used in R2010a NNET 6.0.4.
%
%  Syntax
%
%    net = setx(net,X)
%
%  Description
%
%    This function sets a networks weight and biases to
%    a vector of values.
%
%    NET = SETX(NET,X)
%      NET - Neural network.
%      X   - Vector of weight and bias values.
%
%  Examples
%
%    Here we create a network with a 2-element input, and one
%    layer of 3 neurons.
%
%      net = newff([0 1; -1 1],[3]);
%
%    The network has six weights (3 neurons * 2 input elements)
%    and three biases (3 neurons) for a total of 9 weight and bias
%    values.  We can set them to random values as follows:
%
%      net = setx(net,rand(9,1));
%
%    We can then view the weight and bias values as follows:
%
%      net.iw{1,1}
%      net.b{1}
%
%  See also GETX.

% Mark Beale, 11-31-97
% Mark Beale, Updated help, 5-25-98
% Copyright 1992-2012 The MathWorks, Inc.
% $Revision: 1.1.8.2 $ $Date: 2012/03/27 18:23:00 $

hints = nn7.netHints(net);

% Shortcuts
inputLearn = hints.iwInclude;
layerLearn = hints.lwInclude;
biasLearn = hints.bInclude;
inputWeightInd = hints.inputWeightInd;
layerWeightInd = hints.layerWeightInd;
biasInd = hints.biasInd;

for i=1:net.numLayers
  for j=find(inputLearn(i,:))
    net.IW{i,j}(:) = x(inputWeightInd{i,j});
  end
  for j=find(layerLearn(i,:))
    net.LW{i,j}(:) = x(layerWeightInd{i,j});
  end
  if biasLearn(i)
    net.b{i}(:) = x(biasInd{i});
  end
end
