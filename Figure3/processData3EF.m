function [x_before, y_before, l_before, u_before, x_after, y_after, l_after, u_after] = processData5DE(trial_range, data_filename, time_filename,analysis_type, plotlength_sec)
%此函数与我们之前用于处理4D数据的processData非常相似,只是在一些细微处有不同,以及加了一个
%transfer time matrix模块来针对对不同的分析类型(reversal start 或turn start)转换对齐时间.
% 同时processData只考虑了t = 0之后的情况,而本函数还会同创造一个before和after的时间窗口来处理数据.我会标出此函数与processData的不同之处以供参考.

% defining initial parameters
minnum = 3;   %
frame = 50;  %定义频率
backtimemax = 10000;
smoothpara = 40;
trial = trial_range;   
trialnum = length(trial);   
plotlength = plotlength_sec * frame;   %定义了一个plotlength,同于在transfer time时在第一行的前面增加一个分析窗口避免数据不够

% create empty cell to load data and results
gcamp_ref = cell(1,trialnum);  
gcamp_ori = cell(1,trialnum);
ratio = cell(1,trialnum);
ratio_smo = cell(1,trialnum);   %这里多定义了一个ratio_sum
smo = cell(1,trialnum);
time = cell(1,trialnum);

for i = 1:trialnum   
    current_trial_index = trial(i);
    temp = xlsread(data_filename, current_trial_index);
    gcamp_ref{i} = temp(:,1);    
    gcamp_ori{i} = temp(:,2);    
    ratio{i} = temp(:,2)./temp(:,1);
    
    time{i} = xlsread(time_filename, current_trial_index);
end

%time transfer matrix
if strcmp(analysis_type, 'reversalstart') % 这一句实现了只有在输入reversalstart的analysis type时才会启动这一代码块
    disp('Running time matrix transfer for reversal start...'); 
    for i = 1:trialnum
        temp = time{i};
        temp(2,:) = time{i}(1,:); % 将reversalstart 的时间数据赋给temp的第二行作为对齐数据
        temp(3,:) = time{i}(3,:); % 第三行不变.
        %此时的第一行为reversalstart time
        
        % 重新定义第一行的数据,即在reversalstart前增加分析窗口.
        temp(1,1) = max([1, time{i}(1,1) - plotlength]); %保证分析开始时间大于1
        for j = 2:size(time{i},2)
            temp(1,j) = max([time{i}(3,j-1)+1, time{i}(1,j) - plotlength]); %此处实现了第一行数据的更新,同时也保证了两个分析窗口不会互相重叠.
        end
        time{i} = temp;%更新原来的time表
    end
end

%smooth
for i = 1:trialnum
    ratio_smo{i} = smooth(ratio{i}, smoothpara);  
	NotANum = isnan(ratio{i});
    NaNPos = find(NotANum == 1);   %这两行筛选出来nnan值
    for j = 1:length(NaNPos)
        ratio_smo{i}(NaNPos(j)) = NaN;   %为nan值做平滑避免报错
    end
    smo{i} = ratio_smo{i};
end

% normalize data
n = 0;
for i = 1:trialnum
    for j = 1:size(time{i},2)   % X代表数组，dimension（第二个接受值）代表维度，1代表行，2代表列
        if isnan(time{i}(1,j)) == 0 && isnan(time{i}(3,j)) == 0 && isnan(smo{i}(time{i}(2,j))) == 0
            n = n+1;
            tt = time{i}(1,j):time{i}(3,j);   %  ：符号意味着创造一个等差数列，相当于创建了一个列表；在这里相当于python中的切片
            ratio{i}(tt) = ( ratio{i}(tt) - min(smo{i}(tt)) ) ./ min(smo{i}(tt));   %向量化计算ratio
            smo{i}(tt) = ( smo{i}(tt) - min(smo{i}(tt)) ) ./ min(smo{i}(tt));   %smooth，计算每一个平滑点对应的ratio（也就是图像上的y）值
        end
    end
end

% alignment and average
turn = cell(1,backtimemax);
back = cell(1,backtimemax);   %这一段代码的目的是要获得对齐后的宽度为backtimemax的分析窗口
n = 0;
for i = 1:trialnum   %定位到要处理的trial也就是sheet
    for j = 1:size(time{i},2)   %这里我们拿到了每一张时间表的sheet值
        if isnan(time{i}(1,j)) == 0 && isnan(time{i}(3,j)) == 0 && isnan(smo{i}(time{i}(2,j))) == 0 %这里需要三行都不为nan
            n = n+1;
            for t = (time{i}(2,j)):(time{i}(3,j))
                backtime = t - time{i}(2,j) + 1;
                if backtime <= backtimemax && isnan(smo{i}(t)) == 0
                    if strcmp(analysis_type, 'reversalstart')
                        % reversalstart 用 dR/R0
                        turn{backtime} = [turn{backtime}, smo{i}(t)]; 
                    else
                        % turnstart 用 dR (减去对齐点的值),不同地荧光信号处理策略
                        turn{backtime} = [turn{backtime}, smo{i}(t) - smo{i}(time{i}(2,j))]; 
                    end
                end
            end
            
            % 收集对齐点之前的数据 (t < 0)
            for t = (time{i}(2,j)):(-1):time{i}(1,j)
                backtime = time{i}(2,j) - t + 1;
                if backtime <= backtimemax && isnan(smo{i}(t)) == 0
                    if strcmp(analysis_type, 'reversalstart')
                        % reversalstart 用 dR/R0
                        back{backtime} = [back{backtime}, smo{i}(t)];
                    else
                         % turnstart 用 dR (减去对齐点的值)
                        back{backtime} = [back{backtime}, smo{i}(t) - smo{i}(time{i}(2,j))];
                    end
                end
            end
        end
    end
end

%calculate the means and standarderror
smoback2 = zeros(1,backtimemax);
smobackstd2 = zeros(1,backtimemax);


backtimevis2 = 0; %这一行的意思是

for t = 1:backtimemax
    smoback2(t) = mean(turn{t});
    smobackstd2(t) = std(turn{t}) / sqrt(length(turn{t}));
    if length(turn{t}) >= minnum
        backtimevis2 = t; % 找到满足最小 N 的最远时间点
    end
end
smoback_up2 = smoback2 + smobackstd2;
smoback_low2 = smoback2 - smobackstd2;   %画出阴影区域的上下界

% output
frame2 = 50;
x_after = ((1:backtimevis2) - 1) / frame2;
y_after = smoback2(1:backtimevis2);
l_after = smoback_low2(1:backtimevis2);
u_after = smoback_up2(1:backtimevis2);

smoback1 = zeros(1,backtimemax);
smobackstd1 = zeros(1,backtimemax);
backtimevis = 0;
for t = 1:backtimemax
    smoback1(t) = mean(back{t});
    smobackstd1(t) = std(back{t}) / sqrt(length(back{t}));
    if length(back{t}) >= minnum
        backtimevis = t;
    end
end
backtimevis_before = min(plotlength, backtimevis);
smoback_up1 = smoback1 + smobackstd1;
smoback_low1 = smoback1 - smobackstd1;

% 准备 t < 0 (before) 的输出
% 注意 x 轴是负的，并且用 fliplr 来翻转
x_before = fliplr(((1:backtimevis_before) - backtimevis_before) / frame);
y_before = smoback1(1:backtimevis_before);
l_before = smoback_low1(1:backtimevis_before);
u_before = smoback_up1(1:backtimevis_before);
end