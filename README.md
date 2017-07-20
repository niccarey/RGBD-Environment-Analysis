# RGBD-Environment-Analysis
4D micro-scale scene reconstruction using Intel Realsense or other RGBD streaming hardware, using MATLAB.

Originally designed to reconstruct soil manipulation by Macrotermes, this toolbox has a lot of handy functions for anyone working with RGB-D data, so I thought I'd upload it publically. It is not a general-purpose 3D reconstruction tool: it is designed explicitly for sub-mm reconstruction using a fixed cameras, and currently only works with a licensed version of matlab.

This toollbox requires explicit intrinsic and extrinsic camera parameters, and a certain amount of knowledge of the filming environment (eg. distance/rotation to baseline plane of interest). The easiest way to create this data in an appropriate format is to use the  Caltech Vision Camera Calibration Toolbox, http://www.vision.caltech.edu/bouguetj/calib_doc/.

May also require access to the Matlab Image Processing toolbox. Coming soon: a truly open-source version of this toolbox, using Python.

Run Termite_Build_Analysis for a gui menu with access to all key scripts.  

%----------------------%
# Documentation from Termite_Build_Analysis: to be updated

To use these functions, you will need:
 - a stereo calibration file containing RGB and depth camera stereo data (see Calib_Results_stereo in RS1 Calib Data)
 - the precise depth/disparity mapping for the depth camera (see DepthDisparityMapping in RS1 Calib Data)
 - the plate rotation (plate_om) and translation (plate_tc) vectors for the baseline of the filming arena (see DepthDisparityMapping in RS1 Calib Data for the calibration image number. Once Calib_Results_stereo has been loaded, call
plate_om = calibStruct.omc_left_xx
plate_tc = calibStruct.tc_left_xx
where xx is the calibration image number)

Optional but useful:
- a residual depth error array, which removes any sensor tilt in the depth camera (load DepthError.mat in RS1 Calib Data)
- a thresholding function to isolate the dish in the RGB array (example threshold function included, or define a new threshold from within the GUI)
- a vector of RGB limits to use when processing the RGB image (can be constructed from within the GUI)
- a thresholding function to isolate the termites (example function included, or define a new function from within the GUI)
- a background frame (termites removed) which can be subtracted to remove any remaining steady-state errors in the depth. This can be constructed from within the GUI. Recommend running in debug mode so script can be killed when background frame has reached an optimal point.
- an array mask identifying noisy pixels. This can also be constructed from within the GUI. Usually 300 frames is sufficient to identify noisy pixels.

depth_in_rgb_store: creates a sequence of depth images in the RGB reference frame. Output is two arrays the same size as the RGB images, containing projected and interpolated depth values for (1) the raw depth image and (2) the depth image with non-steady-state noise removed. Including a background subtraction step will remove steady-state noise from both arrays.
These depth maps are ready to be overlaid on colour images with no further transformation needed. Use the mesh function with option [ 'CData' = rgb_image ]to view the RGBD output.

% ------------------------ %

# Documentation of key scripts:

rgb_loader: Select a folder containing RGB images, loads location and number of images

depth_loader: Select a folder containing raw .dat depth data, loads location and number of files (nB: depth and color frames must be temporally aligned,)

calib_load: loads calibration parameters from a file structure. Expected format for calib_load is that used by the Caltech Camera Calibration Toolbox.

alpha_load: Asks for depth/disparity coefficients - must be accurate to at least 3sf for good reconstruction

dishThresholding: Select dish thresholding - an initial threshold function can be used to select a specific region of interest.

select_threshold: Load termite-locating thresholder - can be used to identify segments of an image that you do not want to include in the 3D reconstruction. For example, small, fast-moving insects.

create_threshold: Loads the colorThresholder GUI in the matlab image processing toolbox. 

rgb_sliders: Adjusts RGB pre-filter - accurate thresholding can be aided by adjusting the color limits.

bg_frame_create: uses a moving persistence and averaging filter to generate an initial background frame

noiseCalculator: One of the big problems with working with depth sensor data in the realworld is noise. Some portions of the frame may be persistently noisy, or have persistent depth holes - at other times noise is seen when viewing certain materials, or under specific lighting conditions. This function calculates pixel variance for high-frame-rate data and uses this to generate a likely noise-pixel map. (note: may not be effective at low framerates with fast-moving scene elements)
