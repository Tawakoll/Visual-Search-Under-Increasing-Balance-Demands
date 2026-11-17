%% Load data from each participant
clear all; clc; close all;
dataPath = './Team9';

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

%% Visualize Individual Trials: Time-Series and AP-ML Ellipses
dt = 0.033; % Time step in seconds based on 33ms sampling
chi_val = 5.991; % Chi-square scale factor for 95% confidence (2 DOF)
chi_sqrt = sqrt(chi_val); % Approx 2.4478
for p = 1:length(allData)
    participantName = allData(p).ParticipantID;
    
    % ==========================================
    % 1. DETERMINE GLOBAL LIMITS FOR NORMALIZATION
    % ==========================================
    max_acc = 0;
    max_time = 0;
    all_trials = [allData(p).EC_Data, allData(p).EO_Data];
    
    for i = 1:length(all_trials)
        data = all_trials{i};
        ml_c = data.acc_ml - mean(data.acc_ml);
        ap_c = data.acc_ap - mean(data.acc_ap);
        t_sec = data.t_ms / 1000;
        
        % Find the absolute maximum acceleration across AP and ML
        max_acc = max([max_acc, max(abs(ml_c)), max(abs(ap_c))]);
        max_time = max([max_time, max(t_sec)]);
    end
    
    % Add a 10% padding buffer to the axis limits for clean plotting
    max_acc = max_acc * 1.1; 
    
    % ==========================================
    % 2. PLOT 1: ACCELERATION OSCILLATIONS OVER TIME
    % ==========================================
    figure('Name', sprintf('Time-Series Oscillations: Participant %s', participantName), ...
           'Position', [50, 450, 1400, 400]);
    
    % EC Trials (Top Row)
    for i = 1:length(allData(p).EC_Data)
        subplot(2, 3, i); hold on; grid on;
        data = allData(p).EC_Data{i};
        t_sec = data.t_ms / 1000;
        
        plot(t_sec, data.acc_ml - mean(data.acc_ml), 'r', 'LineWidth', 1);
        plot(t_sec, data.acc_ap - mean(data.acc_ap), 'b', 'LineWidth', 1);
        
        ylim([-max_acc, max_acc]); xlim([0, max_time]);
        title(sprintf('EC Trial %d', i));
        xlabel('Time (s)'); ylabel('Acceleration');
        if i == 1, legend('ML Accel', 'AP Accel', 'Location', 'best'); end
    end
    
    % EO Trials (Bottom Row)
    for i = 1:length(allData(p).EO_Data)
        subplot(2, 3, i + 3); hold on; grid on;
        data = allData(p).EO_Data{i};
        t_sec = data.t_ms / 1000;
        
        plot(t_sec, data.acc_ml - mean(data.acc_ml), 'r', 'LineWidth', 1);
        plot(t_sec, data.acc_ap - mean(data.acc_ap), 'b', 'LineWidth', 1);
        
        ylim([-max_acc, max_acc]); xlim([0, max_time]);
        title(sprintf('EO Trial %d', i));
        xlabel('Time (s)'); ylabel('Acceleration');
    end
    sgtitle(sprintf('Acceleration Oscillations: Participant %s', participantName), 'FontSize', 14, 'FontWeight', 'bold');
    
    % ==========================================
    % 3. PLOT 2: AP-ML DISTRIBUTION & 95% ELLIPSES
    % ==========================================
    figure('Name', sprintf('AP-ML Distributions: Participant %s', participantName), ...
           'Position', [50, 50, 1400, 800]);
    
    % EC Trials (Top Row)
    for i = 1:length(allData(p).EC_Data)
        subplot(2, 3, i); hold on; grid on; axis equal;
        data = allData(p).EC_Data{i};
        
        ml_c = data.acc_ml - mean(data.acc_ml);
        ap_c = data.acc_ap - mean(data.acc_ap);
        
        scatter(ml_c, ap_c, 10, 'r', 'filled', 'MarkerFaceAlpha', 0.5);
        
        C = cov(ml_c, ap_c);
        [eigVec, eigVal] = eig(C);
        
        ec_area = pi * chi_val * sqrt(eigVal(1,1) * eigVal(2,2));
        
        theta = linspace(0, 2*pi, 100);
        ellipse_pts = eigVec * (chi_sqrt * sqrt(eigVal) * [cos(theta); sin(theta)]);
        plot(ellipse_pts(1,:), ellipse_pts(2,:), 'k-', 'LineWidth', 1.5);
        
        d_ml = diff(data.acc_ml) / dt;
        d_ap = diff(data.acc_ap) / dt;
        ec_jerk = 0.5 * sum((d_ap.^2 + d_ml.^2) * dt);
        
        rms_ml = sqrt(sum(ml_c.^2) / length(ml_c));
        rms_ap = sqrt(sum(ap_c.^2) / length(ap_c));
        
        % Normalize limits
        xlim([-max_acc, max_acc]); ylim([-max_acc, max_acc]);
        
        title(sprintf('EC Trial %d\nArea: %.4f | JERK: %.4f\nRMS ML: %.4f | RMS AP: %.4f', ...
            i, ec_area, ec_jerk, rms_ml, rms_ap));
        xlabel('ML Acceleration'); 
        if i == 1, ylabel('AP Acceleration'); end
    end
    
    % EO Trials (Bottom Row)
    for i = 1:length(allData(p).EO_Data)
        subplot(2, 3, i + 3); hold on; grid on; axis equal;
        data = allData(p).EO_Data{i};
        
        ml_c = data.acc_ml - mean(data.acc_ml);
        ap_c = data.acc_ap - mean(data.acc_ap);
        
        scatter(ml_c, ap_c, 10, 'b', 'filled', 'MarkerFaceAlpha', 0.5);
        
        C = cov(ml_c, ap_c);
        [eigVec, eigVal] = eig(C);
        
        eo_area = pi * chi_val * sqrt(eigVal(1,1) * eigVal(2,2));
        
        theta = linspace(0, 2*pi, 100);
        ellipse_pts = eigVec * (chi_sqrt * sqrt(eigVal) * [cos(theta); sin(theta)]);
        plot(ellipse_pts(1,:), ellipse_pts(2,:), 'k-', 'LineWidth', 1.5);
        
        d_ml = diff(data.acc_ml) / dt;
        d_ap = diff(data.acc_ap) / dt;
        eo_jerk = 0.5 * sum((d_ap.^2 + d_ml.^2) * dt);
        
        rms_ml = sqrt(sum(ml_c.^2) / length(ml_c));
        rms_ap = sqrt(sum(ap_c.^2) / length(ap_c));
        
        % Normalize limits
        xlim([-max_acc, max_acc]); ylim([-max_acc, max_acc]);
        
        title(sprintf('EO Trial %d\nArea: %.4f | JERK: %.4f\nRMS ML: %.4f | RMS AP: %.4f', ...
            i, eo_area, eo_jerk, rms_ml, rms_ap));
        xlabel('ML Acceleration'); 
        if i == 1, ylabel('AP Acceleration'); end
    end
    
    sgtitle(sprintf('AP-ML 95%% Confidence Ellipses & Metrics: Participant %s', participantName), ...
        'FontSize', 14, 'FontWeight', 'bold');
end
