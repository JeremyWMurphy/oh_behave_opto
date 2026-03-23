function [] = oh_behave_opto()

%% parameters
config = struct();

config.teensy_fs = 2000; % teensy sample rate, Hz

% experiment parameters
config.baseln = 5; % length of pause at begining of each run, sec
config.n_trials = 200; % number of total trials to run -- there are many conditions, so this is a target, but do to rounding (always up, i.e., ceil()), there will be more than this number

%% key parameters
config.iti_len = [3 5];
config.prcnt_go_p_alone = 0.75; % percentage of trials that are go trials
config.prcnt_go_p_opto = 0.75; % percentage of trials that are go trials
config.prcnt_opto = 0.75;
% piezo
config.sig_amps = [0.1 0.2 0.3 0.4 0.6 0.8 1.1]; % amplitudes of stimuli, Volts
config.prcnt_amps = repmat(1/numel(config.sig_amps),1,numel(config.sig_amps)); % proportion of different amplitudes to present - needs to add to 1
% opto
config.opto_times = [-200 -75 -50 -25];

config.n_resets = Inf; % how many times to reset iti on early lick

config.play_error_sound = false; % play gross noise if early lick
config.error_timeout_len = 10; % on a FA give a timeout this longe, in seconds
config.play_hit_sound = false; % play chirp on hit
config.play_fa_sound = false; % play long gross noise if early lick
config.fa_timeout_len = [10 15]; % on a FA give a timeout this longe, in seconds


%% other parameters, more fixed

% initial teensy waveform stimulus parameters, currently fixed to Shin and
% Moore, 2019: whale, 6 ms rise, 20 ms fall, 20 Hz, 10 reps, 500 ms --
% actually 5 ms rise here
config.piezo_chan = '0';
config.pulse_type = '0'; % 0 = whale, 1 = square, 2 = rampup, 3 = rampdown, 4 = pyramid
config.pulse_len = '25'; % ms
config.pulse_intrvl = '0'; % ms
config.pulse_reps = '1';

% opto specific parameters
config.opto_chan = '1';
config.opto_amp = 3;
config.opto_pulse_type = '1'; % on teensy 1 = sqaure wave
config.opto_len = '50'; % ms

% Teensy parameters
config.serial_port = 'COM3';
config.up_every = 5000; % number of bytes to read in at a time
config.n_sec_disp = 10; % number of seconds to display on the graph

% sound parameters
config.sound_fs = 10e3;
% error sound
config.err_len = config.error_timeout_len;
config.err_amp = 0.1;
config.err_freq1 = 2500;
config.err_freq2 = 4500;
% FA sound
config.fa_len = config.fa_timeout_len;
config.fa_amp = 0.5;
config.fa_freq1 = 700;
config.fa_freq2 = 1000;
% hit  sound
config.hit_amp = 0.5;
config.hit_len = 0.05;
config.hit_freq1 = 250;
config.hit_freq2 = 1000;

% make feedback sounds
err_t = 1/config.sound_fs:1/config.sound_fs:config.err_len;
error_sound = config.err_amp*sin(2*pi*config.err_freq1*err_t) + sin(0.33*pi*config.err_freq2*err_t);
%
fa_t = 1/config.sound_fs:1/config.sound_fs:config.fa_len;
fa_sound = config.fa_amp*sin(2*pi*config.fa_freq1*fa_t) + sin(0.5*pi*config.fa_freq2*fa_t);
%
hit_t = 1/config.sound_fs:1/config.sound_fs:config.hit_len;
hit_sound = config.hit_amp.*chirp(hit_t,config.hit_freq1,hit_t(end),config.hit_freq2) .* gausswin(numel(hit_t))';

% Teensy parameters, *time should be in ms
config.tp.enforceEarlyLick = 1; % 1/0
config.tp.lickMax = 1; % uint
config.tp.waitForNextFrame = 0; % 1/0
config.tp.contingentStim = 0; % uint 0-3, or number of dac channels, zero index based
config.tp.trigLen = 200; % length of trigger broadcast/digital high, double, in seconds, but will be rounded to nearest integer of val * teensy_fs, e.g., 0.2112 * 2000 = 442 points or 0.221 sec 
config.tp.respLen = 1500; % length of response window from stim onset double, in seconds, but will be rounded to nearest integer of val * teensy_fs, e.g., 0.2112 * 2000 = 442 points or 0.221 sec 
config.tp.valveLen = 200;  % how long the valve opens on reward, double, in seconds, but will be rounded to nearest integer of val * teensy_fs, e.g., 0.2112 * 2000 = 442 points or 0.221 sec 
config.tp.consumeLen = 2500; % how much time to give between reward administration and starting the next trial, double, in seconds, but will be rounded to nearest integer of val * teensy_fs, e.g., 0.2112 * 2000 = 442 points or 0.221 sec   
config.tp.pairDelay =  0; % if doing pairing, offset between stim and reward, double, in seconds, but will be rounded to nearest integer of val * teensy_fs, e.g., 0.2112 * 2000 = 442 points or 0.221 sec   
config.tp.outLen =   1000; % length of time to braodcast an outcome of an early response, double, in seconds, but will be rounded to nearest integer of val * teensy_fs, e.g., 0.2112 * 2000 = 442 points or 0.221 sec   
config.tp.removeLen =  1000; % how long to open the valve for the vacuum to suck away reward
 
