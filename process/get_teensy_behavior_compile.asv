function [] = get_teensy_behavior_compile(pth,compile_days)

% beh will be [piezo_amp opto_trl opto_t outcome rt trial_ix i];
% hit = 1, miss = 0, cw = 2, fa = 3
beh = [];
for i = 1:numel(compile_days)

    load([pth 'behavior_day_' num2str(compile_days(i))],'S');
    b = S.beh;
    first_hit = find(b(:,4)==1,1,'first');
    last_hit = find(b(:,4)==1,1,'last');
    b = b(first_hit:last_hit,:);
    beh = cat(1,beh,b);

end

% n_conditions = p amps x opo tf x opto time

% cell 1 will be no opto
beh_summ{1} = zeros(numel(unique(beh(:,1))),3);
% cell 2 will be opto
beh_summ{2} = zeros(numel(unique(beh(:,1))),numel(unique(beh(~isnan(beh(:,3)),3))),4);

p_amps = unique(beh(:,1));
opto_ts = unique(beh(~isnan(beh(:,3)),3));

cnts = {};
for i = 1:numel(p_amps)

    all_pts = beh(beh(:,1)==p_amps(i),:);
    opto_pts = all_pts(logical(all_pts(:,2)),:);
    non_opto_pts = all_pts(~logical(all_pts(:,2)),:);

    if p_amps(i)==0
        fa_rate = nnz(non_opto_pts(:,4)==3)./(nnz(non_opto_pts(:,4)==3)+nnz(non_opto_pts(:,4)==2));
        cnts{1}.n_cws(i) = nnz(non_opto_pts(:,4)==2);
        cnts{1}.n_fas(i) = nnz(non_opto_pts(:,4)==3);
        beh_summ{1}(i,:) = [p_amps(i) fa_rate 0];
    else
        hit_rate = nnz(non_opto_pts(:,4)==1)./(nnz(non_opto_pts(:,4)==1)+nnz(non_opto_pts(:,4)==0));
        cnts{1}.n_hits(i) = nnz(non_opto_pts(:,4)==1);
        cnts{1}.n_misses(i) = nnz(non_opto_pts(:,4)==0);
        rt = mean(non_opto_pts(:,3),'omitnan');
        beh_summ{1}(i,:) = [p_amps(i) hit_rate rt];
    end

    for j = 1:numel(opto_ts)

        this_t_opto_pts = opto_pts(opto_pts(:,3)==opto_ts(j),:,:,:,:);

        if p_amps(i)==0
            fa_rate = nnz(this_t_opto_pts(:,4)==3)./(nnz(this_t_opto_pts(:,4)==3)+nnz(this_t_opto_pts(:,4)==2));
            cnts{2}.n_cws(i,j) = nnz(this_t_opto_pts(:,4)==2);
            cnts{2}.n_fas(i,j) = nnz(this_t_opto_pts(:,4)==3);
            beh_summ{2}(i,j,:) = [p_amps(i) opto_ts(j) fa_rate 0];
        else
            hit_rate = nnz(this_t_opto_pts(:,4)==1)./(nnz(this_t_opto_pts(:,4)==1)+nnz(this_t_opto_pts(:,4)==0));
            cnts{2}.n_hits(i,j) = nnz(this_t_opto_pts(:,4)==1);
            cnts{2}.n_misses(i,j) = nnz(this_t_opto_pts(:,4)==0);
            rt = mean(this_t_opto_pts(:,3),'omitnan');
            beh_summ{2}(i,j,:) = [p_amps(i) opto_ts(j) hit_rate rt];
        end
    end

end

D = {};
C = {};
B = {};
for i = 1:numel(cnts)
    for j = 1:numel(cnts{i}.n_hits)

        hits = cnts{i}.n_hits(j);
        misses = cnts{i}.n_misses(j);
        correct_witholds = cnts{i}.n_cws;
        false_alarms = cnts{i}.n_fas;
        [d,b,c] = dprime(hits,misses,false_alarms,correct_witholds);
        D{i}(j) = d;
        C{i}(j) = c;
        B{i}(j) = b;
    end
