
% --- 图 1 & 2：冲突特征分析 ---
% 'Color', 'w' 设置窗口背景为白色
figure('Name', '冲突特征分析', 'Color', 'w', 'Position', [100, 100, 1000, 400]);

subplot(1,2,1);
spy(adj_matrix, 'b.', 5); 
title('图 A: 考场冲突矩阵稀疏图');
xlabel('科目 ID'); ylabel('科目 ID');
set(gca, 'Color', 'w'); % 确保坐标轴背景也是白色

subplot(1,2,2);
bar(sorted_degrees, 'FaceColor', [0.8 0.3 0.3]);
title('图 B: 考试科目冲突度排序 (Welsh-Powell 依据)');
xlabel('排序后的科目序号'); ylabel('冲突边数 (度)');
grid on;
set(gca, 'Color', 'w', 'GridColor', [0.5 0.5 0.5]); % 设置网格颜色为灰色，背景白色

% --- 图 3：排考分配结果 ---
figure('Name', '排考结果分布', 'Color', 'w');
h = histogram(colors, 'BinMethod', 'integers', 'FaceColor', [0.2 0.6 0.2]);
title(['图 C: 排考时间段分配结果 (总计需要 ', num2str(current_color), ' 个时段)']);
xlabel('考试时间段 (颜色/轮次编号)'); ylabel('该时段安排的科目数量');
xticks(1:current_color);
grid on;
set(gca, 'Color', 'w');