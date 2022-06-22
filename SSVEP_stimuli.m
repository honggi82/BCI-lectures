% "SSVEP_stimuli" is a function to present SSVEP visual stimuli 
% programed by Hong Gi Yeom at Chosun University 2022.06.03
% Inputs of the function should be stimulus frequencies, and positions
% ex)
% stim_Hz=[5 6 7 8]; % Frequencies of the stimuli. Unit is Hz
% stim_pos=[0.4, 0.1; 0.7 0.4; 0.4 0.7; 0.1 0.4]; % Positions of the stimuli
% ex_time = 10; % execution time. Unit is second
% % the values of the stim_pos range from 0 to 1
% run "SSVEP_stimuli(stim_Hz, stim_pos, ex_time);"

function SSVEP_stimuli(stim_Hz, stim_pos, ex_time)

width=0.2; % width of the stimuli
height=0.2; % height of the stimuli
refresh=60; % refresh rate of the computer monitor 

% Stimulus signal generation
t=1/refresh:1/refresh:1;
for s=1:length(stim_Hz)
    sig(s,:)=round((sin(2*pi*stim_Hz(s)*t)+1)/2)+1;
end
%figure;for s=1:length(stim_Hz);subplot(length(stim_Hz),1,s); plot(sig(s,:));end

% Pattern of the stimulus
pattern(1,:,:)=[0,1,0,1; 
        1,0,1,0;
        0,1,0,1; 
        1,0,1,0];
pattern(2,:,:)=~pattern(1,:,:);

% Subplot positions of the stimuli
for s=1:size(stim_pos,1)
    pos(s,:)=[stim_pos(s,1), 1-stim_pos(s,2)-height, width, height];
end

figure; set(gcf,'Color','k'); colormap('gray');
for s=1:size(pos,1)
    subplot('Position', pos(s,:));
    sp(s)=imagesc(squeeze(pattern(sig(s,1),:,:)));
    set(gca,'xtick',[],'ytick',[]); 
end

% using a timer
tm = timer('TimerFcn', 'Plot_SSVEP_stimuli(pattern, sig, sp, t); t=t+1; if t>refresh;t=1;end ');
tm.Period = 1/refresh;
tm.ExecutionMode = 'fixedRate';
tm.TasksToExecute = refresh*ex_time;
start(tm)
