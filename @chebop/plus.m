function Nout = plus(N1,N2)

% Copyright 2011 by The University of Oxford and The Chebfun Developers. 
% See http://www.maths.ox.ac.uk/chebfun/ for Chebfun information.

if isnumeric(N1)
    N1show = cellstr(repmat(mat2str(N1),size(N2.opshow)));
    mode = num2cell(repmat(1,size(N2.opshow)));
    if strcmp(N2.optype,'anon_fun')
        Nout = chebop(N2.dom, @(u) N1+N2.op(u));
        Nout.optype = 'anon_fun';
        Nout.opshow = cellfun(@combineshow,N1show,N2.opshow,mode,'uniform',false);
    else
        N2show = cellstr(repmat('chebop',size(N2.opshow)));
        Nout = chebop(N2.dom, @(u) N1+ feval(N2.op,u));
        Nout.optype = 'anon_fun';
        Nout.opshow = cellfun(@combineshow,N1show,N2show,mode,'uniform',false);
    end
    return
end

if isnumeric(N2)
    N2show = cellstr(repmat(mat2str(N2),size(N1.opshow)));
    mode = num2cell(repmat(2,size(N1.opshow)));
    if strcmp(N1.optype,'anon_fun')
        Nout = chebop(N1.dom, @(u) N1.op(u)+N2);
        Nout.optype = 'anon_fun';
        Nout.opshow = cellfun(@combineshow,N1.opshow,N2show,mode,'uniform',false);
    else
        N1show = cellstr(repmat('chebop',size(N1.opshow)));
        Nout = chebop(N1.dom, @(u) feval(N1.op,u)+N2);
        Nout.optype = 'anon_fun';
        Nout.opshow = cellfun(@combineshow,N1show,N2show,mode,'uniform',false);
    end
    return
end

if ~(N1.dom == N2.dom)
    error('CHEBOP:plus:domain','Domains of operators do not match');
end

if ~strcmp(N1.optype,N2.optype)
    error('CHEBOP:plus:opType','Operators must be of same type (handle or linop)');
end

mode = num2cell(repmat(3,size(N1.opshow)));
if strcmp(N1.optype,'anon_fun')
    Nout = chebop(N1.dom, @(u) N1.op(u)+N2.op(u));
    Nout.optype = 'anon_fun';
    Nout.opshow = cellfun(@combineshow,N1.opshow,N2.opshow,mode,'uniform',false);
else
    Nout = chebop(N1.dom, N1.op+N2.op);
    Nout.optype = 'linop';
    Nout.opshow = cellfun(@combineshow,N1.opshow,N2.opshow,mode,'uniform',false);
end


end

function s = combineshow(op1,op2,mode)
if mode == 1  % Double + chebop
    firstRightParLoc2 = min(strfind(op2,')'));
    if isempty(firstRightParLoc2)
        s = [op1,'+',op2];
    else
        funArgs2 = op2(1:firstRightParLoc2);
        fun2 = op2(firstRightParLoc2+1:end);
        s = [funArgs2,op1,'+',fun2];
    end
elseif mode == 2 % Chebop + double
    firstRightParLoc1 = min(strfind(op1,')'));
    if isempty(firstRightParLoc1)
        s = [op1,'+',op2];
    else
        funArgs1 = op1(1:firstRightParLoc1);
        fun1 = op1(firstRightParLoc1+1:end);
        s = [funArgs1,fun1,'+',op2];
    end
else % Chebop + chebop. Combine the output in a nice way
    if length(op1) + length(op2) >= 70
        s = 'chebop + chebop';
    else
        firstRightParLoc1 = min(strfind(op1,')'));
        firstRightParLoc2 = min(strfind(op2,')'));
        
        funArgs1 = op1(1:firstRightParLoc1);
        funArgs2 = op2(1:firstRightParLoc2);
        
        fun1 = op1(firstRightParLoc1+1:end);
        fun2 = op2(firstRightParLoc2+1:end);
        if ~strcmp(funArgs1,funArgs2)
            error('CHEBOP:plus:arguments','Arguments of chebops do not match.');
        end
    end
end
end


% For possible future use? Right now it doesn't allow nested hyperlinks.
% These links are strings executed in the base workspace and so anonymous functions
% don't seem to help.
function s = linktodisplay(N)

s = ['<a href="matlab:display(''',N.opshow,''')">chebop</a>'];

end