%% Make Trial structure

% make opto trials
n_opto_trials = ceil(config.n_trials * config.prcnt_opto);
n_opto_ttypes =  numel(config.sig_amps) * numel(config.opto_times);
trls = [];

ttype_dict = dictionary();
for i = 1:numel(config.opto_times)
    for j = 1:numel(config.sig_amps)
        ttype_dict((i*10) + j) = ['o:' num2str(config.opto_times(i)) ',p:' num2str(config.sig_amps(j))];
        n_tmp = ceil(((n_opto_trials*config.prcnt_go_p_opto)*config.prcnt_amps(j))/numel(config.opto_times));
        trls = [trls; ((i*10) + j) * ones(n_tmp,1)]; 
    end
end
ttype_dict(100) = 'opto alone';
trls = [trls; 100*ones(ceil(config.n_trials*(1-config.prcnt_go_p_opto)*config.prcnt_opto),1)];

% make piezo alone trials
n_nopto_trls = ceil(config.n_trials * (1-config.prcnt_opto));

for i = 1:numel(config.sig_amps)
    ttype_dict(i) = ['p alone:' num2str(config.sig_amps(i))];
    n_tmp = ceil((n_nopto_trls*config.prcnt_go_p_alone)*config.prcnt_amps(i));
    trls = [trls;i*ones(n_tmp,1)];
end
ttype_dict(0) = 'full catch';
trls = [trls; zeros(ceil(config.n_trials*(1-config.prcnt_go_p_alone)*(1-config.prcnt_opto)),1)];

%% convert voltages to 12 bit for dac
sig_amps_12bit = map_jm(config.sig_amps,0,5,0,4095);
opto_amp_12bit = map_jm(config.opto_amp,0,5,0,4095);

%% serial coms w/ teensy
% teensy state codes
teensy_reset =      '<S,1>';
teensy_go_trial =   '<S,2>';
teensy_nogo_trial = '<S,3>';
teensy_pairing_trial = '<S,4>';
teensy_trigger =    '<S,7>';
% connect to teensy
s = serialport(config.serial_port,115200);
pause(1);
% send the parameters that need to be set on teensy
set_teensy_parameters(s,config.tp);

%% make main gui figure
f = make_ui_figure(config.teensy_fs,config.n_sec_disp,s,config.sig_amps);
% get fig objs
tbs = get(f,'Children');
gl = tbs(1).Children(1).Children(1);
ax = gl.Children(1);
axb = gl.Children(2);
axc = gl.Children(3);
id_field = gl.Children(6);
pth_field = gl.Children(7);
notes = gl.Children(4);
hit_txt = gl.Children(20);
miss_txt = gl.Children(22);
cw_txt = gl.Children(24);
fa_txt = gl.Children(26);
el_txt = gl.Children(28);

%% Main
trial_is_done = false;

