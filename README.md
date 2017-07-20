# RGBD-Environment-Analysis
4D micro-scale scene reconstruction using Intel Realsense or other RGBD streaming hardware

Originally designed to reconstruct soil manipulation by Macrotermes, this toolbox has a lot of handy functions for anyone working with RGB-D data, so I thought I'd upload it publically. 


Key functions:
- bg_frame_create: uses a moving persistence and averaging filter to generate an initial background frame
- noiseCalculator: One of the big problems with working with depth sensor data in the realworld is noise. Some portions of the frame may be persistently noisy, or have persistent depth holes - at other times noise is seen when viewing certain materials, or under specific lighting conditions. This function calculates pixel variance for high-frame-rate data and uses this to generate a likely noise-pixel map. (note: may not be effective at low framerates with fast-moving scene elements)
