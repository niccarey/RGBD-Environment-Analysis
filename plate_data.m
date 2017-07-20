% termite_build_analysis: 
% Load rotation and translation vectors for base of filming arena

plate_om = input('Please enter a rotation vector for the filming arena baseline: ');
plate_tc = input('Please enter a translation vector for the filming arena baseline: ');

% heuristic height adjustment if necessary
depth_est = plate_tc(3) - 4;
