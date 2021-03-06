function middleM = getMiddleMatrix(m, sz)
%Extract values near middle of a matrix.
%
%   middleM = getMiddleMatrix(m,sz)
%
% Data values from the middle of a matrix are returned. The total number
% of extracted pixels is 1 + round(sz/2)*2.  This is awkward  for small
% numbers of sz, but OK for bigger numbers.  
%   
%  Example:
%     m = reshape([1:(9*9)],9,9);
%     foo = getMiddleMatrix(m,3)
%
%     m = reshape([1:(9*9*3)],9,9,3);
%     foo = getMiddleMatrix(m,5)
%
% Copyright ImagEval Consultants, LLC, 2003.

% Changed from round to floor on March 19, 2015.  We are worried, but it
% had no effect on validationfastall and the routine is only called in a
% few places where this should be OK.  Delete this comment after a few
% months.
% HJ/BW
sz = floor(sz/2);

center = round(size(m)/2);
rMin = max(1,center(1)-sz); rMax = min(size(m,1), center(1)+sz);
cMin = max(1,center(2)-sz); cMax = min(size(m,2), center(2)+sz);

r = rMin : rMax;
c = cMin : cMax;
% w = size(m,3);
middleM = m(r, c, :);

end

