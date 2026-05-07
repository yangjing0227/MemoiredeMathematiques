%% 均衡负载着色算法实验 (修正版)
clear; clc;

% --- 1. 数据读取 (以 sta-f-83-3 为例) ---
filename = 'sta-f-83-3.stu';
num_exams = 139; 
adj_matrix = zeros(num_exams, num_exams);
fid = fopen(filename, 'r');
if fid == -1, error('找不到文件 %s', filename); end

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

% --- 2. 算法执行 ---
degrees = sum(adj_matrix, 2);
[~, sorted_idx] = sort(degrees, 'descend');

% 策略 A: 原始贪心 (Welsh-Powell)
colors_greedy = zeros(num_exams, 1);
for i = 1:num_exams
    node = sorted_idx(i);
    used_colors = colors_greedy(logical(adj_matrix(node, :)));
    c = 1;
    while any(used_colors == c), c = c + 1; end
    colors_greedy(node) = c;
end

% 策略 B: 负载均衡着色 (修正逻辑)
max_c = max(colors_greedy); 
colors_balanced = zeros(num_exams, 1);
for i = 1:num_exams
    node = sorted_idx(i);
    used_colors = colors_balanced(logical(adj_matrix(node, :)));
    
    best_c = 1;
    min_count = inf;
    for c = 1:max_c
        if ~any(used_colors == c)
            current_count = sum(colors_balanced == c);
            if current_count < min_count
                min_count = current_count;
                best_c = c;
            end
        end
    end
    colors_balanced(node) = best_c;
end

% --- 3. 结果对比可视化 (白底高清版) ---
figure('Color', 'w', 'Name', '排考压力对比图', 'Position', [200, 200, 800, 600]);

% 子图1: 原始算法
subplot(2,1,1);
h1 = histogram(colors_greedy, 'BinMethod', 'integers', 'FaceColor', [0.6 0.6 0.6]);
title(['策略 A: 原始 Welsh-Powell 算法 (总时段: ', num2str(max(colors_greedy)), ')']);
ylabel('科目数量'); grid on;
set(gca, 'Color', 'w');

% 子图2: 均衡算法
subplot(2,1,2);
h2 = histogram(colors_balanced, 'BinMethod', 'integers', 'FaceColor', [0.2 0.5 0.8]);
% 修正了导致报错的单引号问题
title(['策略 B: 负载均衡改进算法 (总时段: ', num2str(max(colors_balanced)), ')']);
xlabel('考试时间段 (轮次)'); ylabel('科目数量'); grid on;
set(gca, 'Color', 'w');

% --- 4. 统计分析输出 ---
% 计算方差评价均衡性 (方差越小越平均)
count_greedy = histcounts(colors_greedy, 1:max_c+1);
count_balanced = histcounts(colors_balanced, 1:max_c+1);

fprintf('====================================\n');
fprintf('原始算法排考方差: %.2f\n', var(count_greedy));
fprintf('均衡算法排考方差: %.2f\n', var(count_balanced));
fprintf('均衡性提升: %.2f%%\n', (var(count_greedy)-var(count_balanced))/var(count_greedy)*100);
fprintf('====================================\n');