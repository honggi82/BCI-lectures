clear all; close all; clc;
addpath(genpath('E:\조선대\수업\2022년 1학기\바이오컴퓨팅특론\Matlab codes\SMR'));
 
%====================== 1. Parameter setting ======================
sf = 1000;                                  % Sampling frequency
ch_n = 62;                                  % Number of channels
wnd_size=[-1 4];                            % Window size
baseline=[-1 0];                            % Baseline
f_scale=1;                                  % Frequency interval for time-frequency analysis
freq_band=[0.1 100];                        % Frequency band for time-frequency analysis
normal=1;                                   % Normalization by the baseline
fullscreen=get(0,'ScreenSize');             % Size of the monitor screen
[position]=EEG_62ch_layout_Brain_Products;  % EEG channel positions

%====================== 2. Data load ======================
load('sess01_subj36_EEG_MI.mat'); % Loading training data
EEG = EEG_MI_train.x';            % For short name
EMG = EEG_MI_train.EMG';          % For short name
 
%====================== 3. Rereferencing (CAR)======================
EEG = EEG-repmat(mean(EEG,1), ch_n,1);

%====================== 4. Extract events ======================
events{1}=EEG_MI_train.t(find(EEG_MI_train.y_dec==1)); % Right hand
events{2}=EEG_MI_train.t(find(EEG_MI_train.y_dec==2)); % Left hand

% =================== 5. Epoching data =================== 
for i=1:length(events)         % Class number
    for tr=1:size(events{i},2) % Trials number 
        e_EEG{i}(:,:,tr) = EEG(:,round(events{i}(tr)+(wnd_size(1)*sf)):round(events{i}(tr)+(wnd_size(2)*sf)));
        e_EMG{i}(:,:,tr) = EMG(:,round(events{i}(tr)+(wnd_size(1)*sf)):round(events{i}(tr)+(wnd_size(2)*sf)));
    end
end
 
