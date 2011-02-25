function A = diag(f,d)
% DIAG   Pointwise multiplication operator.
% A = DIAG(F) produces a chebop that stands for pointwise multiplication by
% the chebfun F. The result of A*G is identical to F.*G.
%
% A = DIAG(F,D) is similar, but restricts the domain of F to D.
%
% See also domain/diag, chebop, linop/mtimes.

% Copyright 2011 by The University of Oxford and The Chebfun Developers. 
% See http://www.maths.ox.ac.uk/chebfun/ for Chebfun information.

if nargin < 2, d = domain(f); else f = restrict(f,d); end

A = diag(d, f); % Call domain/diag