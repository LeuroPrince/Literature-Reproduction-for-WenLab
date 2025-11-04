clearvars
minnum = 3;
frame = 100;
backtimemax = 10000;
smoothpara = 40;
trial = 9;
gcamp_ref = cell(1,trial);
gcamp_ori = cell(1,trial);
ratio = cell(1,trial);
ratio_smo = cell(1,trial);
smo = cell(1,trial);
time = cell(1,trial);
for i = 1:trial
    temp = xlsread('datacb.xlsx',i);
    gcamp_ref{i} = temp(:,1);
    gcamp_ori{i} = temp(:,2);   
    ratio{i} = temp(:,2)./temp(:,1);   %获取raw ratio数据
    time{i} = xlsread('timecb.xlsx',i);
    ratio_smo{i} = smooth(ratio{i},smoothpara);   %在这里我们拿到了特定行为的时间戳，而data表中其他时间可能包括一些空白数据（无意义）
	NotANum = isnan(ratio{i});
    NaNPos = find( NotANum ==1 );
    for j = 1:length( NaNPos )
        ratio_smo{i}( NaNPos(j) ) = NaN;   %消除空值带来的计算误差
    end
    smo{i} = ratio_smo{i};
end
totaltime = length(gcamp_ref{1});

%% 
n = 0;
n_1 = 0;
n_2 = 0;
for i = 1:trial
    for j = 1:size(time{i},2)   %遍历每个时间表的每一列
        n = n+1;
        if isnan(time{i}(3,j))   %选取第三列为空的值，即事件type1
            if j ~= size(time{i},2)   %这里的作用是确定j不是最后一个数据
                tt = time{i}(1,j):(time{i}(1,j+1)-1);  %定一个时间分析窗口，即从上一个事件的开始时间点到下一次时间起点的前一帧。但是我有一个问题，就是两个事件之间往往有比一个事件内大很多的时间跨度，这是怎么解决的？
            else
                tt = time{i}(1,j):(time{i}(2,j)+4*frame);  %哦这一句代码里的4*frame解决了上一个问题！
            end
            n_1 = n_1 + 1;   %计数器
        else
            tt = time{i}(1,j):time{i}(3,j);   %事件type2的时间窗口，在事件内部
            n_2 = n_2 + 1;
        end
        temp = min(smo{i}(tt));
        smo{i}(tt) = ( smo{i}(tt) - temp ) ./ temp;
        ratio{i}(tt) = ( ratio{i}(tt) - temp ) ./ temp;    %拿到每一个tt窗口的平滑后的数据并用ΔF/F来标准化.然后将处理完后的代码传输回ratio覆盖了同一个地方的raw data。
    end
end

individual_trial = n;   %

%%
%{
for i = 1:trial
    mintemp = min(ratio_smo{i});
    maxtemp = max(ratio_smo{i});
    smo{i} = ( ratio_smo{i} - mintemp ) ./ mintemp ;
end
%}
%%
forward = cell(1,backtimemax);
back = cell(1,backtimemax);
for i = 1:trial
    for j = 1:size(time{i},2)
        if isnan(time{i}(1,j)) == 0
            if isnan(time{i}(3,j)) == 1   %无turn数据，计算的是type1事件
                if isnan( smo{i}(time{i}(2,j)) ) == 0
                    % forward开始之后，forward中
                    %plot(1:( time{i}(2,j) - time{i}(1,j) ),smo{i}((time{i}(1,j)+1):time{i}(2,j))-smo{i}(time{i}(2,j)));
                    %hold on
                    if j == size(time{i},2)   %若j是最后一列时间
                        endtime = length(ratio{i});
                    else
                        if isnan(time{i}(1,j+1)) == 0   %若j的下一列时间不为空（即有后续事件）
                            endtime = time{i}(1,j+1);   %取下一个1事件的起始时间为endtime
                        else
                            endtime = time{i}(2,j+1);   %这里的else还有可能是什么情况？下一个事件的开始时间是空值？
                        end
                    end
                    endtime = min(endtime,time{i}(2,j)+4*frame);
                    for t = (time{i}(2,j)+1):endtime
                        backtime = t-time{i}(2,j);
                        if isnan(smo{i}(t)) == 0
                            forward{backtime} = [forward{backtime},smo{i}(t)-smo{i}(time{i}(2,j))];   %这个for循环行对齐之事，对齐于前进的起始时间，且计算了t0后部分的数据
                            %turn{backtime} = [turn{backtime},smo{i}(t)];
                        end
                    end
                    % turn开始之前，后退中
                    
                    for t = (time{i}(2,j)-1):(-1):time{i}(1,j)   %令人不解，这里用的是一个时间倒流的处理方式。这样处理的话，画图时该如何与前面的forward对齐？
                        backtime = time{i}(2,j)-t;               %那么在这里1对应的是reversal结束前的一帧，……，backtime（最后一个backtime）指的是reversal开始的时间。

                        if isnan(smo{i}(t)) == 0
                            back{backtime} = [back{backtime},smo{i}(t)-smo{i}(time{i}(2,j))];   %哦除非，在图像上，这一块的数据被画在了t=0之前，也就是说，这里的forward指的是reversal结束时即将进入forward状态（也是type1的定义），而上面的forward就是获取的reversal结束后的数据点
                            %back{backtime} = [back{backtime},smo{i}(t)];                       %这样就解释得通了
                            
                        end
                    end
                    
                end
            end
        end
    end
end

figure
hold on

smoback = zeros(1,backtimemax);
smobackstd = zeros(1,backtimemax);
for t = 1:backtimemax
    smoback(t) = mean(forward{t});
    smobackstd(t) = std(forward{t})/sqrt(length(forward{t}));
    if length(forward{t}) >= minnum
        backtimevis = t;
    end
end
smoback_up = smoback + smobackstd;
smoback_low = smoback - smobackstd;
plot([0,(1:backtimevis)/frame],[0,smoback(1:backtimevis)],'b');   %将x轴的输入从帧率转化为时间（/frame）。但是这里是如何保证数据是从0开始的？或者说从0开始的图像特征是代码处理带来的还是数据禀赋带来的？
fill([((1:backtimevis))/frame fliplr(((1:backtimevis)-1)/frame)],[smoback_low(1:backtimevis) fliplr(smoback_up(1:backtimevis))],'b','facealpha',0.2,'edgealpha',0);   %哦可能这个0只是作为一个起点，后面的图像该如何变化得看数据自身的变化趋势。这个图像只代表数据变化趋势。而且0前和0后的数据是相互独立的，并没有必然联系。

smoback = zeros(1,backtimemax);
smobackstd = zeros(1,backtimemax);
for t = 1:backtimemax
    smoback(t) = mean(back{t});
    smobackstd(t) = std(back{t})/sqrt(length(back{t}));
    if length(back{t}) >= minnum
        backtimevis = t;
    end
end
smoback_up = smoback + smobackstd;
smoback_low = smoback - smobackstd;
plot(fliplr(((1:backtimevis)-backtimevis-1)/frame),smoback(1:backtimevis),'b');
fill([fliplr(((1:backtimevis)-backtimevis-1)/frame) ((1:backtimevis)-backtimevis)/frame],[smoback_low(1:backtimevis) fliplr(smoback_up(1:backtimevis))],'b','facealpha',0.2,'edgealpha',0);

title('RIB GCaMP before and after type-1 transition ( t=0 aligned to forward starts)');
xlabel('t/s');
ylabel('dR/R');