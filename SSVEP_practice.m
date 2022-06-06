clear all; close all; clc;
%addpath(genpath('E:\data\각종 data\공개 데이터\이성환 교수\SSVEP_SMR Data\SSVEP'));
addpath(genpath('E:\조선대\수업\2022년 1학기\바이오컴퓨팅특론\Matlab codes'));

% ====================== 1. Parameter setting ======================
sf = 1000;                                  % Sampling frequency
ch_n = 62;                                  % Number of channels
wnd_size=[-1 4];                            % Window size
baseline=[-1 0];                            % Baseline
wnd_ft=[0 4];                               % Window size for the feature extraction
f_scale=1;                                  % Frequency interval for time-frequency analysis
freq_band=[1 100];                          % Frequency band for time-frequency analysis
normal=1;                                   % Normalization by the baseline
freq = [12, 8.57, 6.67, 5.45];              % Target frequency
chan = 29:31;                               % channels used for prediction
fullscreen=get(0,'ScreenSize');             % Size of the monitor screen
[position]=EEG_62ch_layout_Brain_Products;  % EEG channel positions

% ====================== 2. Loading data ======================
load('sess01_subj36_EEG_SSVEP.mat');
EEG = EEG_SSVEP_train.x'; % For short name

% ====================== 3. Rereferencing (CAR)======================
EEG = EEG-repmat(mean(EEG,1), ch_n,1);

%% =================== Analysis =================== 
% ====================== 4. Extracting events ======================
for i=1:length(freq)         % Class number
    events{i}=EEG_SSVEP_train.t(find(EEG_SSVEP_train.y_dec==i)); % Target
end

% ====================== 5. Epoching data =================== 
for i=1:length(freq)           % Class number
    for tr=1:size(events{i},2) % Trials number 
        e_EEG{i}(:,:,tr) = EEG(:,round(events{i}(tr)+(wnd_size(1)*sf)):round(events{i}(tr)+(wnd_size(2)*sf)));
    end
end

% ====================== 6. Power spectrum analysis =================== 
ft_intv =(wnd_ft(1)-wnd_size(1))*sf:(wnd_ft(2)-wnd_size(1))*sf; % interval for features
N=length(ft_intv);                               % length of the EEG signal
fr=0:sf/N:sf/2;                                  % Frequency values
for i=1:length(freq)                             % Class number
    for tr=1:size(events{i},2)                   % Trials number 
        temp=abs(fft(e_EEG{i}(:,ft_intv,tr)'));  % Absolute FFT of EEG signals
        PS{i}(:,:,tr)=log10(temp(1:N/2+1,:)');   % Log scale of the FFT
    end
end

figure; hold on;
plot(fr,mean(PS{1}(30,:,:),3),'r'); 
plot(fr,mean(PS{2}(30,:,:),3),'g'); 
plot(fr,mean(PS{3}(30,:,:),3),'b'); 
plot(fr,mean(PS{4}(30,:,:),3),'k'); 
xlim([0 30]);

% ====================== 7. FTF analysis =================== 
for i=1:length(freq)         % Class number
    data(:,:,:,i)=e_EEG{i};
end
[BW TF]=FTF_anal(data, sf, wnd_size, baseline,f_scale,freq_band, normal, 0); % F-value

ti=wnd_size(1):1/sf:wnd_size(2); % Time for the FTF plot
fr=freq_band(1):f_scale:freq_band(2); % Frequency for the FTF plot

figure('Position',[0 0 fullscreen(3) fullscreen(4)]);
for ch=1:ch_n 
    subplot('Position', position(ch,:));
    pcolor(ti,fr,squeeze(BW(ch,:,:))); shading 'interp'; caxis([0 5]); 
    x1=[0 0];y1=freq_band;line(x1,y1,'Color','red', 'LineWidth', 1)
end
set(gcf,'Color','w');


%% =================== Test =================== 
% ====================== 2. Loading data ======================
EEG_ts = EEG_SSVEP_test.x'; % For short name

% ====================== 3. Rereferencing (CAR)======================
EEG_ts = EEG_ts-repmat(mean(EEG_ts,1), ch_n,1);

% ====================== 4. Extracting events ======================
events_ts=EEG_SSVEP_test.t; % Event time

% ====================== 5. Epoching data =================== 
for tr=1:size(events_ts,2) % Trials number 
    e_EEG_ts(:,:,tr) = EEG_ts(:,round(events_ts(tr)+(wnd_ft(1)*sf)):round(events_ts(tr)+(wnd_ft(2)*sf)));
end

% ====================== 6. CCA =================== 
t=1/sf:1/sf:size(e_EEG_ts,2)/sf;
for i=1:length(freq)         % Class number
    y{i} = [sin(2*pi*freq(i)*t);
              cos(2*pi*freq(i)*t);
              sin(4*pi*freq(i)*t);
              cos(4*pi*freq(i)*t);
              sin(6*pi*freq(i)*t);
              cos(6*pi*freq(i)*t)];
end

for tr=1:size(events_ts,2) % Trials number 
    for i=1:length(freq)         % Class number
        [~,~,temp] = canoncorr(e_EEG_ts(chan,:,tr)',y{i}');
        corr(i) = max(temp);   % Correlation between EEGs and sinusoidal harmonics of the i-th frequency
        clear temp
    end
    [~,pred(tr)]=max(corr); % Prediction results
    clear corr
end

% Accuracy
accuracy=mean(EEG_SSVEP_test.y_dec==pred)