end

figure, hold on

% no opto curve
plot(beh_summ{1}(:,1),beh_summ{1}(:,2),'-ok');

% opto curves
beh_summ{2}(1,2,3) = beh_summ{2}(1,1,3);
beh_summ{2}(1,3,3) = beh_summ{2}(1,1,3);
beh_summ{2}(1,4,3) = beh_summ{2}(1,1,3);
beh_summ{2}(1,5,3) = beh_summ{2}(1,1,3);
beh_summ{2}(1,6,3) = beh_summ{2}(1,1,3);


plot(beh_summ{2}(:,1,1),beh_summ{2}(:,1,3),'-o');
plot(beh_summ{2}(:,2,1),beh_summ{2}(:,2,3),'-o');
plot(beh_summ{2}(:,3,1),beh_summ{2}(:,3,3),'-o');
plot(beh_summ{2}(:,4,1),beh_summ{2}(:,4,3),'-o');
plot(beh_summ{2}(:,5,1),beh_summ{2}(:,5,3),'-o');
plot(beh_summ{2}(:,6,1),beh_summ{2}(:,6,3),'-o');
    

legend({'No Opto', '20','10','5','-50','-200'});
xlabel('Piezo Voltage')
ylabel('P(hit)')
ax=gca;
ax.Legend.EdgeColor = 'None';
ax.Legend.Location = 'SouthEast';

%
subplot(1,2,2), hold on
ft = fittype('logistic');
mdl_fit_no = fit(beh_summ{1}([1 2 4:8],1),beh_summ{1}([1 2 4:8],2),ft);
eval_x = 0:0.01:2;
fit_points_no = mdl_fit_no(eval_x);

%

mdl_fit_0 = fit(beh_summ{2}([1 2 4:8],1,1),beh_summ{2}([1 2 4:8],1,3),ft);
mdl_fit_100 = fit(beh_summ{2}([1 2 4:8],2,1),beh_summ{2}([1 2 4:8],2,3),ft);

eval_x = 0:0.01:2;

fit_points_0 = mdl_fit_0(eval_x);
fit_points_100 = mdl_fit_100(eval_x);

plot(eval_x,fit_points_no,'k')
plot(eval_x,fit_points_0,'g')
plot(eval_x,fit_points_100,'m')

xlabel('Piezo Voltage')
ylabel('P(hit)')
legend({'No Opto', '0', '-100'});
ax=gca;
ax.Legend.EdgeColor = 'None';
ax.Legend.Location = 'SouthEast';

% plot(beh_summ{1}(1:end,1),beh_summ{1}(1:end,2),'ok')
% plot(beh_summ{2}(:,2,1),mean(beh_summ{2}(:,2,3),2),'og')
% plot(beh_summ{2}(:,1,1),mean(beh_summ{2}(:,1,3),2),'om')

%

all_go_licks(all_go_licks==0) = NaN;

pre_post = [-0.5 2];
lick_t = pre_post(1):1/fs:pre_post(2);
subplot(2,2,3), hold
scatter(lick_t,all_go_licks+linspace(1,size(all_go_licks,2),size(all_go_licks,2)),'Marker','o','SizeData',4,'MarkerFaceColor','k','MarkerEdgeColor','none','MarkerFaceAlpha', 0.01)
xlim(pre_post)
ylim([0 size(all_go_licks,2)])
xlabel('Time (S)')
ylabel('Trial Number')
line([0 0],ylim,'Color','r','LineWidth',2)

%

subplot(2,2,4),
bar([beh_summ{1}(1,2) mean(beh_summ{2}(1,:,3),2)],'FaceColor',[0.25 0.1 0.5],'EdgeColor','None')
ylim([0 1])
ylabel('P|fa|')
xlabel('Condition')
ax=gca;
ax.XTickLabel = {'No Opto','Opto'};