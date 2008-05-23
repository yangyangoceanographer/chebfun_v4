function A = subsasgn(A,s,B)
% SUBSASGN  Change boundary conditions or other properties of a chebop.
% A.bc = BC assigns boundary conditions at both ends of the function domain
% as described by a mnemonic or chebop. See CHEBOP/AND for the syntax.
%
% A.lbc = BC or A.rbc = BC assigns a single boundary condition only at one 
% end of the domain, using the same syntax to describe the condition. To
% set more than one condition, use A.lbc(2), A.rbc(2), etc. 
%
% A.scale = S sets a vertical scale (e.g., norm) to which a function in 
% the domain of A should be compared. This can help MRDIVIDE (backslash)
% decide when adaptive refinement of a solution should be stopped, for
% example in Newton's method where corrections are small compared to the
% global solution.
%
% See also CHEBOP/AND, CHEBOP/MLDIVIDE.

% Copyright 2008 by Toby Driscoll.
% See www.comlab.ox.ac.uk/chebfun.

valid = false;
switch s(1).type
  case '.'
    name = s(1).subs;
    switch name
      case 'scale'                 % SCALE
        A.scale = B;
        valid = true;

      case {'lbc','rbc'}           % DIRECT BC ASSIGNMENT
        if isequal(name,'lbc')
          side = 'left';
        else
          side = 'right';
        end
        bc = getbc(A);
        if length(s)==1  % no index specified, so clear old ones
          bc.(side) = struct([]);
          idx = 1;
          valid = true;
        elseif isequal(s(2).type,'()') && length(s(2).subs)==1
          idx = s(2).subs{1};
          valid = true;
        end
        if valid 
          % B gives us (maybe) the operator and the RHS value
          if isempty(B)
            bc.(side)(idx).op = [];  
            bc.(side)(idx).val = [];
          elseif isnumeric(B)
            % Dirichlet case
            bc.(side)(idx).op = 'dirichlet';
            bc.(side)(idx).val = B;
          elseif ischar(B) || isa(B,'chebop') || isa(B,'varmat')
            bc.(side)(idx).op = B;
            bc.(side)(idx).val = 0;           
          elseif iscell(B) && isnumeric(B{2}) && ...
              (isa(B{1},'chebop') || isa(B{1},'varmat') || ischar(B{1}) )  
            % General operator
            bc.(side)(idx).op = B{1};
            bc.(side)(idx).val = B{2};
           else
            valid = false;
          end
          if valid, A = setbc(A,bc); end
        end

      case 'bc'                    % BC MNEMONICS OR STRUCT
        A = setbc(A,B);
        valid = true;
                          
    end
end

if ~valid
  error('chebop:subsasgn:invalid','Invalid assignment syntax.')
elseif ~isequal(s(1).subs,'scale')
  A.ID = newIDnum();   % stored matrices have become invalid
end
