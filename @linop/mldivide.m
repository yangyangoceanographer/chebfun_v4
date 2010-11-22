function C = mldivide(A,B,tolerance)
% \  Solve a linear operator equation.
% U = A\F solves the linear system A*U=F, where U and F are chebfuns and A
% is a chebop. If A is a differential operator of order M, a warning will
% be issued if A does not have M boundary conditions. In general the
% function may not converge in this situation.
%
% The algorithm is to realize and solve finite linear systems of increasing
% size until the chebfun constructor is satisfied with the convergence.
% This convergence is in a relative sense for U, which may not be
% appropriate in some situations (e.g., Newton's method finding a small
% correction). To set a different scale S for the relative accuracy, use 
% A.scale = S before solving.
%
% EXAMPLE
%   % Newton's method for (u')^2+6u=1, u(0)=0.
%   d = domain(0,1);  D = diff(d);
%   f = @(u) diff(u).^2 - 6*u - 1;
%   J = @(u) (diag(2*diff(u))*D - 6) & 'dirichlet';
%   u = chebfun('x',d);  du = Inf;
%   while norm(du) > 1e-12
%     r = f(u);  A = J(u);  A.scale = norm(u);
%     du = -(A\r);
%     u = u+du;
%   end
%
% See also linop/and, linop/mtimes.
% See http://www.maths.ox.ac.uk/chebfun.

% Copyright 2008 by Toby Driscoll.
%  Last commit: $Author$: $Rev$:
%  $Date$:

% For future performance, store LU factors of realized matrices.
persistent storage
if isempty(storage), storage = struct([]); end
use_store = cheboppref('storage');
maxdegree = cheboppref('maxdegree');

dorectmat = 1;
% dorectmat = 0;
% forceold = 1; % Force the use of the old way in solving systems with m = 1
forceold = 0; % i.e. same discretisation for each side.

switch(class(B))
  case 'linop'
    %TODO: Experimental, undocumented.
    dom = domaincheck(A,B);
    C = linop( A.varmat\B.varmat, [], dom, B.difforder-A.difforder );  

  case 'double'
    if length(B)==1  % scalar expansion
      C = mldivide(A,chebfun(B,domain(A),chebopdefaults));
    else
      error('LINOP:mldivide:operand','Use scalar or chebfun with backslash.')
    end

  case 'chebfun'
    dom = domaincheck(A,B(:,1));
    m = A.blocksize(2);
    if (m==1) && (A.numbc~=A.difforder)
      warning('LINOP:mldivide:bcnum',...
        'Operator may not have the correct number of boundary conditions.')
    end
    
    % Grab the default settings
    settings = chebopdefaults;
    if nargin == 3
        settings.eps = tolerance;
    end

    % Deal with maps
    % TOD) : test this.
    map = B(:,1).map;
    if ~isempty(map)
        if     strcmp(map.name,'linear'), map = [];
        else   settings.map = map; end
    end   
    % Take the union of all the ends
    ends = dom.endsandbreaks;
    for k = 1:numel(B)
        ends = union(B(:,k).ends,ends);
    end

    V = [];  % Initialise V so that the nested function overwrites it.
    
    % Call the constructor 
    if numel(ends) == 2 && ~chebfunpref('splitting')          % Smooth
        if isa(A.scale,'chebfun') || isa(A.scale,'function_handle')
          C = chebfun( @(x) A.scale(x)+value(x), ends, settings) - A.scale;
        else
          settings.scale = A.scale;
          C = chebfun( @(x) value(x), ends, settings);
        end
    else                          % Piecewise
        if isa(A.scale,'chebfun') || isa(A.scale,'function_handle')
            warning('CHEBFUN:linop:mldivide:sclfun', ...
                'No support for function scaling for piecewise domains.')
            if isa(A.scale,'function_handle'), A.scale = 1,
            else A.scale = norm(A.scale,inf); end
        end
        settings.scale = A.scale;
        C = chebfun( @(x,N,bks) valuesys(x,N,bks), {ends}, settings);
        if m == 1, C = C{:}; end
    end
    
    % If there aren't systems, then we're done.
    if m == 1, return, end
    
    % V has been overwritten by the nested value function.
    if numel(ends)==2 % Standard version
        for j = 1:m
            c = chebfun( V(:,j), dom, settings);
            C(:,j) = chebfun( @(x) c(x), dom, settings);
        end
    else              % Piecewise version
        l = 1;
        C = chebfun;
        settings.maxdegree = maxdegree;  settings.maxlength = maxdegree;
        for j = 1:m
            % For each variable, build a chebfun
            tmp = chebfun;            
            % Loop over each interval
            for k = 1:numel(ends)-1
                funk = fun( V{l}, ends(k:k+1), settings);
                tmp = [tmp ; set(chebfun,'funs',funk,'ends',ends(k:k+1),...
                    'imps',[funk.vals(1) funk.vals(end)],'trans',0)];
                l = l+1;
            end
            C(:,j) = simplify(tmp,settings.eps);
        end
    end
    
  otherwise
    error('LINOP:mldivide:operand','Unrecognized operand.')
