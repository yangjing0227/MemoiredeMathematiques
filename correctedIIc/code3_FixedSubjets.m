%% 带预设科目约束的负载均衡排考算法
clear; clc;

% --- 1. 数据读取 ---
filename = 'sta-f-83-3.stu';
num_exams = 139; 
adj_matrix = zeros(num_exams, num_exams);
fid = fopen(filename, 'r');
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

% --- 2. 设置指定科目约束 (核心修改点) ---
% 格式：[科目ID, 指定时段编号]
% 比如：把 10号科目固定在第 5 时段，把 50号科目固定在第 1 时段
fixed_exams = [
    10, 5;
    50, 1;
    139, 3
];

% 初始化颜色分配
colors = zeros(num_exams, 1);

% 首先应用固定约束
for k = 1:size(fixed_exams, 1)
    exam_id = fixed_exams(k, 1);
    target_color = fixed_exams(k, 2);
    
    % 检查预设是否存在冲突 (数学专业严谨性检查)
    neighbors = find(adj_matrix(exam_id, :) == 1);
    if any(colors(neighbors) == target_color)
        error('预设失败：科目 %d 的邻居已分配了时段 %d，存在冲突！', exam_id, target_color);
    end
    colors(exam_id) = target_color;
end

% --- 3. 执行均衡负载着色 ---
degrees = sum(adj_matrix, 2);
[~, sorted_idx] = sort(degrees, 'descend');

% 预估总时段（参考之前的实验结果，设为13或稍大）
max_c = 13; 

for i = 1:num_exams
    node = sorted_idx(i);
    
    % 如果该科目已经被固定了，跳过
    if colors(node) > 0, continue; end
    
    used_colors = colors(logical(adj_matrix(node, :)));
    
    best_c = -1;
    min_count = inf;
    
    % 尝试在 1 到 max_c 之间寻找最空闲且不冲突的时段
    for c = 1:max_c
        if ~any(used_colors == c)
            current_count = sum(colors == c);
            if current_count < min_count
                min_count = current_count;
                best_c = c;
            end
        end
    end
    
    % 如果 1-max_c 都没位置，则开启新时段
    if best_c == -1
        max_c = max_c + 1;
        best_c = max_c;
    end
    
    colors(node) = best_c;
end

% --- 4. 结果展示 ---
figure('Color', 'w', 'Name', '带约束排考分布');
h = histogram(colors, 'BinMethod', 'integers', 'FaceColor', [0.3 0.6 0.4]);
title(['指定约束下的排考结果 (总时段: ', num2str(max(colors)), ')']);
xlabel('考试时间段'); ylabel('科目数量');
grid on;

% 验证固定科目是否成功
fprintf('--- 预设科目检查 ---\n');
for k = 1:size(fixed_exams, 1)
    fprintf('科目 %d 最终分配时段: %d (预设值: %d)\n', ...
        fixed_exams(k, 1), colors(fixed_exams(k, 1)), fixed_exams(k, 2));
end