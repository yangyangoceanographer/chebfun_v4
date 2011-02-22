function Fout = erfc(F)
% ERFC   Complementary error function of a chebfun.
%
% See http://www.maths.ox.ac.uk/chebfun for chebfun information.

% Copyright 2002-2009 by The Chebfun Team. 

Fout = comp(F, @(x) erfc(x));
for k = 1:numel(F)
  Fout(k).jacobian = anon('diag1 = diag(-2*exp(-F.^2)/sqrt(pi)); der2 = diff(F,u,''linop''); der = diag1*der2; nonConst = ~der2.iszero;',{'F'},{F(k)},1);
  Fout(k).ID = newIDnum();
end