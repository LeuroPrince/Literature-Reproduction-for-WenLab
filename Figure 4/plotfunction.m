clearvars;  % 清除变量
close all;  % 关闭所有图形窗口
figure;     % 只在这里创建一次图形
hold on;    

% no ATR
[x_ctrl, y_ctrl, l_ctrl, u_ctrl] = processData(1:7, 'Figure_4D_no_ATR_data.xlsx', 'Figure_4D_no_ATR_time.xlsx');
plot(x_ctrl, y_ctrl, 'Color', [0.5,0.5,0.5], 'LineWidth', 1.5, 'DisplayName', 'control(no ATR)(N=52)');
fill([x_ctrl fliplr(x_ctrl)], [l_ctrl fliplr(u_ctrl)], [0.5,0.5,0.5], 'facealpha', 0.2, 'edgealpha', 0);

% eat-4
[x_eat4, y_eat4, l_eat4, u_eat4] = processData(1:9, 'dataeat4.xlsx', 'timeeat4.xlsx');
plot(x_eat4, y_eat4, 'r', 'LineWidth', 1.5, 'DisplayName', 'eat-4(ky5) (N=89)');
fill([x_eat4 fliplr(x_eat4)], [l_eat4 fliplr(u_eat4)], 'r', 'facealpha', 0.2, 'edgealpha', 0);

%ATR
[x_atr, y_atr, l_atr, u_atr] = processData(1:8, 'ATR_data.xlsx', 'ATR_time.xlsx');
plot(x_atr, y_atr, 'Color',[0,0,0.5], 'LineWidth', 1.5, 'DisplayName', 'control(ATR)(n=59)');
fill([x_atr fliplr(x_atr)], [l_atr fliplr(u_atr)], [0,0,0.5], 'facealpha', 0.2, 'edgealpha', 0);

%美化
hold off; 

title('atr GCamp (AIB activated)');
xlabel('t/s');
ylabel('dR/R0');


axis([0 10 0 0.6]); % 使用一个能包含所有数据的坐标轴范围

legend('show', 'Location', 'best');

disp('绘图完成！');