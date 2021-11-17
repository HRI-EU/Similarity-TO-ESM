% Title: 
%    Similarity-based Topology Optimization using Energy Scaling Method
% Authors: 
%    Muhammad Salman Yousaf, Duane Detwiler, Fabian Duddeck, Satchit Ramnath and Mariusz Bujny
% Corresponding Author: 
%    salman.yousaf@tum.de


clc; clear;
nelx = 100; nely = 100; volfrac = 0.3; penal = 3; rmin = 1.5; ft = 1;
load reference_structure.mat % loads 0-1 pixels of 100 by 100 reference design
energy_scaling_value = 0.98; % energy scaling value for the preferred region

top_esm(nelx,nely,volfrac,penal,rmin,reference_structure,energy_scaling_value);