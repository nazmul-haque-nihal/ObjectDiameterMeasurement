function object_diameter_measurement_gui()
    close all; clc;

    %% Select input source
    choice = questdlg('Select image source:', 'Input Choice', ...
                      'From File', 'From Camera', 'From File');
    if isempty(choice), disp('No option selected.'); return; end

    switch choice
        case 'From File'
            [filenames, pathname] = uigetfile({'*.jpg;*.png;*.bmp;*.tiff', 'Image Files'}, ...
                                              'Select Images', 'MultiSelect', 'on');
            if isequal(filenames, 0), disp('No image selected.'); return; end
            if ischar(filenames), filenames = {filenames}; end
        case 'From Camera'
            hWait = waitbar(0.5, 'Capturing image from camera. Please wait...', ...
                            'Name', 'Capturing', 'WindowStyle', 'modal');
            system('grab.exe');
            if ishandle(hWait), close(hWait); end
            filenames = {'captured_image.jpg'};
            pathname = pwd;
        otherwise
            return;
    end

    numImages = numel(filenames);
    results = {};

    %% Measurement Mode Selection
    mode = questdlg('What do you want to estimate?', 'Measurement Mode', ...
                    'Estimate Diameter (Know Distance)', ...
                    'Estimate Distance (Know Diameter)', ...
                    'Estimate Diameter (Know Distance)');
    if isempty(mode), return; end

    %% GUI for HSV sliders
    hFig = figure('Name', 'HSV Threshold Control', 'NumberTitle', 'on', 'Position', [100 100 500 520]);
    h = addSlider('Hue Min', 0.00, 420); hHueMin = h.s; hHueMinVal = h.val;
    h = addSlider('Hue Max', 1.00, 390); hHueMax = h.s; hHueMaxVal = h.val;
    h = addSlider('Sat Min', 0.4, 360); hSatMin = h.s; hSatMinVal = h.val;
    h = addSlider('Sat Max', 1.0, 330); hSatMax = h.s; hSatMaxVal = h.val;
    h = addSlider('Val Min', 0.3, 300); hValMin = h.s; hValMinVal = h.val;
    h = addSlider('Val Max', 1.0, 270); hValMax = h.s; hValMaxVal = h.val;

    colorAxes = axes('Units', 'pixels', 'Position', [380 330 80 80]);
    updateColorPreview();
    sliders = [hHueMin, hHueMax, hSatMin, hSatMax, hValMin, hValMax];
    addlistener(sliders, 'ContinuousValueChange', @(~,~) updateColorPreview());

    uicontrol('Style', 'pushbutton', 'String', 'Start Processing', ...
              'Position', [150 100 200 40], 'Callback', @processImages);

    %% Slider Utility
    function h = addSlider(label, defaultVal, y)
        uicontrol('Style', 'text', 'Position', [20 y 100 20], 'String', label);
        s = uicontrol('Style', 'slider', 'Position', [130 y 200 20], ...
                      'Min', 0, 'Max', 1, 'Value', defaultVal);
        val = uicontrol('Style', 'text', 'Position', [340 y 30 20], ...
                        'String', num2str(defaultVal, '%.2f'));
        addlistener(s, 'ContinuousValueChange', @(src,~) set(val, 'String', num2str(src.Value, '%.2f')));
        h.s = s; h.val = val;
    end

    %% Color preview box
    function updateColorPreview()
        Hmin = hHueMin.Value; Hmax = hHueMax.Value;
        S = (hSatMin.Value + hSatMax.Value) / 2;
        V = (hValMin.Value + hValMax.Value) / 2;

        if Hmin <= Hmax
            hSample = linspace(Hmin, Hmax, 100);
        else
            hSample = [linspace(Hmin, 1, 50), linspace(0, Hmax, 50)];
        end

        sSample = ones(size(hSample)) * S;
        vSample = ones(size(hSample)) * V;
        hsvSample = cat(3, hSample, sSample, vSample);
        hsvSample = reshape(hsvSample, [1, length(hSample), 3]);
        rgbSample = hsv2rgb(hsvSample);
        image(rgbSample, 'Parent', colorAxes);
        axis(colorAxes, 'off');
    end

