function g = feval(A,f)
% FEVAL   Apply oparray to a chebfun.

% Copyright 2008 by Toby Driscoll. See www.comlab.ox.ac.uk/chebfun.

% feval(A,f) requires that size(A,2)==size(f,2); i.e., f should be a
% quasimatrix whose columns are different variables.

if ~isa(f,'chebfun')
  error('oparray:feval:type','Oparrays can evaluate only on chebfuns.')
end

if numel(A.op)==1
  g = A.op{1}(f);
else
  if size(A,2)~=size(f,2)
    error('oparray:feval:size',...
      'Number of op columns must equal number of chebfun columns.')
  end
  % Emulate matrix * vector.
  g = [];
  for i = 1:size(A,1)
%    g(:,i) = chebfun(0,dom);
    h = 0;
    for j = 1:size(A,2)
      h = h + A.op{i,j}(f(:,j));
    end
    if isa(h,'chebfun')
      % Can't assign chebfun to previously undefined name.
      if i==1, g=h; else g(:,i) = h; end
    else
      g = [g;h];
    end
  end
end

end