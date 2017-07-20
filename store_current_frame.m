function[] = store_current_frame(name, storedir, current_frame, depthmap)

cd(storedir);
savename = [name num2str(current_frame,'%04d') '.mat'];
save(savename, 'depthmap');
cd('../')
