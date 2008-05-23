function display(A)
% DISPLAY Pretty-print a chebop.
% DISPLAY is called automatically when a statement that results in a chebop
% output is not terminated with a semicolon.

% Copyright 2008 by Toby Driscoll.
% See www.comlab.ox.ac.uk/chebfun.

loose = ~isequal(get(0,'FormatSpacing'),'compact');
if loose, disp(' '), end
disp([inputname(1) ' = chebop']);
if loose, disp(' '), end
s = char(A);
if ~loose   
  s( all(isspace(s),2), : ) = [];  % remove blank lines
end
disp(s)

end