%% Process image(s)
function processImages(~, ~)
    results = {};
    for i = 1:numImages
        img = imread(fullfile(pathname, filenames{i}));
        hsvImg = rgb2hsv(img);

        % Get HSV threshold values from sliders
        hMin = hHueMin.Value; hMax = hHueMax.Value;
        sMin = hSatMin.Value; sMax = hSatMax.Value;
        vMin = hValMin.Value; vMax = hValMax.Value;

        % Create mask based on HSV thresholds
        if hMin <= hMax
            hueMask = hsvImg(:,:,1) >= hMin & hsvImg(:,:,1) <= hMax;
        else
            hueMask = hsvImg(:,:,1) >= hMin | hsvImg(:,:,1) <= hMax;
        end
        satMask = hsvImg(:,:,2) >= sMin & hsvImg(:,:,2) <= sMax;
        valMask = hsvImg(:,:,3) >= vMin & hsvImg(:,:,3) <= vMax;
        mask = hueMask & satMask & valMask;
        mask = imfill(mask, 'holes');
        mask = bwareaopen(mask, 1700);
        [labeled, numObjects] = bwlabel(mask);

        if numObjects < 1
            warndlg(sprintf('No objects detected in image: %s', filenames{i}), 'No Objects Found');
            continue;
        end

        props = regionprops(labeled, 'MajorAxisLength', 'MinorAxisLength', 'Centroid', 'BoundingBox');
        [~, sortIdx] = sort([props.MajorAxisLength], 'descend');
        props = props(sortIdx);

        % Prompt user to optionally override the detected object count
        countPrompt = {sprintf('Detected %d object(s). Enter number to use (you can reduce it):', numObjects)};
        countAnswer = inputdlg(countPrompt, 'Confirm Object Count', [1 50], {num2str(numObjects)});
        if isempty(countAnswer), continue; end
        expectedCount = min(str2double(countAnswer{1}), numObjects);
        
        % Prompt for distance or diameter based on mode
        if strcmp(mode, 'Estimate Diameter (Know Distance)')
            knownPrompt = {'Enter distance to object (mm):'};
            knownDef = {'300'};
        else
            knownPrompt = {'Enter real object diameter (mm):'};
            knownDef = {'60'};
        end
        
        knownAnswer = inputdlg(knownPrompt, 'Measurement Parameters', [1 50], knownDef);
        if isempty(knownAnswer), continue; end
        knownValue = str2double(knownAnswer{1});
        
        % Limit the number of measured objects
        if numel(props) > expectedCount
            props = props(1:expectedCount);
        end

        fAnalysis = figure('Name', ['HSV Processing - ', filenames{i}], ...
                           'Position', [50, 50, 900, 600],'NumberTitle', 'off');
        subplot(2,3,1); imshow(img); title('Original');
        subplot(2,3,2); imshow(mask); title('HSV Threshold Mask');
        subplot(2,3,3); imshow(hsvImg(:,:,1)); title('Hue Channel');
        subplot(2,3,4); imshow(hsvImg(:,:,2)); title('Saturation Channel');
        subplot(2,3,5); imshow(hsvImg(:,:,3)); title('Value Channel');
        subplot(2,3,6);
        imshow(img); title('Bounding Boxes with Pixel Dimensions'); hold on;

        for k = 1:numel(props)
            bbox = props(k).BoundingBox;
            width = round(bbox(3));
            height = round(bbox(4));
            rectangle('Position', bbox, 'EdgeColor', 'r', 'LineWidth', 2);
            text(bbox(1), bbox(2)-10, ...
                 sprintf('%dx%d px', width, height), ...
                 'Color', 'yellow', 'FontSize', 9, 'FontWeight', 'bold', ...
                 'BackgroundColor', 'black', 'Margin', 1);
        end

        hold off;

        % Measurement Figure
        figure('Name', ['Measurements - ', filenames{i}], ...
               'Position', [950, 50, 500, 400], 'NumberTitle', 'off');
        imshow(img, 'InitialMagnification', 'fit'); axis tight; hold on;

        for k = 1:numel(props)
            d_pix = mean([props(k).MajorAxisLength, props(k).MinorAxisLength]);

            if strcmp(mode, 'Estimate Diameter (Know Distance)')
                % Estimate real diameter using known distance
                refFOV = max(size(img)); % simplistic FOV-based estimate
                d_mm = d_pix * (knownValue / refFOV);
                d_cm = d_mm / 10;
                estimatedDist = knownValue; % Set known distance directly
                estimatedDist_cm = estimatedDist / 10;
            else
                % Estimate distance using known diameter
                refFOV = max(size(img));
                d_mm = knownValue;
                estimatedDist = (d_mm * refFOV) / d_pix;
                d_cm = d_mm / 10;
                estimatedDist_cm = estimatedDist / 10;
            end

            bbox = props(k).BoundingBox;
            rectangle('Position', bbox, 'EdgeColor', 'g', 'LineWidth', 2);

            if strcmp(mode, 'Estimate Diameter (Know Distance)')
                label = sprintf('%.2f mm', d_mm);
            else
                label = sprintf('Dist: %.1f mm', estimatedDist);
            end

            text(bbox(1)+5, bbox(2)+5, label, ...
                'Color', 'yellow', 'FontSize', 9, 'FontWeight', 'bold');

            % Store both diameter and distance values
            results(end+1,:) = {filenames{i}, sprintf('Object %d', k), ...
                d_pix, d_mm, d_cm, estimatedDist, estimatedDist_cm, mode};
        end
        hold off;
    end

    % Show results in a table
    if ~isempty(results)
        figTable = figure('Name', 'Measurement Results', ...
            'Position', [100, 100, 800, 300], ...
            'NumberTitle', 'off', ...
            'Resize', 'on');

        uitable('Parent', figTable, ...
            'Data', results, ...
            'ColumnName', {'Image','Object ID','Pixel Diameter','Diameter (mm)','Diameter (cm)','Distance (mm)', 'Distance (cm)', 'Mode'}, ...
            'Units', 'normalized', ...
            'Position', [0.02 0.1 0.96 0.85], ...
            'FontSize', 10, ...
            'RowStriping', 'on');

        % Save to CSV with both diameter and distance
        T = cell2table(results, 'VariableNames', ...
            {'Image','ObjectID','PixelDiameter','Diameter_mm','Diameter_cm','Distance_mm', 'Distance_cm', 'Mode'});
        writetable(T, fullfile(pathname, 'measurement_results.csv'));
        msgbox('Results saved as measurement_results.csv', 'Export Complete');
    else
        msgbox('No valid measurements recorded.', 'No Results');
    end
end
end
