%% 考场编排算法集成工具箱 (学术全白黑字终极版)
clear; clc; close all;

%% 1. 数据集选择
[file, path] = uigetfile('*.stu', '第一步：请选择要分析的 .stu 数据集');
if isequal(file,0), disp('用户取消操作'); return; end
filepath = fullfile(path, file);

%% 2. 核心数据解析与人数统计
fprintf('正在分析数据集: %s ...\n', file);
max_v = 0;
exam_counts = containers.Map('KeyType', 'int32', 'ValueType', 'int32'); 

fid = fopen(filepath, 'r');
while ~feof(fid)
    line = fgetl(fid);
    if isempty(line) || ~ischar(line); continue; end
    exams = sscanf(line, '%d');
    if ~isempty(exams)
        max_v = max(max_v, max(exams));
        for k = 1:length(exams)
            id = exams(k);
            if isKey(exam_counts, id)
                exam_counts(id) = exam_counts(id) + 1;
            else
                exam_counts(id) = 1;
            end
        end
    end
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

%% 3. 策略选择界面 (白底黑字)
d = dialog('Position', [300 300 1100 550], 'Name', '算法策略选择器', 'Color', 'w');
uicontrol('Parent', d, 'Style', 'text', 'Position', [50 460 1000 50], ...
    'String', 'SELECT SCHEDULING STRATEGY | 请选择排考优化策略', ...
    'FontSize', 24, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'ForegroundColor', 'k');

options = {'  ▶ 策略 1: 最短时间优先 (Welsh-Powell)', ...
           '  ▶ 策略 2: 负载均衡优先 (每日考试平均)', ...
           '  ▶ 策略 3: 带约束的负载均衡优化'};
hList = uicontrol('Parent', d, 'Style', 'listbox', 'Position', [50 130 1000 300], ...
    'String', options, 'FontSize', 30, 'FontWeight', 'bold', ...
    'BackgroundColor', 'w', 'ForegroundColor', 'k', 'Value', 1);

uicontrol('Parent', d, 'Style', 'pushbutton', 'Position', [400 30 300 70], ...
    'String', '确 定 运 行', 'FontSize', 24, 'FontWeight', 'bold', ...
    'ForegroundColor', 'w', 'BackgroundColor', [0.2 0.4 0.7], 'Callback', 'uiresume(gcbf)');

uiwait(d);
if ishandle(hList), choice = get(hList, 'Value'); close(d); else, return; end

%% 4. 算法执行逻辑
degrees = sum(adj_matrix, 2);
[~, sorted_idx] = sort(degrees, 'descend');
final_colors = zeros(num_exams, 1);

switch choice
    case 1 % Welsh-Powell
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
    case 3 % 带约束
        % 特殊科目后置约束：这些科目必须安排在 time_threshold 之后。
        time_threshold = 5;
        special_exams = [4, 103];
        special_exams = special_exams(special_exams >= 1 & special_exams <= num_exams);

        temp_colors = zeros(num_exams, 1);
        for i = 1:num_exams
            node = sorted_idx(i);
            used_colors = temp_colors(logical(adj_matrix(node, :)));
            c = 1; while any(used_colors == c), c = c + 1; end
            temp_colors(node) = c;
        end
        max_c = max(max(temp_colors), time_threshold + 1);

        normal_idx = sorted_idx(~ismember(sorted_idx, special_exams));
        special_idx = sorted_idx(ismember(sorted_idx, special_exams));
        constrained_order = [special_idx; normal_idx];

        for i = 1:length(constrained_order)
            node = constrained_order(i);
            used_colors = final_colors(logical(adj_matrix(node, :)));

            if ismember(node, special_exams)
                candidate_colors = (time_threshold + 1):max_c;
            else
                candidate_colors = 1:max_c;
            end

            best_c = -1;
            min_count = inf;
            for c = candidate_colors
                if ~any(used_colors == c)
                    current_count = sum(final_colors == c);
                    if current_count < min_count
                        min_count = current_count;
                        best_c = c;
                    end
                end
            end

            if best_c == -1
                max_c = max_c + 1;
                best_c = max_c;
                if ismember(node, special_exams) && best_c <= time_threshold
                    best_c = time_threshold + 1;
                    max_c = best_c;
                end
            end
            final_colors(node) = best_c;
        end
        algo_name = '带约束的负载均衡优化';
