%%在python中我们在sheet处理，在matlab中我们把每一个sheet中的数据提取出来向量化地处理
function [x_axis, mean_trace, lower_bound, upper_bound] = processData(trial_range, data_filename, time_filename)
% processData 


% defining parameters
backtimemax = 2000;
smoothpara = 40;
trial = trial_range;   %这里定义了trial，即在excel表中处于'sheet'数，或者说实验数
trialnum = length(trial);   

% create empty cell to load data and results
gcamp_ref = cell(1,trialnum);  
gcamp_ori = cell(1,trialnum);
ratio = cell(1,trialnum);
smo = cell(1,trialnum);
time = cell(1,trialnum);

for i = 1:trialnum   
    current_trial_index = trial(i);
    temp = xlsread(data_filename, current_trial_index);
    gcamp_ref{i} = temp(:,1);    %不同于在python中我们一个trial一个trail地处理，在这里我们直接把每一个sheet中我们需要的数据拿出来储存在元数据组中，然后可以向量化处理数据
    gcamp_ori{i} = temp(:,2);    %非常优雅与高效啊
    ratio{i} = temp(:,2)./temp(:,1);
    
    time{i} = xlsread(time_filename, current_trial_index);
    time{i} = [time{i}; NaN*zeros(1,size(time{i},2))];   %建立一个time{i}*2的空cell
end

%smooth
for i = 1:trialnum
    smo{i} = smooth(ratio{i}, smoothpara);  %应该就是一点一点填充两个数据点之间的距离。
	NotANum = isnan(ratio{i});
    NaNPos = find(NotANum == 1);   %这两行筛选出来nnan值
    for j = 1:length(NaNPos)
        smo{i}(NaNPos(j)) = NaN;   %为nan值做平滑避免报错
    end
end

% normalize data
n = 0;
for i = 1:trialnum
    for j = 1:size(time{i},2)   % X代表数组，dimension（第二个接受值）代表维度，1代表行，2代表列
        if isnan(time{i}(1,j)) == 0   %奇怪的是，0在这里代表有意义
                if isnan(smo{i}(time{i}(1,j))) == 0
                    n = n+1;
                    tt = time{i}(1,j):time{i}(2,j);   %  ：符号意味着创造一个等差数列，相当于创建了一个列表；在这里相当于python中的切片
                    ratio{i}(tt) = ( ratio{i}(tt) - min(smo{i}(tt)) ) ./ min(smo{i}(tt));   %向量化计算ratio
                    smo{i}(tt) = ( smo{i}(tt) - min(smo{i}(tt)) ) ./ min(smo{i}(tt));   %smooth，计算每一个平滑点对应的ratio（也就是图像上的y）值
                end
        end
    end
end

% alignment and average
back = cell(1,backtimemax);   %这一段代码的目的是要获得对齐后的宽度为backtimemax的分析窗口
for i = 1:trialnum   %定位到要处理的trial也就是sheet
    for j = 1:size(time{i},2)   %这里我们拿到了每一张时间表的sheet值
        if isnan(time{i}(1,j)) == 0
            if isnan(smo{i}(time{i}(1,j))) == 0
                for t = (time{i}(1,j)+1):time{i}(2,j)   %！！！关键：在这里我们取得的了开始帧和结束帧之间的值，也就是作为可以作为提取smo对应时间数值的索引！
                    backtime = t - time{i}(1,j);
                    if backtime <= backtimemax && isnan(smo{i}(t)) == 0
                        back{backtime} = [back{backtime}, smo{i}(t)];   %实现对齐的一句代码，用t一帧一帧地截取开始刺激后的时间点，再用backtime来规范化t（将其转变为距离刺激开始时间的距离）用t做索引，拿到该时间点的处理过平滑的的ratio值
                    end
                end
            end
        end
    end
end

%calculate the means and standarderror
smoback2 = zeros(1,backtimemax);
smobackstd2 = zeros(1,backtimemax);


backtimevis2 = 480; %这一行的意思是选一个可视化窗口长度

for t = 1:backtimemax
    smoback2(t) = mean(back{t});
    smobackstd2(t) = std(back{t}) / sqrt(length(back{t}));
end
smoback_up2 = smoback2 + smobackstd2;
smoback_low2 = smoback2 - smobackstd2;   %画出阴影区域的上下界

% output
frame2 = 50;
x_axis = ((1:backtimevis2) - 1) / frame2;
mean_trace = smoback2(1:backtimevis2);
lower_bound = smoback_low2(1:backtimevis2);
upper_bound = smoback_up2(1:backtimevis2);

end
