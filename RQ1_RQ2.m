clear all; clc; close all;

BELL_TEST_folder = '.\BELL_TEST';

fileList = dir(BELL_TEST_folder);

%part2
% RQ1 – Cognitive Acquisition 
% How does concurrent postural demand affect the acquisition of a novel cognitive task? 
% Investigate changes in cognitive performance across the learning trials of Groups A and B. 
% • Plot cognitive performance as a function of trial number. 
% • Compare the evolution of performance between the two learning conditions. 
% • Compare cognitive performance in the stable-standing pre-test and post-test for Groups A 
% and B, before and after their respective training phases

% RQ2 – Prior Learning and Learning Context 
% How do prior cognitive learning and the context in which the task is learned affect subsequent 
% dual-task performance? 
% Compare the performance of Groups A, B, and C during the first common dual-task trial on the 
% wobble board. 
% • Visualize and compare the cognitive performance across the three groups and interpret 
% potential differences in relation to prior training and learning context. 

%1. loop the subjects 1: 29

opts = detectImportOptions('participants.csv');
  opts.DataLines = [2, inf];
  participantsData = readtable('participants.csv', opts);
subjectFolders = dir(fullfile(BELL_TEST_folder, 'S*'));
subjectFolders = subjectFolders([subjectFolders.isdir]);

allSubjectData = cell(length(subjectFolders), 1);

for i = 1:length(subjectFolders)
    filePath = fullfile(subjectFolders(i).folder, subjectFolders(i).name, 'bell_Scores.CSV');
    
    if isfile(filePath)
        allSubjectData{i} = readtable(filePath);
    end
end
%2. subjects as a tables , access each  bell test score
participantsData.Index = (1:height(participantsData))';

group_A = participantsData(strcmp(participantsData.Group, 'A'), {'Index', 'Participant_ID'});
group_B = participantsData(strcmp(participantsData.Group, 'B'), {'Index', 'Participant_ID'});
group_C = participantsData(strcmp(participantsData.Group, 'C'), {'Index', 'Participant_ID'});

%3. find mean, std deviation of bell performance for each group A,B
numTrials_A = height(allSubjectData{group_A.Index(1)});
perf_A = zeros(height(group_A), numTrials_A);
for i = 1:height(group_A)
    data = allSubjectData{group_A.Index(i)}.N_Bells_40s';
    data(isnan(data)) = 0;
    perf_A(i, :) = data;
end

numTrials_B = height(allSubjectData{group_B.Index(1)});
perf_B = zeros(height(group_B), numTrials_B);
for i = 1:height(group_B)
    data = allSubjectData{group_B.Index(i)}.N_Bells_40s';
    data(isnan(data)) = 0;
    perf_B(i, :) = data;
end

numTrials_C = height(allSubjectData{group_C.Index(1)});
perf_C = zeros(height(group_C), numTrials_C);
for i = 1:height(group_C)
    data = allSubjectData{group_C.Index(i)}.N_Bells_40s';
    data(isnan(data)) = 0;
    perf_C(i, :) = data;
end

mean_A = mean(perf_A, 1);
std_A  = std(perf_A, 0, 1);

mean_B = mean(perf_B, 1);
std_B  = std(perf_B, 0, 1);

mean_C = mean(perf_C, 1);
std_C  = std(perf_C, 0, 1);


%plot trials comparison

figure; hold on; grid on;

errorbar(1:numTrials_A, mean_A, std_A, '-o', 'LineWidth', 1.5, 'DisplayName', 'Group A');
errorbar(1:numTrials_B, mean_B, std_B, '-s', 'LineWidth', 1.5, 'DisplayName', 'Group B');

trials_C = 13:(12+numTrials_C);
errorbar(trials_C, mean_C, std_C, '-d', 'LineWidth', 1.5, 'DisplayName', 'Group C');

plot([1, 1], [mean_A(1), mean_B(1)], 'p', 'MarkerSize', 12, 'LineStyle', 'none', ...
    'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k', 'DisplayName', 'Pre-learning (Trial 1)');

plot([12, 12], [mean_A(12), mean_B(12)], 'p', 'MarkerSize', 12, 'LineStyle', 'none', ...
    'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'DisplayName', 'Post-learning (Trial 12)');

plot([13, 13, 13], [mean_A(13), mean_B(13), mean_C(1)], 'p', 'MarkerSize', 13, 'LineStyle', 'none', ...
    'MarkerFaceColor', 'c', 'MarkerEdgeColor', 'k', 'DisplayName', 'first common task ''WB''');

plot([18, 18, 18], [mean_A(18), mean_B(18), mean_C(end)], 'p', 'MarkerSize', 12, 'LineStyle', 'none', ...
    'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'k', 'DisplayName', 'last common task ''WB''');

xline(1, '--k', 'HandleVisibility', 'off');
xline(12, '--k', 'HandleVisibility', 'off');
xline(13, '--k', 'HandleVisibility', 'off');
xline(18, '--k', 'HandleVisibility', 'off');

xticks(1:max([numTrials_A, numTrials_B, 12+numTrials_C]));
xlabel('Trial Number');
ylabel('Number of Bells (40s)');
title('Cognitive Performance Across Trials (Mean \pm STD)');
legend('Location', 'best');
hold off;


learning_rate_A = (mean_A(12) - mean_A(1)) / mean_A(1) * 100;
learning_rate_B = (mean_B(12) - mean_B(1)) / mean_B(1) * 100;
learning_rate_c =((mean_C(end)-mean_C(1))/mean_C(1))*100;
fprintf('Learning Rate A (Trial 1->12): %.2f%%\n', learning_rate_A);
fprintf('Learning Rate B (Trial 1->12): %.2f%%\n', learning_rate_B);
fprintf('Improvement Rate C (Trial 1->6): %.2f%%\n', learning_rate_c);


fprintf('\nRQ1: Standing Pre-test vs Post-test\n');
fprintf('Trial 1  (Pre):  A=%.2f  B=%.2f\n', mean_A(1), mean_B(1));
fprintf('Trial 12 (Post): A=%.2f  B=%.2f\n', mean_A(12), mean_B(12));

fprintf('\nRQ2: Common wobble board "WB" Trials\n');
fprintf('Trial 13 (First WB): A=%.2f  B=%.2f  C=%.2f\n', mean_A(13), mean_B(13), mean_C(1));
fprintf('Trial 18 (Last WB):  A=%.2f  B=%.2f  C=%.2f\n', mean_A(18), mean_B(18), mean_C(end));
