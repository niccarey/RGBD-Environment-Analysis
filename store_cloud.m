function[] = store_cloud(name, storedir, current_frame, pxcloud, mmcloud)

cd(storedir);
savename = [name num2str(current_frame,'%06d') '.mat'];
save(savename, 'pxcloud', 'mmcloud');
cd('../')
