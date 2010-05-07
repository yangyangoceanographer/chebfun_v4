function pass = infimps
% Check that imps are properly set in computations involving exps
%
% NH 08/12

tol = 2e3*chebfunpref('eps');
gam = chebfun('gamma(x)',[-4:0 4],'blowup','on');
gami = merge(1./gam);
I = gami.*gam;
pass = norm(I-1,inf) < tol;
