function [s] = get_teensy_behavior(d,fs,ttypes)

valid_response_win = 1.5;

piezo = d.Ao0;
piezo = 5*(piezo./4095);
opto = d.Ao1;
opto = 5*(opto./4095);
state = d.State;
licks = d.Licks;
wheel = d.Wheel;
trial_outcome = d.TrialOutcome;

state(state==8 | state==11) = 0;
go_trials = find(diff(state)==ttypes('goTrial'));
nogo_trials = find(diff(state)==ttypes('noGoTrial'));
pair_trials = find(diff(state)==ttypes('pairTrial'));

tot_trials = numel(go_trials) + numel(nogo_trials) + numel(pair_trials);
all_trials_ixs = [[ones(size(go_trials)); 2*ones(size(nogo_trials)); 3*ones(size(pair_trials))] ...
    [go_trials; nogo_trials; pair_trials]];
[~,ix] = sort(all_trials_ixs(:,2),'ascend');
all_trials_ixs = all_trials_ixs(ix,:);

if ~isempty(go_trials)
    fprintf('\nGo-NoGo Run detected')
    fprintf(['\n' num2str(numel(go_trials))  ' Go trials'])
    fprintf(['\n' num2str(numel(nogo_trials))  ' NoGo trials'])
elseif ~isempty(pair_trials)
    fprintf('\nPairing Run detected')
    fprintf(['\n' num2str(numel(pair_trials))  ' Pairing trials'])
else
    error('\nUnrecognized run type')
end

% find indices of early lick aborted trials
abort_trials = zeros(tot_trials,2);
all_outcomes = zeros(size(all_trials_ixs,1),1);
if any(trial_outcome==5)

    for i = 1:size(all_trials_ixs,1)-1
        outcome_win = trial_outcome(all_trials_ixs(i,2)+1:all_trials_ixs(i+1,2)-1);
        
        if any(outcome_win==5) % it was an abort
            abort_trials(i,1) = all_trials_ixs(i,2);
            abort_trials(i,2) = 1;
            all_outcomes(i) = 5;    
        else
            abort_trials(i,1) = all_trials_ixs(i,2);
            if max(outcome_win)==0
                keyboard
            end
            all_outcomes(i) = max(outcome_win);
        end
    end
    % last trial
    outcome_win = trial_outcome(all_trials_ixs(end,2):end);
    if any(outcome_win==5) % it was an abort
        abort_trials(end,1) = all_trials_ixs(i+1,2);
        abort_trials(end,2) = 1;
    else
        abort_trials(end,1) = all_trials_ixs(i+1,2);
    end
end

fprintf(['\n' num2str(sum(abort_trials(:,2))) ' aborted trials']);

if ~all(abort_trials(:,1) == all_trials_ixs(:,2))
    error('\ntrial indices are funky, might want to take a closer look')
end

all_trials_ixs = [all_trials_ixs(:,2) all_trials_ixs(:,1) abort_trials(:,2) all_outcomes];

beh = [];
% beh will be [piezo_amp opto_trl opto_t outcome rt];
all_go_licks = [];
% for each trial, get outcome
for i = 1:size(all_trials_ixs,1)-1
    ttype = all_trials_ixs(i,2);
    abrt = all_trials_ixs(i,3);
    b = [];
    if ~abrt
        if ttype == 1 % go trial

            trl_ixs = all_trials_ixs(i,1)+1:all_trials_ixs(i+1,1)-1;

            pz_win = piezo(trl_ixs);
            pz_amp = round(max(pz_win),2);
            pz_onset = find(diff(pz_win)>0,1,'first');

            opto_win = opto(trl_ixs);
            if max(opto_win) > 0
               opto_onset = find(diff(opto_win)>0,1,'first');
               opto_t = floor(1000*(pz_onset-opto_onset)/fs);
               opto_trl = 1;
            else
                opto_t = NaN;
                opto_trl = 0;
            end

            outcome = all_trials_ixs(i,4);
                    
            if outcome == 2 % it was a miss
                b = [pz_amp opto_trl opto_t 0 0];
            elseif outcome == 1 % it was a hit
                lk_win = licks(trl_ixs);
                all_go_licks = cat(2,all_go_licks,licks((pz_onset+trl_ixs(1))-2*fs:(pz_onset+trl_ixs(1))+5*fs));
                lk_ixs = find(diff(lk_win)>0);
                lk_ix = lk_ixs(find(lk_ixs>pz_onset & lk_ixs<= pz_onset+valid_response_win*fs,1,'first'));
                b = [pz_amp opto_trl opto_t 1 (lk_ix-pz_onset)./fs];
            else
                error('\nThere is a mismatch between the trial type and the outcome');
            end

        elseif ttype == 2 % no go

            trl_ixs = all_trials_ixs(i,1)+1:all_trials_ixs(i+1,1)-1; 

            outcome = all_trials_ixs(i,4);

            if outcome == 3 % it was a correct withold
                b = [0 opto_trl opto_t 2 0];
            elseif outcome == 4 % it eas a fa
                b = [0 opto_trl opto_t 3 0];
            else
                error('\nThere is a mismatch between the trial type and the outcome');
            end

        elseif ttype == 3 % pair

        end
        beh = cat(1,beh,b);
    end

end

%%
% beh will be [piezo_amp opto_trl opto_t outcome rt];

p_amps = unique(beh(:,1));
beh_summ = [];
for i = 1:numel(p_amps)
    pts = beh(beh(:,1)==p_amps(i),:);
    if p_amps(i)==0
        fa_rate = nnz(pts(:,4)==3)./(nnz(pts(:,4)==3)+nnz(pts(:,4)==2));
        b = [p_amps(i) fa_rate 0];
    else
        hit_rate = nnz(pts(:,4)==1)./(nnz(pts(:,4)==1)+nnz(pts(:,4)==0));
        rt = mean(pts(:,3),'omitnan');
        b = [p_amps(i) hit_rate rt];
    end
    beh_summ = cat(1,beh_summ,b);
end

figure,
subplot(1,2,1)
plot(beh_summ(:,1),beh_summ(:,2),'-ok')   
subplot(1,2,2)
plot(beh_summ(:,1),beh_summ(:,3),'-ok')   

all_go_licks(all_go_licks==0) = NaN;

pre_post = [-2 5];
lick_t = pre_post(1):1/fs:pre_post(2);
figure, hold
scatter(lick_t,all_go_licks+linspace(1,size(all_go_licks,2),size(all_go_licks,2)),'Marker','o','MarkerFaceColor','k','MarkerEdgeColor','none','MarkerFaceAlpha', 0.01)
xlim(pre_post)

end



