function[] = store_overlay(name, storedir, current_frame, rgbmat)

cd(storedir);
savename = [name num2str(current_frame) '.mat'];
save(savename, 'rgbmat');
cd('../')
