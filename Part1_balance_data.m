%% Load data from each participant
clear all; clc; close all;
dataPath = './Assignment1_data/Team9';

% 1. Get a list of all items, filter for directories, and remove '.' and '..'
participants = dir(dataPath);
participants = participants([participants.isdir] & ~ismember({participants.name}, {'.', '..'}));

% Initialize a structure array to hold all organized data
allData = struct();

% 2. Loop through each participant folder
for p = 1:length(participants)
    participantName = participants(p).name;
    participantFolder = fullfile(dataPath, participantName);
    
    % 3. Find files containing 'EC' and 'EO' in their names
    ecFiles = dir(fullfile(participantFolder, '*EC*.csv'));
    eoFiles = dir(fullfile(participantFolder, '*EO*.csv'));
    
    % 4. Read the EC files using readtable
    ecTables = cell(1, length(ecFiles)); % Pre-allocate cell array
    for i = 1:length(ecFiles)
        filePath = fullfile(participantFolder, ecFiles(i).name);
        ecTables{i} = readtable(filePath);
    end
    
    % 5. Read the EO files using readtable
    eoTables = cell(1, length(eoFiles));
    for i = 1:length(eoFiles)
        filePath = fullfile(participantFolder, eoFiles(i).name);
        eoTables{i} = readtable(filePath);
    end
    
    % 6. Store everything neatly in the structure
    allData(p).ParticipantID = participantName;
    allData(p).EC_Data = ecTables;
    allData(p).EO_Data = eoTables;
    
    % Print progress to the command window
    fprintf('Loaded data for %s: %d EC files, %d EO files.\n', participantName, length(ecFiles), length(eoFiles));

end

%% Visualize Mean AP and ML Accelerations with Error Cylinders
% Approximate time step based on your sample (33ms = 0.033s)
dt = 0.033; 

