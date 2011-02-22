function fout = mrdivide(f1,f2)
% /	  Scalar right divide.
% F/C divides the chebfun F by a scalar C.
%
% See http://www.maths.ox.ac.uk/chebfun for chebfun information.

% Copyright 2002-2009 by The Chebfun Team. 

if isa(f2,'double')
    fout = f1*(1/f2);
elseif isa(f1,'double')
    error('CHEBFUN:ldivide:nonscalar','Currently mrdivide only divides the chebfun by a scalar.')
else
    [q,r]=qr(f2,0);
    fout=r\(q'*f1);
end