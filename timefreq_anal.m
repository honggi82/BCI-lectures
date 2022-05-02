% Time-frequency analysis
% 'TF' is time-frequency spectra of data. 
% 'TF' will be a matrix (time * frequency)
% 'data' should be a vector
% 'sf' is a sampling rate
% 'wnd_size' is a window size of data
% 'baseline' is a period for baseline correction of analysis
% 'f_scale' is a freqeuncy resolution of analysis
% 'freq_band' is a frequency band of analysis
% Set 'normal' to 1 if you want to normalize the spectrum values depending on baseline
%
% Copyright Hong Gi Yeom
% You can use this code for academic purpose
%
% Examples:
%
%  sf = 1000
%  wnd_size = [-1 3]
%  baseline = [-1 0]
%  f_scale = 1
%  freq_band = [1 100]
%  normal = 1
%  TF = timefreq_anal(data, sf, wnd_size, baseline,f_scale, freq_band, normal)

function TF = timefreq_anal(data, sf, wnd_size, baseline,f_scale, freq_band, normal)

wname = 'cmor2.48-1';

if nargin<5
    f_scale=1;
    freq_band = [1, 100];
    normal=0;
elseif nargin<6
    freq_band = [1, 100];
    normal=0;
elseif nargin<7
    normal=0;    
end
target_f = freq_band(1):f_scale:freq_band(2); 

timefreq=abs(cwt(data, sf./target_f, wname));
start_bs=ceil((baseline(1)-wnd_size(1))*sf)+1;
end_bs=ceil((baseline(2)-wnd_size(1))*sf);
base=timefreq(:,start_bs:end_bs);
bs=mean(base,2);
bs_std=std(base');

if normal==1
    TF=(timefreq-repmat(bs,1,size(timefreq,2)))./repmat(bs_std',1,size(timefreq,2));
else
    TF=timefreq-repmat(bs,1,size(timefreq,2));
end 