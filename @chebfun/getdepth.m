function d = getdepth(f)
% GETDEPTH Obtain the AD depth of a chebfun
% D = GETDEPTH(F) returns the depth of the anon stored in the chebfun F.

% Copyright 2011 by The University of Oxford and The Chebfun Developers. 
% See http://www.maths.ox.ac.uk/chebfun/ for Chebfun information.

d = getdepth(f.jacobian);
end