end

  function v = value(x)
    N = length(x);
    if N > maxdegree+1
      error('LINOP:mldivide:NoConverge',['Failed to converge with %i points.',maxdegree+1])
      error('LINOP:mldivide:NoConverge','Failed to converge with %i points.',maxdegree+1)
    elseif N==1
      error('LINOP:mldivide:OnePoint',...
        'Solution requested at a lone point. Check for a bug in the linop definition.')
    elseif N <= A.numbc+1 || N < 2
      % Too few points: force refinement
      v = ones(N,1); 
      v(2:2:end) = -1;
      return
    end
    A.difforder = abs(A.difforder);
    x1 = [];
    
    if ~isempty(map), use_store = 0; end
    use_store = 0;
    
    % Retrieve or compute LU factors of the matrix.
    if use_store && N > 5 && length(storage)>=A.ID ...
        && length(storage(A.ID).L)>=N && ~isempty(storage(A.ID).L{N})
      L = storage(A.ID).L{N};
      U = storage(A.ID).U{N};
      x1 = storage(A.ID).x1{N};
      c = storage(A.ID).c{N};
      rowidx = storage(A.ID).rowidx{N};
    else  % have to compute L and U
      Amat = feval(A,N,map,ends);
      [Bmat,c,rowidx] = bdyreplace(A,N,map,ends);

      if dorectmat && m == 1% New rectangular matrix method
        if any(isinf(ends))
            % We don't want chebpts to do the scaling in this case. (Done below).
            x1 = chebpts(N-A.numbc,[-1 1],1);            
        else
            x1 = chebpts(N-A.numbc,ends,1);
        end
        if ~isempty(map) % Map the 1st-kind points. (x is already mapped).
            if isstruct(map)
                x1 = map.for(x1);
            else
                x1 = map(x1);
            end
        end
        Amat = [barymat(x1,x)*Amat; Bmat];
      else                   % Do things the old way
        Amat(rowidx,:) = Bmat;
      end
      
      [L,U] = lu(Amat);
      if use_store && N > 5   % store L and U
        % Very crude garbage collection! If over capacity, clear out
        % everything.
        ssize = whos('storage');
        if ssize.bytes > cheboppref('maxstorage')
          storage = struct([]);
        end
        storage(A.ID).L{N} = L;
        storage(A.ID).U{N} = U;
        storage(A.ID).x1{N} = x1;
        storage(A.ID).c{N} = c;
        storage(A.ID).rowidx{N} = rowidx;
      end        
    end
    
    % Evaluate and modify RHS as needed.
    if m == 1 && dorectmat
        f = B(x1,:);
        f = [f ; c]; 
    else
        f = B(x,:);
        f = f(:);
        f(rowidx) = c;
    end

    % Solve.
    v = U\(L\f);

    V = reshape(v,N,m);
    v = sum(V,2);
    v = filter(v,1e-8);

  end
  

 function v = valuesys(y,N,bks)
    % y is a cell array with the points for each function.
    % N is the number of points on each subinterval.
    % bks contains the ends of the subintervals.

    syssize = A.blocksize(1);     % # of eqns in system 
    N = N{:};   bks = bks{:};     % We allow only the same discretization
                                  % size and breaks for each system
    maxdo = max(A.difforder(:));  % the maximum derivative order of the system
                                    
    if sum(N) > maxdegree+1
      error('LINOP:mldivide:NoConverge',['Failed to converge with ',int2str(maxdegree+1),' points.'])
    elseif any(N==1)
      error('LINOP:mldivide:OnePoint',...
        'Solution requested at a lone point. Check for a bug in the linop definition.')
    elseif any(N < maxdo+1)
      % Too few points: force refinement
      jj = find(N < maxdo+1);
      csN = [0 ; cumsum(N)];
      v = y;
      for kk = 1:length(jj)
          e = ones(N(jj(kk)),1); e(2:2:end) = -1;
          v{csN(jj(kk))+(1:N(jj(kk)))} = e; 
      end
      return
    end    
    
    % Evaluate the Matrix with boundary conditions attached
    [Amat,ignored,c,ignored,P] = feval(A,N,'bc',map,bks);

    % Project the RHS
    if syssize == 1
        f = P*B(y{1},1);
    else
        f = [];
        for jj = 1:syssize, f = [f ; P{jj}*B(y{1},jj)]; end
    end
    % Add the boundary conditions
    f = [f ; c];

    v = Amat\f;                             % Solve the system

    V = mat2cell(v,repmat(N,1,syssize),1);  % Store for output
    
    v = sum(reshape(v,[sum(N),syssize]),2); % Combine equations
    
    % Filter
    csN = cumsum([0 N]);
    for jj = 1:numel(N)
        ii = csN(jj) + (1:N(jj));
        v(ii) = filter(v(ii),1e-8);
    end
    v = {v};
    
    end

