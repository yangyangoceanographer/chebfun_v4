function h = gt(f,g)
% GT (>) for chebfuns
%   H = F > G where F and/or G are chebfuns constructs a logical chebfun H
%   which is true (i.e. takes the value 1) where F > G, and false (0) elsewhere.
%
%   Quasimatrices are not yet supported.

if numel(f) > 1 || numel(g) > 1
    error('CHEBFUN:gt:quasi','gt is not yet implemented for quasimatrices.');
end

h = heaviside(f-g);
h.imps(h.imps == .5) = 0;
for k = 1:h.nfuns
    if h.funs(k).vals == .5, h.funs(k).vals = 0; end
end    
h = merge(h);
    

