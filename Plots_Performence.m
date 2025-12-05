close all
clear
mice_all = {
    'C:\Users\XinHao\Desktop\WM_DualCircuit\CIBRZC213\yes_no_multipole_delay_autoTrain_Video_509\Session Data';...
    'C:\Users\XinHao\Desktop\WM_DualCircuit\CIBRZC214\yes_no_multipole_delay_autoTrain_Video_509\Session Data';...
    'C:\Users\XinHao\Desktop\WM_DualCircuit\CIBRZC220\yes_no_multipole_delay_autoTrain_Video_509\Session Data';...
    };

% the behavioral data for each mouse
for i_mice = 1: length(mice_all)
    micename=mice_all{i_mice};
    i_str = find(micename=='\');
    miceID=micename(i_str(5)+1:i_str(6)-1);
    mice_path=mice_all{i_mice}(1:i_str(6)-1);

    R_hit_allSession = [];
    R_miss_allSession = [];
    R_ignore_allSession = [];
    L_hit_allSession = [];
    L_miss_allSession = [];
    L_ignore_allSession = [];
    LickEarly_allSession = [];
    TrialnumLickamount_allSession=[];
    Protocol_allSession = [];
    Delay_Dur_allSession = [];
    Date_allSession = [];

    Bpod_filenames = dir(fullfile(mice_all{i_mice}, '*.mat'));
    Bpod_filenames = {Bpod_filenames.name}';
    % the behavioral data for each session
    for i_session = 1: length(Bpod_filenames)
        % --------------- load Bpod data -------------------
        load([mice_all{i_mice}, '\', Bpod_filenames{i_session}]);
        disp(Bpod_filenames{i_session});
        j_str=find(Bpod_filenames{i_session}=='_');
        day_curr = Bpod_filenames{i_session}(j_str(end-1)+1:j_str(end)-1);
        n_trials_curr = SessionData.nTrials;

        % --------------- get performance -------------------
        Outcomes = [];
        EarlyLicks = [];
        for x = 1:n_trials_curr
            if ~isempty(SessionData.TrialSettings(x).GUI) && SessionData.TrialSettings(x).GUI.ProtocolType>=3
                if ~isnan(SessionData.RawEvents.Trial{x}.States.Reward(1))
                    Outcomes(x) = 1;    % correct
                elseif ~isnan(SessionData.RawEvents.Trial{x}.States.TimeOut(1))
                    Outcomes(x) = 0;    % error
                elseif ~isnan(SessionData.RawEvents.Trial{x}.States.NoResponse(1))
                    Outcomes(x) = 2;    % no repsonse
                else
                    Outcomes(x) = 3;    % others
                end
            else
                Outcomes(x) = -1;        % others
            end

            if SessionData.TrialSettings(x).GUI.ProtocolType==5
                if ~isnan(SessionData.RawEvents.Trial{x}.States.EarlyLickSample(1)) || ~isnan(SessionData.RawEvents.Trial{x}.States.EarlyLickDelay(1))
                    EarlyLicks(x) = 1;    % lick early
                else
                    EarlyLicks(x) = 0;    % others
                end
            else
                EarlyLicks(x) = 0;        % others
            end
        end

        % SessionData.TrialTypes   % 0's (right) or 1's (left)
        R_hit = ((SessionData.TrialTypes==0) & Outcomes==1)';
        R_miss = ((SessionData.TrialTypes==0) & Outcomes==0)';
        R_ignore = ((SessionData.TrialTypes==0) & Outcomes==2)';
        L_hit = ((SessionData.TrialTypes==1) & Outcomes==1)';
        L_miss = ((SessionData.TrialTypes==1) & Outcomes==0)';
        L_ignore = ((SessionData.TrialTypes==1) & Outcomes==2)';
        LickEarly_all = (EarlyLicks==1)';

        trialnum=length(find(((~R_ignore)&(~L_ignore))==1));
        lickamount=0;
        for k=[find(R_hit==1);find(L_hit==1)]'
            wvt=SessionData.TrialSettings(k).GUI.WaterValveTime;
            rt=SessionData.RawEvents.Trial{k}.States.RewardConsumption;
            if R_hit(k)==1
                lickamount=lickamount+wvt*length(find(SessionData.RawEvents.Trial{k}.Events.Port2In>rt(1)&SessionData.RawEvents.Trial{k}.Events.Port2In<rt(2)));
            else
                lickamount=lickamount+wvt*length(find(SessionData.RawEvents.Trial{k}.Events.Port1In>rt(1)&SessionData.RawEvents.Trial{k}.Events.Port1In<rt(2)));
            end
        end
        TrialnumLickamount_allSession=[TrialnumLickamount_allSession;[str2double(day_curr),trialnum,lickamount]];

        Protocol_all = [];
        Delay_Dur_all = [];
        for x = 1:n_trials_curr
            if ~isempty(SessionData.TrialSettings(x).GUI)
                Protocol_all(x,1) = SessionData.TrialSettings(x).GUI.ProtocolType;
                Delay_Dur_all(x,1) = SessionData.TrialSettings(x).GUI.DelayPeriod;
            else
                Protocol_all(x,1) = -1;
                Delay_Dur_all(x,1) = -1;
            end
        end
        Date_all = ones(n_trials_curr,1)*str2num(day_curr);

        R_hit_allSession = [R_hit_allSession; R_hit];
        R_miss_allSession = [R_miss_allSession; R_miss];
        R_ignore_allSession = [R_ignore_allSession; R_ignore];
        L_hit_allSession = [L_hit_allSession; L_hit];
        L_miss_allSession = [L_miss_allSession; L_miss];
        L_ignore_allSession = [L_ignore_allSession; L_ignore];
        LickEarly_allSession = [LickEarly_allSession; LickEarly_all];
        Protocol_allSession = [Protocol_allSession; Protocol_all];
        Delay_Dur_allSession = [Delay_Dur_allSession; Delay_Dur_all];

        Date_allSession = [Date_allSession; Date_all];
        Trial_al = (R_hit|R_miss|L_hit|L_miss); % 只计算舔过的
        EL = LickEarly_all(Trial_al);
        if isempty(EL)
            EL_Rate(i_session) = NaN;
        else
            EL_Rate(i_session) = sum(EL) / length(EL);
        end
    end

    TrialNum_allSession = (1:length(Date_allSession))';
    days_all = sort(unique(Date_allSession));
    for i_day = 1:length(days_all)
        i_sel_trials = find(Date_allSession==days_all(i_day));
        n_trials = length(i_sel_trials);
        hit_iSession = (R_hit_allSession(i_sel_trials) | L_hit_allSession(i_sel_trials));
        hitmiss_iSession=(R_hit_allSession(i_sel_trials) | L_hit_allSession(i_sel_trials)|R_miss_allSession(i_sel_trials) | L_miss_allSession(i_sel_trials));
        DayPerf(i_day,1) = sum(hit_iSession)/sum(hitmiss_iSession);

        % 基于所有 trials 计算
        % TrialNum_iSession = TrialNum_allSession(i_sel_trials);
        % EarlyLick_iSession = LickEarly_allSession(i_sel_trials);
        % earlyLick_Rate(i_day) = (sum(EarlyLick_iSession)/length(EarlyLick_iSession));
    end

    figure;
    subplot(2, 1, 1); %  plot performance
    plot(1:length(DayPerf),DayPerf(:,1),'Color','b');hold on;
    ylim([0 1]);
    yline(0.7, '--k', 'LineWidth', 1.5);
    xlabel('Session');
    ylabel('Performance');

    subplot(2, 1, 2);  % plot early lick rate
    plot(1:length(EL_Rate'),EL_Rate','Color','b');hold on;
    xlim([1 length(days_all)]);
    ylim([0 1]);
    xlabel('Session');
    ylabel('Early lick rate');
    i_trial_final_param = find(Delay_Dur_allSession == 1.3, 1, 'first'); 
    if ~isempty(i_trial_final_param)
        day_of_trial = Date_allSession(i_trial_final_param);
        session_idx = find(days_all == day_of_trial);
        line([session_idx session_idx], [0 1], 'color','r', 'linestyle', ':', 'linewidth', 2);
    end
    sgtitle(miceID);

    saveas(gcf, fullfile(mice_path, 'Perf.png'));
    close(gcf);
    clearvars -except mice_all i_mice
end