% =================== 6. Plotting signals =================== 
% Plotting EMG signals
for i=1:length(events)
    figure('Position',[0 0 fullscreen(3) fullscreen(4)]); % New window
    for tr=1:size(e_EEG{i},3)
        subplot(5,10,j);                % Plotting the figure at j-th on 5*10 matrix 
        plot(e_EMG{i}(:,:,j)');         % Plotting EMG of j-th trial and j-th task
        ylim([-600 600]);               % Limitation of the y-axis
        title(['Trial: ', num2str(j)]); % Title of the figure
    end
end

% Plotting EEG signals
for i = 1 : length(events)
    figure('Position',[0 0 fullscreen(3) fullscreen(4)]); % New window
    for j = 1 : length(events{i})
        subplot(5,10,j);                 % Plotting the figure at j-th on 5*10 matrix 
        plot(e_EEG{i}(:,:,j)');         % Plotting EMG of j-th trial and j-th task
        ylim([-600 600]);               % Limitation of the y-axis
        title(['Trial: ', num2str(j)]); % Title of the figure
    end
end

% =================== 7. Artifact removal =================== 
% Artifact trials of task 1 and 2
rem{1}=[4:7, 9:12,15,16,21,22,25,29,30,34,35,39,40,43,49];        
rem{2}=[1,2,4,5,10,11,12,15,16,18:21,23:28,31:33,37,37,41:45,50]; 

% Removal of artifact trials
for i = 1 : length(events)
    e_EEG{i}(:,:,rem{i})=[];    
    e_EMG{i}(:,:,rem{i})=[];
end

%% =================== Analysis =================== 
% =================== 8. time-frequency =================== 
t=linspace(wnd_size(1),wnd_size(2),size(m_TF,3)); % time
fr=linspace(freq_band(1), freq_band(2),size(m_TF,2)); % frequency

for i=1:length(events)
    for ch=1:size(e_EEG{i},1)
        for tr=1:size(e_EEG{i},3)
            TF{i}(ch,:,:,tr) = timefreq_anal(e_EEG{i}(ch,:,tr), sf, wnd_size, baseline,f_scale,freq_band, normal);
        end
    end
    fprintf(['Calculation of TF of task ', num2str(i), ' is finished\n']);
end

% Averaging the TF by trials
for i=1:length(events)
    m_TF(:,:,:,i)=squeeze(mean(TF{i},4)); 
end

% =================== 9. Whole channel time-frequency =================== 
figure('Position',[0 0 fullscreen(3) fullscreen(4)]);
for ch=1:size(e_EEG{i},1)
    subplot('Position', position(ch,:));
    pcolor(t,fr,squeeze(m_TF(ch,:,:,i))); 
    shading 'interp'; caxis([-0.5 0.5]); 
    % Line for Onset time
    x1=[0 0]; y1=freq_band; line(x1,y1,'Color','red', 'LineWidth', 1);    
end
 
% =================== 10. Topography=================== 
bpf=[8 26];                   % 8~26Hz
dur=([0 4]-wnd_size(1))*sf;   % 0~4 sec
for i=1:length(events)
    TP(:,i)=mean(mean(m_TF(:,bpf(1):bpf(2),dur(1):dur(2),i),3),2);
end
 
figure;
for i=1:length(events)
    subplot(1,4,i);topoplot(TP(:,i), 'Standard-10-20-Cap62_Brain_Products.locs','style','map', 'maplimits', [-0.3 0.3], 'whitebk','on', 'plotrad',0.548, 'headrad',0.5, 'shading','interp');
end

%% =================== Training =================== 
% =================== 8. Parameter setting ===================
bpf=[8 26];                   % Frequency for the band-pass filtering
dur=([0 4]-wnd_size(1))*sf;   % Duration for the feature extraction

% =================== 9. Band-pass filtering =================== 
for i=1:length(events)
    for ch=1:size(e_EEG{i},1)
        for tr=1:size(e_EEG{i},3)
            fil_EEG{i}(ch, :, tr)=bandpass(e_EEG{i}(ch, dur(1):dur(2), tr), bpf, sf); % Band-pass filtering
            P{i}(ch,tr)=mean(fil_EEG{i}(ch, :, tr).^2);                             % Power calculation
        end
    end
end

% Examining the data on the 13, 15 channels
figure; i=1; plot(P{i}(13,:),P{i}(15,:),'*'); hold on; i=2; plot(P{i}(13,:),P{i}(15,:),'ro');

% =================== 10. Training the classifier ===================
% Labeling the data
X_tr=[P{1}'; P{2}'];
Y_tr=[zeros(size(P{1},2),1); ones(size(P{2},2),1)];

% Training the SVM model
SVMModel = fitcsvm(X_tr,Y_tr,'KernelScale','auto','Standardize',true);

%% =================== Test =================== 
%====================== 2. Data load ======================
EEG_ts = EEG_MI_test.x';  % For short name
 
%====================== 3. Rereferencing (CAR)======================
EEG_ts = EEG_ts-repmat(mean(EEG_ts,1), ch_n,1);

%====================== 4. Extract events ======================
events_ts {1}=EEG_MI_test.t(find(EEG_MI_test.y_dec==1)); % right hand
events_ts {2}=EEG_MI_test.t(find(EEG_MI_test.y_dec==2)); % left hand

% =================== 5. Epoching data =================== 
for i=1:length(events_ts)         % Class number
    for tr=1:size(events_ts{i},2) % Trials number 
        e_EEG_ts{i}(:,:,tr) = EEG_ts(:,round(events_ts{i}(tr)+(wnd_size(1)*sf)):round(events_ts{i}(tr)+(wnd_size(2)*sf)));
    end
end

% =================== 6. Band-pass filtering =================== 
for i=1:length(events_ts)
    for ch=1:size(e_EEG_ts{i},1)
        for tr=1:size(e_EEG_ts{i},3)
            fil_EEG_ts{i}(ch, :, tr)=bandpass(e_EEG_ts{i}(ch, dur(1):dur(2), tr), bpf, sf); % Band-pass filtering
            P_ts{i}(ch,tr)=mean(fil_EEG_ts{i}(ch, :, tr).^2);                             % Power calculation
        end
    end
end

% Examining the data
figure; i=1; plot(P_ts{i}(13,:),P_ts{i}(15,:),'*'); hold on; i=2; plot(P_ts{i}(13,:),P_ts{i}(15,:),'ro');

% =================== 7. Classification =================== 
% Labeling the data
X_ts=[P_ts{1}'; P_ts{2}'];
Y_ts=[zeros(size(P_ts{1},2),1);ones(size(P_ts{2},2),1)];

% Prediction
label= predict(SVMModel, X_ts); 

% Accuracy
accuracy=(1-loss(SVMModel, X_ts, Y_ts))*100
