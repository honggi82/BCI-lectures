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
bpf=[1 50];                                 % Frequency for the band-pass filtering
ds=10;                                      % Down sampling number
freq_band=[1 100];                          % Frequency band for time-frequency analysis
normal=1;                                   % Normalization by the baseline
freq = [12, 8.57, 6.67, 5.45];              % Target frequency
chan = 29:31;                               % channels used for prediction
fullscreen=get(0,'ScreenSize');             % Size of the monitor screen
[position]=EEG_62ch_layout_Brain_Products;  % EEG channel positions

% ====================== 2. Loading data ======================
load('sess01_subj36_EEG_SSVEP.mat');
EEG = EEG_SSVEP_train.x';            % For short name

% ====================== 3. Rereferencing (CAR) ======================
EEG = EEG-repmat(mean(EEG,1), ch_n,1);

% ====================== 4. Band-pass filtering =================== 
f_EEG=bandpass(EEG', bpf, sf)'; 

% ====================== 5. Extracting events ======================
events = EEG_SSVEP_train.t; % Event time

% ====================== 6. Epoching data =================== 
for tr=1:size(events,2) % Trials number 
    e_EEG(:,:,tr) = f_EEG(:,round(events(tr)+(wnd_ft(1)*sf)):round(events(tr)+(wnd_ft(2)*sf)));
end

% ====================== 7. Down sampling======================
for ch=1:ch_n % Channel number
    for tr=1:size(events,2) % Trials number 
        d_EEG(ch,:,tr)=downsample(e_EEG(ch,:,tr),ds); % EEG downsampling
    end
end

% ====================== 8. CNN ======================
r_fil_sz = 3;   % Filter size of row
c_fil_sz = 10;  % Filter size of column
n_fil = 30;     % Number of filters
r_str = 1;      % Stride of row
c_str = 2;      % Stride of column 
pl = 2;         % Number of down sampling using the pooling layers
n_class = 4;    % Number of classes

layers = [
    imageInputLayer([size(d_EEG,1) size(d_EEG,2) 1])
    convolution2dLayer([r_fil_sz c_fil_sz], n_fil, 'Stride', [r_str c_str] , 'Padding','same')
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer([1 pl],'Stride',2)
    convolution2dLayer([r_fil_sz c_fil_sz], n_fil, 'Stride', [r_str c_str] , 'Padding','same')
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer([1 pl],'Stride',2)
    convolution2dLayer([r_fil_sz c_fil_sz], n_fil, 'Stride', [r_str c_str] , 'Padding','same')
    batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(n_class)
    softmaxLayer
    classificationLayer];

options = trainingOptions('sgdm', ...
    'InitialLearnRate',0.01, ...
    'LearnRateDropPeriod',10, ...
    'MaxEpochs',30, ...
    'MiniBatchSize',10, ...
    'Shuffle','every-epoch', ...
    'Verbose',false, ...
    'Plots','training-progress');

X=reshape(d_EEG, size(d_EEG,1), size(d_EEG,2),1, size(d_EEG,3));
Y=categorical(EEG_SSVEP_train.y_dec');

% Training the CNN
net = trainNetwork(X,Y,layers,options);

%% =================== Test =================== 
% ====================== 2. Loading data ======================
EEG_ts = EEG_SSVEP_test.x';            % For short name

% ====================== 3. Rereferencing (CAR)======================
EEG_ts = EEG_ts-repmat(mean(EEG_ts,1), ch_n,1);

% ====================== 4. Band-pass filtering =================== 
f_EEG_ts=bandpass(EEG_ts', bpf, sf)'; % Band-pass filtering

% ====================== 5. Extracting events ======================
events_ts = EEG_SSVEP_test.t; % Event time

% ====================== 6. Epoching data =================== 
for tr=1:size(events_ts,2) % Trials number 
    e_EEG_ts(:,:,tr) = f_EEG_ts(:,round(events_ts(tr)+(wnd_ft(1)*sf)):round(events_ts(tr)+(wnd_ft(2)*sf)));
end

% ====================== 7. Down sampling======================
for ch=1:ch_n % Channel number
    for tr=1:size(events_ts,2) % Trials number 
        d_EEG_ts(ch,:,tr)=downsample(e_EEG_ts(ch,:,tr),ds); % EEG downsampling
    end
end

% ====================== 8. CNN ======================
X_ts=reshape(d_EEG_ts, size(d_EEG_ts,1), size(d_EEG_ts,2),1, size(d_EEG_ts,3));
Y_ts=categorical(EEG_SSVEP_test.y_dec');

YPred= classify(net,X_ts);

accuracy = sum(YPred== Y_ts)/length(Y_ts)
fname = ['f_',num2str(f),'_conv_',num2str(r_fil_sz),'_fil_',num2str(c_fil_sz),'_n_',num2str(n_fil),'_r_',num2str(r_str),'_c_',num2str(c_str),'_ds_',num2str(ds), '.mat']; save(fname, 'accuracy');

