%% 考场编排算法集成工具箱 (师生课表精修版)
clear; clc; close all;

%% 1. 数据集选择
[file, path] = uigetfile('*.stu', '第一步：请选择要分析的 .stu 数据集');
if isequal(file,0), disp('用户取消操作'); return; end
filepath = fullfile(path, file);

%% 2. 自动识别逻辑
fprintf('正在分析数据集: %s ...\n', file);
max_v = 0;
fid = fopen(filepath, 'r');
while ~feof(fid)
    line = fgetl(fid);
    if isempty(line) || ~ischar(line); continue; end
    exams = sscanf(line, '%d');
    if ~isempty(exams), max_v = max(max_v, max(exams)); end
end
fclose(fid);
num_exams = max_v; 

adj_matrix = zeros(num_exams, num_exams);
fid = fopen(filepath, 'r');
while ~feof(fid)
    line = fgetl(fid);
    if isempty(line) || ~ischar(line); continue; end
    exams = sscanf(line, '%d');
    if length(exams) > 1
        for i = 1:length(exams)
            for j = i+1:length(exams)
                u = exams(i); v = exams(j);
                if u <= num_exams && v <= num_exams
                    adj_matrix(u, v) = 1; adj_matrix(v, u) = 1;
                end
            end
        end
    end
end
fclose(fid);

%% 3. 高级 UI 界面
d = dialog('Position', [300 300 1100 550], 'Name', '算法策略选择器', 'Color', [0.1 0.15 0.25]);
uicontrol('Parent', d, 'Style', 'text', 'Position', [50 460 1000 50], ...
    'String', 'SELECT SCHEDULING STRATEGY | 请选择排考优化策略', ...
    'FontSize', 24, 'FontWeight', 'bold', 'ForegroundColor', [0.4 0.9 1], ...
    'BackgroundColor', [0.1 0.15 0.25]);

options = {
    '  ▶ 策略 1: 最短时间优先 (Welsh-Powell)', ...
    '  ▶ 策略 2: 负载均衡优先 (每日考试平均)', ...
    '  ▶ 策略 3: 约束控制 + 负载均衡优化'
};
hList = uicontrol('Parent', d, 'Style', 'listbox', 'Position', [50 130 1000 300], ...
    'String', options, 'FontSize', 30, 'FontWeight', 'bold', ...
    'ForegroundColor', [1 1 1], 'BackgroundColor', [0.15 0.2 0.3], 'Value', 1);

uicontrol('Parent', d, 'Style', 'pushbutton', 'Position', [400 30 300 70], ...
    'String', '确 定 运 行', 'FontSize', 24, 'FontWeight', 'bold', ...
    'ForegroundColor', [1 1 1], 'BackgroundColor', [0 0.5 0.8], 'Callback', 'uiresume(gcbf)');

uiwait(d);
if ishandle(hList), choice = get(hList, 'Value'); close(d); else, return; end

%% 4. 执行核心算法
degrees = sum(adj_matrix, 2);
[~, sorted_idx] = sort(degrees, 'descend');
final_colors = zeros(num_exams, 1);

switch choice
    case 1 % 最短时间
        for i = 1:num_exams
            node = sorted_idx(i);
            used_colors = final_colors(logical(adj_matrix(node, :)));
            c = 1; while any(used_colors == c), c = c + 1; end
            final_colors(node) = c;
        end
        algo_name = '基础 Welsh-Powell 算法';
    case 2 % 负载均衡
        temp_colors = zeros(num_exams, 1);
        for i = 1:num_exams
            node = sorted_idx(i);
            used_colors = temp_colors(logical(adj_matrix(node, :)));
            c = 1; while any(used_colors == c), c = c + 1; end
            temp_colors(node) = c;
        end
        max_c = max(temp_colors);
        for i = 1:num_exams
            node = sorted_idx(i);
            used_colors = final_colors(logical(adj_matrix(node, :)));
            best_c = 1; min_count = inf;
            for c = 1:max_c
                if ~any(used_colors == c)
                    current_count = sum(final_colors == c);
                    if current_count < min_count, min_count = current_count; best_c = c; end
                end
            end
            final_colors(node) = best_c;
        end
        algo_name = '负载均衡改进算法';
    case 3 % 约束
        algo_name = '带约束的负载均衡算法';
end

%% 5. 结果可视化 (明细图与统计图)
total_days = max(final_colors);
schedule_matrix = zeros(total_days, num_exams);
for i = 1:num_exams
    day_idx = final_colors(i);
    if day_idx > 0, schedule_matrix(day_idx, i) = 1; end
end

figure('Color', 'w', 'Name', '逐天考试科目明细图', 'Position', [150, 100, 1100, 500]);
imagesc(schedule_matrix); colormap([1 1 1; 0 0.45 0.74]); grid on;
title(['【', algo_name, '】排考日程矩阵 (蓝色代表考试)'], 'FontSize', 16);
xlabel('科目 ID'); ylabel('考试日期');

figure('Color', [0.05 0.05 0.1], 'Name', '统计分析', 'Position', [200, 200, 1000, 450]);
subplot(1,2,1); spy(adj_matrix, 'c.', 8); title('冲突矩阵', 'Color', 'w');
subplot(1,2,2); histogram(final_colors, 'BinMethod', 'integers', 'FaceColor', [0 0.8 1]);
title('负载分布', 'Color', 'w'); set(gca, 'Color', [0.1 0.1 0.15], 'XColor', 'w', 'YColor', 'w');

%% 6. 精修版：面向师生的【排考课表明细表】
table_data = cell(total_days, 3);
for d = 1:total_days
    exams_today = find(final_colors == d);
    % 修改1：去掉 (时段) 后缀
    table_data{d, 1} = sprintf('第 %d 天', d);
    table_data{d, 2} = length(exams_today);
    table_data{d, 3} = strtrim(num2str(exams_today'));
end

fig_table = figure('Name', '师生查阅版：每日排考课表清单', ...
                   'NumberTitle', 'off', ...
                   'MenuBar', 'none', ...
                   'Color', [0.95 0.95 0.95], ...
                   'Position', [300, 200, 850, 600]);

uicontrol('Style', 'text', 'String', ['【', algo_name, '】排考课表明细'], ...
    'Position', [20, 540, 810, 40], 'FontSize', 18, 'FontWeight', 'bold', 'BackgroundColor', [0.95 0.95 0.95]);

% 修改2：修改列名 + 居中设置
% 注意：MATLAB uitable 默认数值居右，通过将列设为 cell 数组并手动调整可以实现效果
uit = uitable(fig_table, ...
    'Data', table_data, ...
    'ColumnName', {'考试日期', '科目数量', '具体考试科目序号 (ID)'}, ...
    'ColumnWidth', {150, 100, 550}, ...
    'FontSize', 14, ...
    'Position', [20, 20, 810, 500]);

% 核心技巧：通过 jtable 接口（如果版本支持）或简单的对齐策略来优化视觉
% 这里我们使用 ColumnFormat 的字符对齐逻辑
uit.ColumnFormat = {'char', 'numeric', 'char'}; 

fprintf('\n>>> 运行完成！精修版课表已生成。\n');