%imd = read_disparity(filename)
% Reads a disparity image from disk. Corrects endianness issues. Replaces
% 'nan_value' values with NaNs. Default for nan_value is 2047.
%
% Kinect calibration toolbox by DHC

function imd = read_disparity(filename, width, height, nan_value)

if(nargin < 4)
  nan_value = 65535;
end

use_custom_read = false;

[~,~,ext]=fileparts(filename);
if(strcmp(ext,'.pgm'))
  %PGM file, check for binary
  [fid,msg] = fopen(filename,'r');
  if(fid < 0)
    error('kinect_toolbox:read_disparity:fopen',strrep([filename ':' msg],'\','\\'));
  end
  
  magic = fscanf(fid,'%c',2);
  if(strcmp(magic,'P5'))
    %Binary pgm, use custom read to avoid matlab scaling
    use_custom_read = true;
  end
  fclose(fid);
  
    if(use_custom_read)
    [imd,max_value]=readpgm_noscale(filename);
    else
    imd = uint16(imread(filename));
    max_value = 65535;
    end
else
  %dat file, can read directly using fread
  [fid,msg] = fopen(filename,'r');
  if(fid < 0)
    error('realsense_toolbox:read_disparity:fopen',strrep([filename ':' msg],'\','\\'));
  end
  imd = fread(fid, '*uint16');%fscanf(fid,'%c',2);
  fclose(fid);
  %We need to reshape to get depth image.
  if length(imd) == width*height
  imd = reshape(imd, width, height);
  %We need to rotate the image by 90 degrees (whoops wrong direction??)
  imd = fliplr(rot90(rot90(rot90(imd))));
  else 
      fprintf('Error: image read failed. Vector length %d', length(imd));
  end
end


%Check channel count
if(size(imd,3) > 1)
  warning('kinect_toolbox:read_disparity:channels','Disparity image has multiple channels, taking only first channel.');
  imd = imd(:,:,1);
end

if(strcmp(ext,'.pgm'))
                                                        
  %Check for little-endian and matlab scaling problems
  if(nan_value==2047 && max(imd(:)) > 2047) %0x07FF
    imd_swap = swapbytes(imd);
    if(max(imd_swap(:)) <= 2047)
      %Fixed by swap
      imd = imd_swap;
    elseif(~use_custom_read)
      %We used matlabs imread, maybe matlab rescaled
      imd = imd / ((max_value+1)/2048);
    else
      warning('kinect_toolbox:read_disparity:max','Maximum disparity value is over 2047.');
    end
  end

  %Set invalid depths to NaN
  imd = double(imd);
  imd(imd==nan_value) = NaN;

else
  % RealSense uses 0 to represent infinity/unresolvable pixels. So Set invalid depths to NaN
  imd = double(imd);
  imd(imd==0) = NaN;
end
