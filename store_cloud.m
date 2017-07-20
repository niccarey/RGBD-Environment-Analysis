function[] = store_cloud(name, storedir, current_frame, pxcloud, mmcloud)

cd(storedir);
savename = [name num2str(current_frame) '.mat'];
save(savename, 'pxcloud', 'mmcloud');
cd('../')