while f.UserData.state ~= 3

    if f.UserData.run_type == 4 % just stream the data

        s.flush;
        write_serial(s,teensy_reset); % resetting teensy
        ax.Title.String = 'live streaming, not saving...';
        s.configureCallback('byte',config.up_every, @(src,evt) justStream(src, evt, ax, config.up_every));
        present = 1;
        while present
            pause(0.1)
            if f.UserData.state == 2 || f.UserData.state == 3
                present = 0;
                ax.Title.String = 'Waiting to start';
                fprintf('\nAborted...\n')
                configureCallback(s,'off');
                f.UserData.run_type = 0;
            end
        end
        continue

    elseif f.UserData.state == 1 % detection or pairing run

        run_type = f.UserData.run_type;

        trl_cntr = 1;
        present = 1;

        %% setup data files
        id = [id_field.Value '_' char(datetime('now','format','yyyy-MM-dd''_T''HH-mm-ss'))];
        save_pth = [pth_field.Text '\' id];
        mkdir(save_pth);
        data_fid_stream = fopen([save_pth '\data_stream.csv'],'w');
        data_fid_notes = fopen([save_pth '\data_notes.csv'],'w');
        fprintf(data_fid_notes,id);
        
        % print all the parameters that we set above
        print_parameters(data_fid_notes,config);

        %% setup trial parameter distributions       
       
        trls = trls(randperm(size(trls,1)));

        s.flush;

        write_serial(s,teensy_reset); % resetting teensy

        s.configureCallback('byte',config.up_every, @(src,evt) plotSaveDataAvailable(src, evt, data_fid_stream, ax, config.up_every,f));

        % send triggers
        write_serial(s,teensy_trigger);

        fprintf(data_fid_notes,['\nRun Began at ' char(datetime('now','Format','HH:mm:ss'))]);

        n_resp_types = [0 0 0 0]; % piezo hits,misses,cws,fas
        p_hit = zeros(2,numel(config.sig_amps));
        axc.Children.XData = [0 config.sig_amps];
        axc.XTick = [0 config.sig_amps];
        axc.XLim = [0 config.sig_amps(end)];

        prior_was_error = false;
        n_reset_cnts = 0;
        reset_off = 0;

        while present % trial loop

            if trl_cntr == 1 && run_type == 1 && ~prior_was_error 
                fprintf(data_fid_notes,'\nDetection Task');
                pause(config.baseln)
            elseif trl_cntr == 1 && run_type == 2 && ~prior_was_error
                fprintf(data_fid_notes,'\nPairing Task');
                pause(config.baseln)
            end

            if prior_was_error
                prior_was_error = false; 
            end

            iti = round(1e3*(config.iti_len(1) + ((config.iti_len(2) - config.iti_len(1)) * rand(1))));

            trial_type = trls(trl_cntr);

            % set trial
            if trial_type >= 10 % it's an opto trial
                opto_idx = floor(trial_type/10);
                if opto_idx == 10 % it's an opto alone
                    opto_offset = 0;
                    is_go = false;
                    piezo_amp = 0;
                    o_amp = opto_amp_12bit;
                else
                    opto_offset = config.opto_times(opto_idx);
                    piezo_amp = sig_amps_12bit(rem(trial_type,10));
                    is_go = true;
                    o_amp = opto_amp_12bit;
                end
            else % it's piezo alone or a full catch
                if trial_type == 0 % it's a full catch
                    is_go = false;
                    o_amp = 0;
                    piezo_amp = 0;
                    opto_offset = 0;
                else
                  piezo_amp = sig_amps_12bit(trial_type);
                  is_go = true;
                  o_amp = 0;
                  opto_offset = 0;
                end
            end

            % set correct parameters for trial        
            % set piezo parameters
            msg_out = ['<W,' config.piezo_chan ',' config.pulse_type ',' config.pulse_len ',' num2str(piezo_amp) ',' config.pulse_intrvl ',' config.pulse_reps ',' num2str(iti) '>'];           
            write_serial(s,msg_out);
            % set opto parameters
            msg_out = ['<W,' config.opto_chan ',' config.opto_pulse_type ',' config.opto_len ',' num2str(o_amp) ',0,1,' num2str(iti+opto_offset) '>'];           
            write_serial(s,msg_out);

            fprintf(data_fid_notes,['\n Trial ' num2str(trl_cntr) ' ' char(datetime('now','Format','HH:mm:ss')) ', ' char(ttype_dict(trial_type))]);
            ax.Title.String = ['Trial ' num2str(trl_cntr) ', ' char(ttype_dict(trial_type))];

            % run appropriate trial type
            if run_type == 1
                if is_go
                    write_serial(s,teensy_go_trial);
                elseif ~is_go
                    write_serial(s,teensy_nogo_trial);
                end
            elseif run_type == 2
                write_serial(s,teensy_pairing_trial);
            else
                error('run type...')
            end
            
            while ~trial_is_done
                trial_is_done = f.UserData.TeensyDone;
                % wait for end of trial message from teensy before moving on
                % but make sure the serial callback has room to breath:
                pause(0.1)
                if f.UserData.state == 2 || f.UserData.state == 3 % this allows us to end the run or quit while waiting for trial outcome
                    break
                end
            end

            trial_outcome = f.UserData.trialOutcome;
            
            if reset_off % in the event we have enforce no licks and num resets is <Inf, we need to turn off enforce licks for this one trial is max licks has been reached
                write(s,'<P,1,1>','string');
                reset_off = 0;
            end

            % color GUI outcome text based on this trials outcome
            if trial_outcome == 1
                hit_txt.FontColor = [0 1 1];
                n_resp_types(1) = n_resp_types(1)+1;
                p_hit(1,piezo_amp==sig_amps_12bit) = p_hit(1,piezo_amp==sig_amps_12bit) + 1;
                if config.play_hit_sound
                    sound(hit_sound,config.sound_fs);
                end
                n_reset_cnts = 0;
            elseif trial_outcome == 2
                miss_txt.FontColor = [0 1 1];
                n_resp_types(2) = n_resp_types(2)+1;
                p_hit(2,piezo_amp==sig_amps_12bit) = p_hit(2,piezo_amp==sig_amps_12bit) + 1;
                n_reset_cnts = 0;
            elseif trial_outcome == 3
                cw_txt.FontColor = [0 1 1];
                n_resp_types(3) = n_resp_types(3)+1;
                n_reset_cnts = 0;
            elseif trial_outcome == 4
                fa_txt.FontColor = [0 1 1];
                n_resp_types(4) = n_resp_types(4)+1;
                if config.play_fa_sound
                    sound(fa_sound,config.sound_fs);
                end
                if config.fa_timeout_len>0
                   pause(round(config.fa_timeout_len(1) + ((config.fa_timeout_len(2) - config.fa_timeout_len(1)) * rand(1)),2));
                end
                n_reset_cnts = 0;
            elseif trial_outcome == 5 % early lick
                el_txt.FontColor = [0 1 1];
                trl_cntr = trl_cntr - 1; % redo last trial
                prior_was_error = true;
                n_reset_cnts = n_reset_cnts + 1;
                fprintf(['\n' num2str(n_reset_cnts)])
                if n_reset_cnts >= config.n_resets
                     % write(s,'<P,1,0>','string');
                     % reset_off = 1;                
                     if config.play_error_sound
                        sound(error_sound,config.sound_fs); 
                        pause(config.error_timeout_len);
                     end              
                     n_reset_cnts = 0;
                end
                
            end

            while trial_is_done % now wait until the whole trial (i.e., response, reward delivery, consume period, etc) is done
                trial_is_done = f.UserData.TeensyDone;
                % wait for end of trial message from teensy before moving on
                % but make sure the serial callback has room to breath:
                pause(0.1)
                if f.UserData.state == 2 || f.UserData.state == 3 % this allows us to end the run or quit while waiting for trial outcome
                    break
                end
            end

            % Change all outcome text back to gray, and track
            % performance
            hit_txt.FontColor = [0.5 0.5 0.5];
            miss_txt.FontColor = [0.5 0.5 0.5];
            cw_txt.FontColor = [0.5 0.5 0.5];
            fa_txt.FontColor = [0.5 0.5 0.5];
            el_txt.FontColor = [0.5 0.5 0.5];

            axb.Children.YData = n_resp_types;
            axb.Children.Labels = n_resp_types;
            axb.XLim = [0 max(n_resp_types(:))+0.1];
            axc.Children.YData =  [n_resp_types(4)/(n_resp_types(4)+n_resp_types(3)) p_hit(1,:)./(p_hit(1,:)+p_hit(2,:))];

            % print the outcome of the trial to file
            fprintf(data_fid_notes,[', Outcome = ' num2str(trial_outcome)'] );

            % check for run ending events
            if f.UserData.state == 2  % end the run
                ax.Title.String = 'Waiting to start';
                fprintf('\nAbort...')
                present = 0;
                configureCallback(s,'off');
                kill_run(s,data_fid_stream,data_fid_notes,notes);
            elseif trl_cntr > config.n_trials % end of run
                ax.Title.String = 'Task Complete';
                pause(3)
                ax.Title.String = 'Waiting to start';
                fprintf('\nEnd of run...')
                present = 0;
                configureCallback(s,'off');
                f.UserData.state = 2;
                kill_run(s,data_fid_stream,data_fid_notes,notes);
            elseif f.UserData.state == 3 % quit
                present = 0;
            end

            if trl_cntr > config.n_trials
                present = 0;
            end

            trl_cntr = trl_cntr + 1;

        end
    end

    pause(0.1)

end

%% end program
try exist(data_fid_stream,'var')
    kill_program(s,notes,data_fid_stream,data_fid_notes);
catch
    kill_program(s);
end

end

%% Supporting functions

%% end run function
function[] = kill_run(s,fid1,fid2,notes)

write(s,'<S,1>','string'); % reset
write(s,'<S,0>','string'); % idle

fprintf(fid2,['\nRun Ended at ' char(datetime('now','Format','HH:mm:ss')) '\n']);

for i = 1:size(notes.Value,1)
    fprintf(fid2,'%s\n',notes.Value{i});
end

fclose(fid1);
fclose(fid2);

end

%% program quit functions
function[] = kill_program(s,notes,fid1,fid2)

fprintf('\nQuitting...\n')

if nargin > 1

    for i = 1:size(notes.Value,1)
        fprintf(fid2,'%s\n',notes.Value{i});
    end
    % close files
    fclose(fid1);
    fclose(fid2);

end

%stop io
write(s,'<S,1>','string'); % reset
write(s,'<S,0>','string'); % idle
clear s

all_fig = findall(0, 'type', 'figure');
close(all_fig)

end

%% write to tensy
function[] = write_serial(s,msg)
write(s,msg,'string');
end