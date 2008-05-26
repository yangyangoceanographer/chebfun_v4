function out = subsref(A,s)
% SUBSREF   Extract a member, or evaluate on a chebfun.

% Copyright 2008 by Toby Driscoll. See www.comlab.ox.ac.uk/chebfun.

% A(f) same as feval(A,f).
% A{i,j} returns A.op{i,j}.

switch s(1).type
  case '()'
    out = feval(A,s(1).subs{1});
  case '{}'
    out = subsref(A.op,s);   % this could be abused, e.g. A{:}
end

end