end
  
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%  JUNK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%  function v = valuesys_old_really_old(y)
%      % THIS IS NO LONGER USED
%     % y is a cell array with the points for each function.
%     syssize = numel(y);                 % # of functions/eqns in system
%     % Beakpoints for each function.
%     [bks brkidx] = cellfun(@findbreaks,y,'UniformOutput',false);
%     nfuns = numel([bks{:}])-syssize; % # of funs (intervals) per function  
%     Adifforder = A.difforder;    
%     % Nsys{j}(k) willl contain the # of pts for function j on interval k.
%     Nsys = cell(syssize,1);               
%     x = cell(1,nfuns); % x will be a cell of the points on each interval
%     do = zeros(nfuns,1); % do(j) will be the difforder of the interval j
%     maxdo = max(Adifforder,[],2); % maxdo(j) is the difforder of eqn j
%     
%     intnum = 1;    
%     for jj = 1:syssize
%         ii = brkidx{jj}; nii = numel(ii);
%         % Separate out all the x's.
%         for kk = 1:nii-1
%             x{intnum} = y{jj}(ii(kk)+1:ii(kk+1));
%             intnum = intnum + 1;
%         end
%         % Keep track of their sizes and difforder.
%         idxj = intnum - (nii-1:-1:1);
%         Nsys{jj} = cellfun(@numel,x(idxj));
%         do(idxj) = max(Adifforder(jj,:));
%     end
%     N = cellfun(@length,x); % N is the number of pts on each interval.
%     
%     % Shift the y values at the breakpoints. This is hacky...
%     for jj = 1:syssize
%         ii = brkidx{jj}; nii = numel(ii);
%         for kk = 2:nii-1
%             y{jj}(ii(kk)) = y{jj}(ii(kk)+1)-100*eps;
%             y{jj}(ii(kk)+1) = y{jj}(ii(kk)+1)+100*eps;
%         end
%     end
%     
%     if sum(N) > maxdegree+1
%       error('LINOP:mldivide:NoConverge',['Failed to converge with ',int2str(maxdegree+1),' points.'])
%     elseif any(N==1)
%       error('LINOP:mldivide:OnePoint',...
%         'Solution requested at a lone point. Check for a bug in the linop definition.')
%     elseif any(N(:) <= do(:)+1)
%       % Too few points: force refinement
%       jj = find(N(:) <= do(:)+1);
%       v = x;
%       % THIS NEEDS TWEAKING FOR BREAKPOINTS
%       for kk = 1:length(jj)
%           v{jj(kk)} = ones(N(jj(kk)),1); 
%           v{jj(kk)}(2:2:end) = -1;
%       end
%       return
%     end    
% 
%     % Boundary conditions
%     [Bmat b] = bdyreplace_sys(A,Nsys,map,bks);   % Get the replacement rows
%     [Cmat c] = cont_conds_sys(A,Nsys,map,bks);   % Get the continuity conditions
%    
%     % Construct the block entries of the main matrix
%     Ajk = cell(syssize);
%     for kk = 1:syssize
%         Nsysk = Nsys{kk}; sNsysk = sum(Nsysk);
%         Akfull = feval(A,Nsysk,map,bks{kk});
%         blockcolindx = (kk-1)*sNsysk+1:kk*sNsysk;
%         Ablockcol = Akfull(:,blockcolindx);
%         for jj = 1:syssize
%             blockrowindx = (jj-1)*sNsysk+1:jj*sNsysk;
%             Ajk{jj,kk} = Ablockcol(blockrowindx,:);
%         end
%     end
%     
%    % Assemble the main matrix and rhs
%     Amat = []; f = [];
%     for jj = 1:syssize
%         Amatj = [];
%         Nsysj = Nsys{jj};
%         newN = Nsysj - maxdo(jj);
%         for kk = 1:syssize
%             % Project onto 1st-kind points of the right degree
%             P = barymatp12(newN,bks{jj},Nsys{kk},bks{kk});
%             Amatj = [Amatj P*Ajk{jj,kk}];
%             if jj == kk
%                 f = [f ; P*B(y{jj},jj)]; % The RHS
%             end
%         end    
%         Amat = [Amat ; Amatj];
%     end  
% 
%     Amat = [Amat ; Bmat ; Cmat];  % Augment the boundary conditions to A.
%     f = [f ; b ; c];              % And the rhs.
%     
%     v = Amat\f;             % Solve the system
%     v = mat2cell(v,N,1);    % Reshape and convert to cell array
%     
%     % Filter
%     u = [];
%     for kk = 1:numel(v)
%         v{kk} = filter(v{kk},1e-8);
%         u = [u ; v{kk}];
%     end
%     
%     % Store here for output
%     V = v;
% 
%     % Reshape and convert to cell array of the right size
%     v = mat2cell(u(:),cellfun(@length,y),1);    
% 
%  end
% 
%  
%   function v = valuesys_old(y,N,bks)
%     % y is a cell array with the points for each function.
%     % N{j}(k) contains the # of pts for equation j on interval k.
%     % bks{j}(k:k+1) is the ends of the interval j for equation k.
%     
%     syssize = numel(y);                 % # of eqns in system
%     nints = numel([bks{:}])-syssize;    % Total # of intervals
%        
%     Adifforder = A.difforder;  
%     maxdo = max(Adifforder,[],2); % maxdo(j) is the difforder of eqn j
% 
%     if sum([N{:}]) > maxdegree+1
%       error('LINOP:mldivide:NoConverge',['Failed to converge with ',int2str(maxdegree+1),' points.'])
%     elseif any([N{:}]==1)
%       error('LINOP:mldivide:OnePoint',...
%         'Solution requested at a lone point. Check for a bug in the linop definition.')
%     elseif any([N{:}] < max(maxdo)+1)
%       % Too few points: force refinement
%       jj = find([N{:}] < max(maxdo)+1);
%       v = y;
%       % THIS NEEDS TWEAKING FOR BREAKPOINTS
%       error
%       for kk = 1:length(jj)
%           v{jj(kk)} = ones(N(jj(kk)),1); 
%           v{jj(kk)}(2:2:end) = -1;
%       end
%       return
%     end    
%    
%     if syssize == 1     % The single-equation case is easiest
%         Amat = feval(A,N{1},map,bks{1});
%         P = barymatp12(N{1}-maxdo,bks{1},N{1},bks{1});
%         Amat = P*Amat;
%         f = P*B(y{1},1);
%     else                % Systems require more work to build
%         % Construct the block entries of the main matrix
%         Ajk = cell(syssize);
%         for kk = 1:syssize
%             Nk = N{kk}; sNk = sum(Nk);
%             Akfull = feval(A,Nk,map,bks{kk});
%             blockcolindx = (kk-1)*sNk+1:kk*sNk;
%             Ablockcol = Akfull(:,blockcolindx);
%             for jj = 1:syssize
%                 blockrowindx = (jj-1)*sNk+1:jj*sNk;
%                 Ajk{jj,kk} = Ablockcol(blockrowindx,:);
%             end
%         end
%         % Assemble the main matrix and rhs
%         Amat = []; f = [];
%         for jj = 1:syssize
%             Amatj = [];
%             for kk = 1:syssize
%                 % Project onto 1st-kind points of the right degree
%                 P = barymatp12(N{jj}-maxdo(jj),bks{jj},N{kk},bks{kk});
%                 Amatj = [Amatj P*Ajk{jj,kk}];
%                 if jj == kk
%                     f = [f ; P*B(y{jj},jj)]; % The RHS
%                 end
%             end    
%             Amat = [Amat ; Amatj];
%         end  
%     end
%     
%     % Boundary conditions
%     [Bmat b] = bdyreplace_sys(A,N,map,bks); % Get the replacement rows
%     [Cmat c] = cont_conds_sys(A,N,map,bks); % Get the continuity conditions
%     
%     Amat = [Amat ; Bmat ; Cmat];  % Augment the boundary conditions to A.
%     f = [f ; b ; c];              % And the rhs.
%     
%     v = Amat\f;                   % Solve the system
%     v = mat2cell(v,[N{:}],1);     % Reshape and convert to cell array
%     
%     % Filter
%     u = [];
%     for kk = 1:numel(v)
%         v{kk} = filter(v{kk},1e-8);
%         u = [u ; v{kk}];
%     end
%     
%     % Store here for output
%     V = v;
% 
%     % Reshape and convert to cell array of the right size
%     v = mat2cell(u(:),cellfun(@length,y),1);    
% 
%  end