for p = 1:length(allData)
    participantName = allData(p).ParticipantID;
    figure('Name', sprintf('Participant %s (Mean ± SD)', participantName), 'Position', [100, 100, 900, 600]);
    
    % ==========================================
    % 1. ALIGN AND AVERAGE EYES CLOSED (EC) DATA
    % ==========================================
    % Find the overlapping time window for all EC trials
    min_t_ec = 0; max_t_ec = inf;
    num_ec = length(allData(p).EC_Data);
    for i = 1:num_ec
        t_curr = allData(p).EC_Data{i}.t_ms / 1000;
        min_t_ec = max(min_t_ec, min(t_curr));
        max_t_ec = min(max_t_ec, max(t_curr));
    end
    t_ec = (min_t_ec : dt : max_t_ec)'; % Shared time vector
    
    % Interpolate data onto the shared time vector
    ec_ml_all = zeros(length(t_ec), num_ec);
    ec_ap_all = zeros(length(t_ec), num_ec);
    for i = 1:num_ec
        t_curr = allData(p).EC_Data{i}.t_ms / 1000;
        ec_ml_all(:, i) = interp1(t_curr, allData(p).EC_Data{i}.acc_ml, t_ec, 'linear');
        ec_ap_all(:, i) = interp1(t_curr, allData(p).EC_Data{i}.acc_ap, t_ec, 'linear');
    end
    
    % Calculate Mean and Standard Deviation across columns (dimension 2)
    ec_ml_mean = mean(ec_ml_all, 2); ec_ml_std = std(ec_ml_all, 0, 2);
    ec_ap_mean = mean(ec_ap_all, 2); ec_ap_std = std(ec_ap_all, 0, 2);

    % ==========================================
    % 2. ALIGN AND AVERAGE EYES OPEN (EO) DATA
    % ==========================================
    min_t_eo = 0; max_t_eo = inf;
    num_eo = length(allData(p).EO_Data);
    for i = 1:num_eo
        t_curr = allData(p).EO_Data{i}.t_ms / 1000;
        min_t_eo = max(min_t_eo, min(t_curr));
        max_t_eo = min(max_t_eo, max(t_curr));
    end
    t_eo = (min_t_eo : dt : max_t_eo)';
    
    eo_ml_all = zeros(length(t_eo), num_eo);
    eo_ap_all = zeros(length(t_eo), num_eo);
    for i = 1:num_eo
        t_curr = allData(p).EO_Data{i}.t_ms / 1000;
        eo_ml_all(:, i) = interp1(t_curr, allData(p).EO_Data{i}.acc_ml, t_eo, 'linear');
        eo_ap_all(:, i) = interp1(t_curr, allData(p).EO_Data{i}.acc_ap, t_eo, 'linear');
    end
    
    eo_ml_mean = mean(eo_ml_all, 2); eo_ml_std = std(eo_ml_all, 0, 2);
    eo_ap_mean = mean(eo_ap_all, 2); eo_ap_std = std(eo_ap_all, 0, 2);

    % ==========================================
    % 3. PLOTTING
    % ==========================================
    
    %% Subplot 1: ML Acceleration
    subplot(2, 1, 1); hold on; grid on;
    % Plot EC Error Cylinder (Red)
    fill([t_ec; flipud(t_ec)], [ec_ml_mean + ec_ml_std; flipud(ec_ml_mean - ec_ml_std)], ...
        'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    p_ec = plot(t_ec, ec_ml_mean, 'r', 'LineWidth', 1.5);
    
    % Plot EO Error Cylinder (Blue)
    fill([t_eo; flipud(t_eo)], [eo_ml_mean + eo_ml_std; flipud(eo_ml_mean - eo_ml_std)], ...
        'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    p_eo = plot(t_eo, eo_ml_mean, 'b', 'LineWidth', 1.5);
    
    title('Medio-Lateral (ML) Acceleration (Mean \pm 1 SD)');
    xlabel('Time (seconds)'); ylabel('Acceleration');
    legend([p_ec, p_eo], {'Eyes Closed (Mean)', 'Eyes Open (Mean)'}, 'Location', 'best');
    
    %% Subplot 2: AP Acceleration
    subplot(2, 1, 2); hold on; grid on;
    % Plot EC Error Cylinder (Red)
    fill([t_ec; flipud(t_ec)], [ec_ap_mean + ec_ap_std; flipud(ec_ap_mean - ec_ap_std)], ...
        'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    plot(t_ec, ec_ap_mean, 'r', 'LineWidth', 1.5);
    
    % Plot EO Error Cylinder (Blue)
    fill([t_eo; flipud(t_eo)], [eo_ap_mean + eo_ap_std; flipud(eo_ap_mean - eo_ap_std)], ...
        'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    plot(t_eo, eo_ap_mean, 'b', 'LineWidth', 1.5);
    
    title('Anterior-Posterior (AP) Acceleration (Mean \pm 1 SD)');
    xlabel('Time (seconds)'); ylabel('Acceleration');
    
    sgtitle(sprintf('Postural Sway Comparison: Participant %s', participantName), 'FontSize', 14, 'FontWeight', 'bold');
end

%% Analyze Individual Trials: 95% Ellipse Area, JERK, and RMS in Subplots
dt = 0.033; % Time step in seconds based on 33ms sampling
chi_val = 5.991; % Chi-square scale factor for 95% confidence (2 DOF)
chi_sqrt = sqrt(chi_val); % Approx 2.4478

for p = 1:length(allData)
    participantName = allData(p).ParticipantID;
    
    % Create a large figure for the 2x3 subplot grid
    figure('Name', sprintf('Individual Trials: Participant %s', participantName), ...
           'Position', [50, 50, 1400, 800]);
    
    %% Top Row: Eyes Closed (EC) Trials
    for i = 1:length(allData(p).EC_Data)
        subplot(2, 3, i); 
        hold on; grid on; axis equal;
        
        data = allData(p).EC_Data{i};
        
        % Center the data
        ml_c = data.acc_ml - mean(data.acc_ml);
        ap_c = data.acc_ap - mean(data.acc_ap);
        
        % Plot the raw distribution
        scatter(ml_c, ap_c, 10, 'r', 'filled', 'MarkerFaceAlpha', 0.5);
        
        % Calculate Covariance and Eigenvalues
        C = cov(ml_c, ap_c);
        [eigVec, eigVal] = eig(C);
        
        % Calculate 95% Ellipse Area
        ec_area = pi * chi_val * sqrt(eigVal(1,1) * eigVal(2,2));
        
        % Draw the 95% Ellipse
        theta = linspace(0, 2*pi, 100);
        ellipse_pts = eigVec * (chi_sqrt * sqrt(eigVal) * [cos(theta); sin(theta)]);
        plot(ellipse_pts(1,:), ellipse_pts(2,:), 'k-', 'LineWidth', 1.5);
        
        % Calculate JERK
        d_ml = diff(data.acc_ml) / dt;
        d_ap = diff(data.acc_ap) / dt;
        ec_jerk = 0.5 * sum((d_ap.^2 + d_ml.^2) * dt); 
        
        % Calculate Root Mean Square (RMS) for centered data
        rms_ml = sqrt(sum(ml_c.^2) / length(ml_c));
        rms_ap = sqrt(sum(ap_c.^2) / length(ap_c));
        
        % Formatting
        title(sprintf('EC Trial %d\nArea: %.4f | JERK: %.4f\nRMS ML: %.4f | RMS AP: %.4f', ...
            i, ec_area, ec_jerk, rms_ml, rms_ap));
        xlabel('ML Acceleration'); 
        if i == 1, ylabel('AP Acceleration'); end
    end
    
    %% Bottom Row: Eyes Open (EO) Trials
    for i = 1:length(allData(p).EO_Data)
        subplot(2, 3, i + 3); % i+3 places these in the second row
        hold on; grid on; axis equal;
        
        data = allData(p).EO_Data{i};
        
        % Center the data
        ml_c = data.acc_ml - mean(data.acc_ml);
        ap_c = data.acc_ap - mean(data.acc_ap);
        
        % Plot the raw distribution
        scatter(ml_c, ap_c, 10, 'b', 'filled', 'MarkerFaceAlpha', 0.5);
        
        % Calculate Covariance and Eigenvalues
        C = cov(ml_c, ap_c);
        [eigVec, eigVal] = eig(C);
        
        % Calculate 95% Ellipse Area
        eo_area = pi * chi_val * sqrt(eigVal(1,1) * eigVal(2,2));
        
        % Draw the 95% Ellipse
        theta = linspace(0, 2*pi, 100);
        ellipse_pts = eigVec * (chi_sqrt * sqrt(eigVal) * [cos(theta); sin(theta)]);
        plot(ellipse_pts(1,:), ellipse_pts(2,:), 'k-', 'LineWidth', 1.5);
        
        % Calculate JERK
        d_ml = diff(data.acc_ml) / dt;
        d_ap = diff(data.acc_ap) / dt;
        eo_jerk = 0.5 * sum((d_ap.^2 + d_ml.^2) * dt);
        
        % Calculate Root Mean Square (RMS) for centered data
        rms_ml = sqrt(sum(ml_c.^2) / length(ml_c));
        rms_ap = sqrt(sum(ap_c.^2) / length(ap_c));
        
        % Formatting
        title(sprintf('EO Trial %d\nArea: %.4f | JERK: %.4f\nRMS ML: %.4f | RMS AP: %.4f', ...
            i, eo_area, eo_jerk, rms_ml, rms_ap));
        xlabel('ML Acceleration'); 
        if i == 1, ylabel('AP Acceleration'); end
    end
    
    sgtitle(sprintf('AP-ML 95%% Confidence Ellipses & Metrics: Participant %s', participantName), ...
        'FontSize', 14, 'FontWeight', 'bold');
end