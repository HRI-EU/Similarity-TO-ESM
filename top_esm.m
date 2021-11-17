% Title: 
%    Similarity-based Topology Optimization using Energy Scaling Method
% Authors: 
%    Muhammad Salman Yousaf, Duane Detwiler, Fabian Duddeck, Satchit Ramnath and Mariusz Bujny
% Corresponding Author: 
%    salman.yousaf@tum.de

function top_esm(nelx,nely,volfrac,penal,rmin,reference_structure,pref_region_energy_scaling)
%% MATERIAL PROPERTIES
E0 = 1;
Emin = 1e-9;
nu = 0.3;
%% PREPARE FINITE ELEMENT ANALYSIS
A11 = [12  3 -6 -3;  3 12  3  0; -6  3 12 -3; -3  0 -3 12];
A12 = [-6 -3  0  3; -3 -6 -3 -6;  0 -3 -6  3;  3 -6  3 -6];
B11 = [-4  3 -2  9;  3 -4 -9  4; -2 -9 -4 -3;  9  4 -3 -4];
B12 = [ 2 -3  4 -9; -3  2  9 -2;  4  9  2  3; -9 -2  3  2];
KE = 1/(1-nu^2)/24*([A11 A12;A12' A11]+nu*[B11 B12;B12' B11]);
nodenrs = reshape(1:(1+nelx)*(1+nely),1+nely,1+nelx);
edofVec = reshape(2*nodenrs(1:end-1,1:end-1)+1,nelx*nely,1);
edofMat = repmat(edofVec,1,8)+repmat([0 1 2*nely+[2 3 0 1] -2 -1],nelx*nely,1);
iK = reshape(kron(edofMat,ones(8,1))',64*nelx*nely,1);
jK = reshape(kron(edofMat,ones(1,8))',64*nelx*nely,1);
% DEFINE LOADS AND SUPPORTS (CANTILEVER BEAM WITH UNIT LOAD ON RIGHT EDGE MIDPOINT)
load_node_y = round((nely+1)/2);
load_node = (nely+1)*(nelx+1)-load_node_y;
F = sparse(2*load_node,1,-1,2*(nely+1)*(nelx+1),1);
U = zeros(2*(nely+1)*(nelx+1),1);
fixeddofs = [1:2*(nely+1)];
alldofs = [1:2*(nely+1)*(nelx+1)];
freedofs = setdiff(alldofs,fixeddofs);
%% PREPARE FILTER
iH = ones(nelx*nely*(2*(ceil(rmin)-1)+1)^2,1);
jH = ones(size(iH));
sH = zeros(size(iH));
k = 0;
for i1 = 1:nelx
  for j1 = 1:nely
    e1 = (i1-1)*nely+j1;
    for i2 = max(i1-(ceil(rmin)-1),1):min(i1+(ceil(rmin)-1),nelx)
      for j2 = max(j1-(ceil(rmin)-1),1):min(j1+(ceil(rmin)-1),nely)
        e2 = (i2-1)*nely+j2;
        k = k+1;
        iH(k) = e1;
        jH(k) = e2;
        sH(k) = max(0,rmin-sqrt((i1-i2)^2+(j1-j2)^2));
      end
    end
  end
end
H = sparse(iH,jH,sH);
Hs = sum(H,2);
%% INITIALIZE ITERATION
x = repmat(volfrac,nely,nelx);
loop = 0;
change = 1;
sq_dissimilarity_metric= 0;
%% START ITERATION
while change > 0.01
  loop = loop + 1;
  %% FE-ANALYSIS
  sK = reshape(KE(:)*(Emin+x(:)'.^penal*(E0-Emin)),64*nelx*nely,1);
  K = sparse(iK,jK,sK); K = (K+K')/2;
  U(freedofs) = K(freedofs,freedofs)\F(freedofs);
  %% OBJECTIVE FUNCTION AND SENSITIVITY ANALYSIS
  ce = reshape(sum((U(edofMat)*KE).*U(edofMat),2),nely,nelx);
  c = sum(sum((Emin+x.^penal*(E0-Emin)).*ce));
  dc = -penal*(E0-Emin)*x.^(penal-1).*ce;
  dv = ones(nely,nelx);
  %% FILTERING/MODIFICATION OF SENSITIVITIES
  dc(:) = H*(x(:).*dc(:))./Hs./max(1e-3,x(:));
  %% APPLY ENERGY SCALING TO PREFERRED AND NON-PREFERRED REGIONS
  dc(reference_structure==1) = pref_region_energy_scaling*dc(reference_structure==1);
  dc(reference_structure==0) = (1-pref_region_energy_scaling)*dc(reference_structure==0);
  %% OPTIMALITY CRITERIA UPDATE OF DESIGN VARIABLES AND PHYSICAL DENSITIES
  l1 = 0; l2 = 1e9; move = 0.2;
  while (l2-l1)/(l1+l2) > 1e-3
    lmid = 0.5*(l2+l1);
    xnew = max(0,max(x-move,min(1,min(x+move,x.*sqrt(-dc./dv/lmid)))));
    if sum(xnew(:)) > volfrac*nelx*nely, l1 = lmid; else l2 = lmid; end
  end
  change = max(abs(xnew(:)-x(:)));
  x = xnew;
  sq_dissimilarity_metric = mean((x(:)-reference_structure(:)).^2);
  %% PRINT RESULTS
  fprintf(' It.:%5i Obj.:%11.4f Vol.:%7.3f ch.:%7.3f\n sq. dissimilarity metric.:%7.3f\n', ...
  loop,c,mean(x(:)),change,sq_dissimilarity_metric);
  %% PLOT DENSITIES
  colormap(gray); imagesc(1-x); caxis([0 1]); axis equal; axis off; drawnow;
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Original work Copyright (c) 2001 E. Andreassen, A. Clausen,              %
% M. Schevenels, B. S. Lazarov and O. Sigmund,                             %
% Department of Solid  Mechanics, Technical University of Denmark,         %
% DK-2800 Lyngby, Denmark.                                                 %
% Please sent your comments to: sigmund@fam.dtu.dk.                        %
%                                                                          %
% Modified work Copyright (c) 2021 Muhammad Salman Yousaf, Duane Detwiler, %
% Fabian Duddeck, Satchit Ramnath and Mariusz Bujny.                       %
% Please sent your comments to: salman.yousaf@tum.de.                      %
%                                                                          %
% Permission is hereby granted, free of charge, to any person obtaining    %
% a copy of this software and associated documentation files               %
% (the "Software"), to deal in the Software without restriction, including %
% without limitation the rights to use, copy, modify, merge, publish,      %
% distribute, sublicense, and/or sell copies of the Software, and to       %
% permit persons to whom the Software is furnished to do so, subject to    %
% the following conditions:                                                %
%                                                                          %
% The above copyright notice and this permission notice shall be included  %
% in all copies or substantial portions of the Software.                   %
%                                                                          %
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS  %
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF               %
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.   % 
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY     %
% CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,     %
% TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        %
% SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%