function pass = pointevals

% LNT 20 May 2008
% This code makes sure point evaluations are working

splitting on

f = chebfun(@(x) sign(x-1),[0 2]);
pass(1) = (f(1+eps) == 1);
pass(2) = (f(1-eps) == -1);
pass(3) = (f(1) == 0);
f(1) = 3;
f(1.5) = 4;
pass(4) = (f(1) == 3);
pass(5) = (f(1.5) == 4);
pass(6) = (sum(f) == 0);

