function focal_length_calibrator()
    close all; clc;

    %% Select image
    choice = questdlg('Use camera or load an image?', 'Image Source', ...
                      'Use Camera', 'Load Image', 'Use Camera');
    if isempty(choice), return; end

    switch choice
        case 'Use Camera'
            system('grab.exe');  % Replace with your camera capture command
            img = imread('captured_image.jpg');
        case 'Load Image'
            [file, path] = uigetfile({'*.jpg;*.png;*.bmp'}, 'Select Image');
            if isequal(file, 0), return; end
            img = imread(fullfile(path, file));
        otherwise
            return;
    end

    %% Ask for known values
    prompt = {'Enter real object width (mm):', ...
              'Enter distance from camera (mm):'};
    dlgtitle = 'Calibration Inputs';
    dims = [1 50];
    definput = {'50', '300'};  % Default values
    answer = inputdlg(prompt, dlgtitle, dims, definput);
    if isempty(answer), return; end

    realWidth_mm = str2double(answer{1});
    distance_mm  = str2double(answer{2});

    %% Show image and get object width in pixels
    figure('Name', 'Click left and right edges of known-width object');
    imshow(img); title('Click LEFT and RIGHT edges of object');
    [x, ~] = ginput(2);  % Click two points horizontally

    pixelWidth = abs(x(2) - x(1));

    %% Compute focal length
    focal_px = (pixelWidth * distance_mm) / realWidth_mm;

    %% Show result
    msg = sprintf(['Calibration Complete!\n\n' ...
                   'Measured Pixel Width: %.2f px\n' ...
                   'Real Width: %.2f mm\n' ...
                   'Distance to Camera: %.2f mm\n\n' ...
                   '**Estimated Focal Length: %.2f px**'], ...
                   pixelWidth, realWidth_mm, distance_mm, focal_px);

    msgbox(msg, 'Focal Length Calibration');

    %% Save to file for reuse (optional)
    save('focal_length_px.mat', 'focal_px');
end
