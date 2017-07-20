% termite_build_analysis: Change RGB thresholds 
% Store data in figure properties

% initialize image frame
rgb_sel = figure;
fighandles = guihandles(rgb_sel);

set(rgb_sel, 'Position', [100, 250, 1200, 750]);
rgb_ax = axes('Parent', rgb_sel, 'position', [0.13 0.34, 0.8 0.6]);
fighandles.AxHandle = rgb_ax;

bgcolor = rgb_sel.Color;

% set up image call button
imsel = uicontrol('Parent', rgb_sel, 'Style', 'pushbutton', 'Position', [590, 60, 80,30], ...
    'Callback', @ui_im_load, 'String', 'RGB image');

% set up sliders
p1 = uipanel('Parent', rgb_sel, 'Position', [0.13, 0.13, 0.36, 0.16]);
p2 = uipanel('Parent', rgb_sel, 'Position', [0.55, 0.13, 0.36, 0.16]);

redmin = uicontrol('Parent', p1, 'Style', 'slider',  'Position', [100, 70, 200, 15], ...
    'value', 0, 'min', 0, 'max', 1, 'Callback', @slider_callback, 'Tag', 'rmin');
redmax = uicontrol('Parent', p2, 'Style', 'slider', 'Position', [100, 70, 200, 15], ...
    'value', 1, 'min', 0, 'max', 1, 'Callback', @slider_callback, 'Tag', 'rmax');
greenmin = uicontrol('Parent', p1, 'Style', 'slider', 'Position', [100, 50, 200, 15],...
    'value', 0, 'min', 0, 'max', 1, 'Callback', @slider_callback, 'Tag', 'gmin');
greenmax = uicontrol('Parent', p2, 'Style', 'slider', 'Position', [100, 50, 200, 15],...
    'value', 1, 'min', 0, 'max', 1, 'Callback', @slider_callback, 'Tag', 'gmax');
bluemin = uicontrol('Parent', p1, 'Style', 'slider',  'Position', [100, 30, 200, 15], ...
    'value', 0, 'min', 0, 'max', 1, 'Callback', @slider_callback, 'Tag', 'bmin');
bluemax = uicontrol('Parent', p2, 'Style', 'slider',  'Position', [100, 30, 200, 15],...
    'value', 1, 'min', 0, 'max', 1, 'Callback', @slider_callback, 'Tag', 'bmax');

fighandles.rmin = 0;
fighandles.rmax = 1;
fighandles.gmin = 0;
fighandles.gmax = 1;
fighandles.bmin = 0;
fighandles.bmax = 1;

align([redmin, greenmin,  bluemin], 'Left', 'Fixed', 15);
align([redmax, greenmax, bluemax], 'Right', 'Fixed', 15);

textrmin = uicontrol('Parent', p1, 'Style', 'text', 'Position', [ 20, 90, 80, 20], ...
    'String', 'Min Red', 'BackgroundColor', bgcolor);
textrmax = uicontrol('Parent', p2, 'Style', 'text', 'Position', [ 20, 90, 80, 20], ...
    'String', 'Max Red', 'BackgroundColor', bgcolor);
textgmin = uicontrol('Parent', p1, 'Style', 'text','Position',  [ 20, 58, 80, 20], ...
    'String', 'Min Green', 'BackgroundColor', bgcolor);
textgmax = uicontrol('Parent', p2, 'Style', 'text', 'Position', [ 20, 58, 80, 20], ...
    'String', 'Max Green', 'BackgroundColor', bgcolor);
textbmin = uicontrol('Parent', p1, 'Style', 'text', 'Position', [ 20, 25, 80, 20],  ...
    'String', 'Min Blue', 'BackgroundColor', bgcolor);
textbmax = uicontrol('Parent', p2, 'Style', 'text', 'Position', [ 20, 25, 80, 20],  ...
    'String', 'Max Blue', 'BackgroundColor', bgcolor);

% close button
imclose = uicontrol('Parent', rgb_sel, 'Style', 'pushbutton', 'Position', [590, 20, 80,30], ...
    'Callback', @ui_close, 'String', 'Close');

align([rgb_ax, imsel, imclose], 'center', 'none');


guidata(rgb_sel, fighandles);

% to-do: add clean up functions to close

function ui_im_load(hObject, eventdata)
    [file, folder] = uigetfile('*.jpg');
    fighandles = guidata(gcbo);
    
    if ~isequal(file, 0)
        tm_im = imread(fullfile(folder, file));
        fighandles.rgb_im = tm_im;

        % load image into window
        imshow(tm_im, 'Parent', fighandles.AxHandle);
    end    
    guidata(gcbo, fighandles);
end

function ui_close(hObject, eventdata)
    % clean up workspace
    % can't use clearvars unless we keep everything in specific structures
    evalin('base', 'clear redmin redmax greenmin greenmax bluemin bluemax');
    evalin('base', 'clear textbmin textbmax textgmin textgmax textrmin textrmax');
    evalin('base', 'clear bgcolor fighandles rgb_ax');
    evalin('base', 'clear p p1 p2 imsel imclose')
    close(gcf);
end


function slider_callback(hObject, eventdata)
    sval = hObject.Value;
    fighandles = guidata(gcbo);
    
    if ~isfield(fighandles, 'rgb_im')
        disp('Error: load image before moving sliders');
    else
        switch hObject.Tag
            case 'rmin'
                fighandles.rmin = sval;
                if fighandles.rmin > fighandles.rmax
                    fighandles.rmin = fighandles.rmax;
                    set(hObject.Value, 'Value', fighandles.rmin);
                end
            case 'rmax'
                fighandles.rmax = sval;
                if fighandles.rmax < fighandles.rmin
                    fighandles.rmax = fighandles.rmin;
                    set(hObject.Value, 'Value', fighandles.rmax);
                end
            case 'gmin'
               fighandles.gmin = sval;
               if fighandles.gmin > fighandles.gmax
                    fighandles.gmin = fighandles.gmax;
                    set(hObject.Value, 'Value', fighandles.gmin);
               end
            case 'gmax'
                fighandles.gmax = sval;
                if fighandles.gmax < fighandles.gmin
                    fighandles.gmax = fighandles.gmin;
                    set(hObject.Value, 'Value', fighandles.gmax);
                end
            case 'bmin'
                fighandles.bmin = sval;
                if fighandles.bmin > fighandles.bmax
                    fighandles.bmin = fighandles.bmax;
                    set(hObject.Value, 'Value', fighandles.bmin);
               end
            case 'bmax'
                fighandles.bmax = sval;
                if fighandles.bmax < fighandles.bmin
                    fighandles.bmax = fighandles.bmin;
                    set(hObject.Value, 'Value', fighandles.bmax);
                end
        end
   
        rgb_params = [fighandles.rmin, fighandles.gmin,fighandles.bmin ; fighandles.rmax, fighandles.gmax, fighandles.bmax];
    
        adjustRGB = imadjust(fighandles.rgb_im, rgb_params);
        imshow(adjustRGB, 'Parent', fighandles.AxHandle);

        % output to workspace
        assignin('base', 'rgb_overlay', rgb_params);
    end

    guidata(gcbo, fighandles);

end
