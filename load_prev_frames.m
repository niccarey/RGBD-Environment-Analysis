function[framedata] = load_prev_frames(prename, storedir, av_frames, c_frame)

f_load = min(av_frames+1, c_frame);
cd(storedir);

if (av_frames == 1)
    filename = [prename 'depth_frame_' num2str(c_frame-1, '%04d')];
    upload_frame = load(filename);
    eval(['frameDat.storeframe_' num2str(c_frame-1) '= upload_frame.depthmap ;']);
else
    for kk = (c_frame-f_load+1):(c_frame-1)
        filename = [prename 'depth_frame_' num2str(kk,  '%04d')];
        upload_frame = load(filename);
        eval(['frameDat.storeframe_' num2str(kk) '= upload_frame.depthmap ;']);
    end
end

cd('../');

framedata = frameDat;