function C = rdivide(A,B)
% ./  Elementwise right divison of varmats, with scalar expansion.

% Copyright 2008 by Toby Driscoll.
% See www.comlab.ox.ac.uk/chebfun.

C = op_scalar_expand(@rdivide,A,B);

end