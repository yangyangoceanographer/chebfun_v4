function [funs,ends,scl] = auto(op,ends,scl,pref)
% [FUNS,ENDS,SCL,SING] = AUTO(OP,ENDS,SCL,PREF)
%    AUTO generates a vector of FUNS used to construct a chebfun
%    representation of the function handle OP. 
%
%    The input vector ENDS   must initially consist of two values and 
%    corresponds to the global interval [a,b]. The ouput vector ends may 
%    contain adional breakpoints if the splitting mode is on. 
%
%    SCL is a structure with two fields: SCL.H and SCL.V corresponding to 
%    the horizonatal and veritcal global scales. This vector is update 
%    within AUTO and is returned as output. 
% 
%    PREF is the chebfun preference structure (see chebfunpref).
%
%    Note: this function is used in ctor_2.m
%
%    See http://www.comlab.ox.ac.uk/chebfun for chebfun information.

% Copyright 2002-2008 by The Chebfun Team. 
 
% Initial setup.


htol = 1e-14*scl.h;


% -------------------------------------------------------------------------
% In SPLITTING OFF mode, seek only one piece with length no greater than
% maxdegree (default is 2^16)

if ~pref.splitting
     maxn = pref.maxdegree+1;
     [funs,hpy] = getfun(op,ends,maxn,scl,pref);
     if ~hpy
        warning('CHEBFUN:auto',['Function not resolved, using ' int2str(maxn) ...
            ' pts. Have you tried ''splitting on''?']);
     end
     return;
end
% ------------------------------------------------------------------------

% SPLITTING ON mode!
maxn = pref.maxlength+1;
nsplit = pref.splitdegree+1;            % Get maxn from preferences: default is 129.

[funs,hpy,scl] = getfun(op,ends,nsplit,scl,pref);    % Try to get one smooth piece for the entire interval 
sad = ~hpy;                                     % before splitting interval

% MAIN LOOP
% If the above didn't work, anter main loop and start splitting (at least
% one breakpoint will be introduced).
while any(sad)
        
    % If a fun is sad in a subinterval, split this subinterval.
    i = find(sad,1,'first');
    a = ends(i); b = ends(i+1);

    % Look for an edge between [a,b].
    edge = detectedge(op,a,b,scl.h,scl.v);

    if isempty(edge) % No edge found, split interval at the middle point
        edge = 0.5*(a+b);
    elseif (edge-a) <= htol % Edge is close to the left boundary, assume it is at x=a
        edge = a+(b-a)/100; % Split interval closer to the left boundary
    elseif (b-edge) <= htol % Edge is close to the right boundary, assume it is at x=b
        edge = b-(b-a)/100; % Split interval closer to the right boundary
    end

    % Try to obtain happy funs on each new subinterval.
    % ------------------------------------
    [child1, hpy1, scl] = getfun(op, [a, edge], nsplit, scl, pref);
    [child2, hpy2, scl] = getfun(op, [edge, b], nsplit, scl, pref);
    funs = [funs(1:i-1) child1 child2 funs(i+1:end)];
    ends = [ends(1:i) edge ends(i+1:end)];
    sad  = [sad(1:i-1) not(hpy1) not(hpy2) sad(i+1:end)];

    %% -------- Stop? check the length --------
    lenf = 0;
    for i = 1:numel(funs)
        lenf = lenf+length(funs(i));
    end
    
    if lenf > maxn
        warning('CHEBFUN:auto',['Chebfun representation may not be accurate:' ...
                'using ' int2str(lenf) ' points'])
        return
    end
    %% ----------------------------------------
end

% Update vertical scale ?
% funs=set(funs,'scl.v',scl.v);
% Removed this, the scale will be updated when the chebfun is constructed.