end

%% 5. 教室容量分配
% 第一列为教室编号，第二列为容纳人数
room_resources = [
    101, 30; 
    102, 30; 
    201, 50; 
    202, 50; 
    301, 80; 
    302, 80; 
    401, 120;
    % 以下为新增教室，以满足 sta-f-83 等大容量科目的需求
    402, 120;
    501, 250;  % 满足 ear 和 yor 的最大单科需求
    502, 300;
    503, 500   % 必须有一个 > 442 的教室来安排 sta 数据集中的最大科目
];
total_days = max(final_colors);
room_assignment_log = {}; 

for d = 1:total_days
    exams_today = find(final_colors == d);
    today_pop = [];
    for k = 1:length(exams_today)
        id = exams_today(k);
        today_pop = [today_pop; id, exam_counts(id)];
    end
    today_pop = sortrows(today_pop, -2);
    current_rooms = room_resources; 
    for j = 1:size(today_pop, 1)
        exam_id = today_pop(j,1); st_count = today_pop(j,2); assigned = false;
        for r = 1:size(current_rooms, 1)
            if current_rooms(r, 2) >= st_count
                room_assignment_log{end+1, 1} = sprintf('第 %d 天', d);
                room_assignment_log{end, 2} = exam_id;
                room_assignment_log{end, 3} = st_count;
                room_assignment_log{end, 4} = current_rooms(r, 1);
                current_rooms(r, 2) = current_rooms(r, 2) - st_count; assigned = true; break;
            end
        end
        if ~assigned
            room_assignment_log{end+1, 1} = sprintf('第 %d 天', d);
            room_assignment_log{end, 2} = exam_id;
            room_assignment_log{end, 3} = st_count;
            room_assignment_log{end, 4} = '需增开临时考场';
        end
    end
end

%% 6. 强制学术可视化
figure('Name', '统计分析', 'Color', 'w', 'Position', [200, 200, 1000, 400]);
subplot(1,2,1); spy(adj_matrix, 'b.', 8); 
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'Box', 'on');
title('冲突矩阵稀疏图', 'Color', 'k');
subplot(1,2,2); histogram(final_colors, 'BinMethod', 'integers', 'FaceColor', [0.2 0.4 0.7], 'EdgeColor', 'w');
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'Box', 'on');
title('各时段负载分布', 'Color', 'k');
xlabel('考试天数'); ylabel('科目数量');

figure('Name', '排考日程明细图', 'Color', 'w', 'Position', [150, 100, 1100, 400]);
schedule_matrix = zeros(total_days, num_exams);
for i = 1:num_exams
    day_idx = final_colors(i);
    if day_idx > 0, schedule_matrix(day_idx, i) = 1; end
end
imagesc(schedule_matrix); colormap([1 1 1; 0.2 0.4 0.7]); grid on;
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridColor', [0.8 0.8 0.8]);
title(['【', algo_name, '】排考日程矩阵'], 'FontSize', 14, 'Color', 'k');
xlabel('科目 ID'); ylabel('考试日期');

fig_table = figure('Name', '排考及考场分配清单', 'Color', 'w', 'MenuBar', 'none', 'Position', [300, 150, 950, 650]);
uicontrol('Style', 'text', 'String', ['【', algo_name, '】排考及教室分配明细'], ...
    'Position', [20, 590, 910, 40], 'FontSize', 18, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'ForegroundColor', 'k');
uitable(fig_table, 'Data', room_assignment_log, ...
    'ColumnName', {'考试日期', '科目序号 (ID)', '考生人数', '分配教室 (Room)'}, ...
    'ColumnWidth', {120, 150, 120, 200}, 'FontSize', 13, ...
    'ForegroundColor', [0 0 0], 'BackgroundColor', [1 1 1], ...
    'RowStriping', 'off', 'Position', [20, 20, 910, 550]);
