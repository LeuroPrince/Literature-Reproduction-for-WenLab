clearvars;  % 清除变量
close all;  % 关闭所有图形窗口
figure;     % 只在这里创建一次图形
hold on;  

trial_num = 1:11;
plot_length = 3;

% RIV
[xb_ctrl, yb_ctrl, lb_ctrl, ub_ctrl,xa_ctrl,ya_ctrl,la_ctrl, ua_ctrl] = processData5DE(1:11, '3E-F_5D-E-dataRIV.xlsx', '3E-F_5D-E-time.xlsx','reversalstart',plot_length);
%t > 0
plot(xa_ctrl, ya_ctrl, 'b', 'LineWidth', 1.5, 'DisplayName', 'RIV calcium acitivity');
fill([xa_ctrl fliplr(xa_ctrl)], [la_ctrl fliplr(ua_ctrl)], 'b', 'facealpha', 0.2, 'edgealpha', 0,'HandleVisibility', 'off');
% 绘制 t < 0
plot(xb_ctrl, yb_ctrl, 'b', 'LineWidth', 1.5, 'HandleVisibility', 'off'); % handlevisibility off 避免重复图例
fill([xb_ctrl fliplr(xb_ctrl)], [lb_ctrl fliplr(ub_ctrl)], 'b', 'facealpha', 0.2, 'edgealpha', 0, 'HandleVisibility', 'off');

% RIB-ablated
[xb_ablated, yb_ablated, lb_ablated, ub_ablated,xa_ablated,ya_ablated,la_ablated, ua_ablated] = processData5DE(1:10, 'data5DE.xlsx', 'time5DE.xlsx','reversalstart',plot_length);
%t > 0
plot(xa_ablated, ya_ablated, 'r', 'LineWidth', 1.5, 'DisplayName', 'RIV with RIB being ablated');
fill([xa_ablated fliplr(xa_ablated)], [la_ablated fliplr(ua_ablated)], 'r', 'facealpha', 0.2, 'edgealpha', 0,'HandleVisibility', 'off');
% 绘制 t < 0
plot(xb_ablated, yb_ablated, 'r', 'LineWidth', 1.5, 'HandleVisibility', 'off'); % handlevisibility off 避免重复图例
fill([xb_ablated fliplr(xb_ablated)], [lb_ablated fliplr(ub_ablated)], 'r', 'facealpha', 0.2, 'edgealpha', 0, 'HandleVisibility', 'off');

%美化
hold off; 

title('figure 5E');
xlabel('stimulation time');
ylabel('ΔR(t)/R₀');


axis([0 3 0 0.6]); % 使用一个能包含所有数据的坐标轴范围

legend('show', 'Location', 'best');

disp('绘图完成！');