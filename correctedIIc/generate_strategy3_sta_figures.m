clear; clc; close all;

data_file = 'C:\Users\Yangjing\Desktop\correctedIIc\sta-f-83-3.stu';
photo_dir = 'C:\Users\Yangjing\Desktop\大四下 论文 数应\LaTex 指导\本科毕业论文-UTF8\本科毕业论文-UTF8\photo';

max_v = 0;
exam_counts = containers.Map('KeyType', 'int32', 'ValueType', 'int32');

fid = fopen(data_file, 'r');
if fid == -1
    error('找不到数据集文件：%s', data_file);
end
while ~feof(fid)
    line = fgetl(fid);
    if isempty(line) || ~ischar(line), continue; end
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

fid = fopen(data_file, 'r');
while ~feof(fid)
    line = fgetl(fid);
    if isempty(line) || ~ischar(line), continue; end
    exams = sscanf(line, '%d');
    if length(exams) > 1
        for i = 1:length(exams)
            for j = i+1:length(exams)
                u = exams(i); v = exams(j);
                if u <= num_exams && v <= num_exams
                    adj_matrix(u, v) = 1;
                    adj_matrix(v, u) = 1;
                end
            end
        end
    end
end
fclose(fid);

degrees = sum(adj_matrix, 2);
[~, sorted_idx] = sort(degrees, 'descend');
final_colors = zeros(num_exams, 1);

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
total_days = max(final_colors);

room_resources = [
    101, 30;
    102, 30;
    201, 50;
    202, 50;
    301, 80;
    302, 80;
    401, 120;
    402, 120;
    501, 250;
    502, 300;
    503, 500
];

room_assignment_log = {};
for d = 1:total_days
    exams_today = find(final_colors == d);
    today_pop = zeros(length(exams_today), 2);
    for k = 1:length(exams_today)
        id = exams_today(k);
        today_pop(k, :) = [id, exam_counts(id)];
    end
    today_pop = sortrows(today_pop, -2);
    current_rooms = room_resources;
    for j = 1:size(today_pop, 1)
        exam_id = today_pop(j, 1);
        st_count = today_pop(j, 2);
        assigned = false;
        for r = 1:size(current_rooms, 1)
            if current_rooms(r, 2) >= st_count
                room_assignment_log{end+1, 1} = sprintf('第 %d 天', d);
                room_assignment_log{end, 2} = exam_id;
                room_assignment_log{end, 3} = st_count;
                room_assignment_log{end, 4} = current_rooms(r, 1);
                current_rooms(r, 2) = current_rooms(r, 2) - st_count;
                assigned = true;
                break;
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

fig1 = figure('Name', '统计分析', 'Color', 'w', 'Position', [200, 200, 1000, 400], 'Visible', 'off');
subplot(1,2,1); spy(adj_matrix, 'b.', 8);
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'Box', 'on');
title('冲突矩阵稀疏图', 'Color', 'k');
subplot(1,2,2);
histogram(final_colors, 'BinMethod', 'integers', 'FaceColor', [0.2 0.4 0.7], 'EdgeColor', 'w');
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'Box', 'on');
title('各时段负载分布', 'Color', 'k');
xlabel('考试天数'); ylabel('科目数量');
exportgraphics(fig1, fullfile(photo_dir, 'P31.png'), 'Resolution', 150);
close(fig1);

fig2 = figure('Name', '排考日程明细图', 'Color', 'w', 'Position', [150, 100, 1100, 400], 'Visible', 'off');
schedule_matrix = zeros(total_days, num_exams);
for i = 1:num_exams
    day_idx = final_colors(i);
    if day_idx > 0, schedule_matrix(day_idx, i) = 1; end
end
imagesc(schedule_matrix); colormap([1 1 1; 0.2 0.4 0.7]); grid on;
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridColor', [0.8 0.8 0.8]);
title(['【', algo_name, '】排考日程矩阵'], 'FontSize', 14, 'Color', 'k');
xlabel('科目 ID'); ylabel('考试日期');
exportgraphics(fig2, fullfile(photo_dir, 'P32.png'), 'Resolution', 150);
close(fig2);

fig3 = figure('Name', '排考及考场分配清单', 'Color', 'w', 'MenuBar', 'none', 'Position', [300, 150, 950, 650], 'Visible', 'on');
uicontrol('Style', 'text', 'String', ['【', algo_name, '】排考及教室分配明细'], ...
    'Position', [20, 590, 910, 40], 'FontSize', 18, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'ForegroundColor', 'k');
uitable(fig3, 'Data', room_assignment_log, ...
    'ColumnName', {'考试日期', '科目序号 (ID)', '考生人数', '分配教室 (Room)'}, ...
    'ColumnWidth', {120, 150, 120, 200}, 'FontSize', 13, ...
    'ForegroundColor', [0 0 0], 'BackgroundColor', [1 1 1], ...
    'RowStriping', 'off', 'Position', [20, 20, 910, 550]);
drawnow;
exportapp(fig3, fullfile(photo_dir, 'P33.png'));
close(fig3);

loads = histcounts(final_colors, 1:(total_days+1));
fprintf('第三策略已生成：总天数=%d，负载方差=%.2f，特殊科目4=%d，特殊科目103=%d。\n', ...
    total_days, var(loads, 1), final_colors(4), final_colors(103));
