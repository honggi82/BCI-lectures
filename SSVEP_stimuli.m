% "SSVEP_stimuli" is a function to present SSVEP visual stimuli 
% programed by Hong Gi Yeom at Chosun University 2022.06.03
% Inputs of the function should be stimulus frequencies, and positions
% ex)
% stim_Hz=[5 6 7 8]; % Frequencies of the stimuli, Unit is Hz
% stim_pos=[0.4, 0.1; 0.7 0.4; 0.4 0.7; 0.1 0.4]; % Positions of the stimuli
% % the values of the stim_pos range from 0 to 1
% run "SSVEP_stimuli(stim_Hz, stim_pos);"

function SSVEP_stimuli(stim_Hz, stim_pos)

width=0.2;            % Width of the stimuli
height=0.2;           % Height of the stimuli
refresh=60;           % Refresh rate of the computer monitor 
resolution=[800 800]; % Resolution of the stimulus screen 

% Stimulus signal generation
t=1/refresh:1/refresh:1;
for s=1:length(stim_Hz)
    sig(s,:)=round((sin(2*pi*stim_Hz(s)*t)+1)/2);
end

% Pattern of the stimulus
pattern(1,:,:)=[0,1,0,1; 
                1,0,1,0;
                0,1,0,1; 
                1,0,1,0];
pattern(2,:,:)=~pattern(1,:,:);

stim=zeros(100);
% Subplot positions of the stimuli
for s=1:size(stim_pos,1)
    x_st(s)=round(100*stim_pos(s,1));           % start position of x for the s-th stimulus
    x_end(s)=round(100*(stim_pos(s,1)+width));  % end position of x for the s-th stimulus
    y_st(s)=round(100*stim_pos(s,2));           % start position of y for the s-th stimulus
    y_end(s)=round(100*(stim_pos(s,2)+height)); % end position of y for the s-th stimulus
end

% Upscaling the pattern 
pattern_up(1,:,:)=kron(squeeze(pattern(1,:,:)), ones([round((x_end(1)-x_st(1)+1)/size(pattern,2)) round((y_end(1)-y_st(1)+1)/size(pattern,3))]));
pattern_up(2,:,:)=kron(squeeze(pattern(2,:,:)), ones([round((x_end(1)-x_st(1)+1)/size(pattern,2)) round((y_end(1)-y_st(1)+1)/size(pattern,3))]));
sz_pt= size(pattern_up);

figure('Position',[0 0 resolution(1) resolution(2)]); set(gcf,'Color','k'); colormap('gray');
t=1;

while (1)
    
    tic;
    % Generating the stimulus image
    for s=1:size(stim_pos,1)
        if sig(s,t)==0
            stim(y_st(s):y_st(s)+sz_pt(3)-1,x_st(s):x_st(s)+sz_pt(2)-1)=pattern_up(1,:,:);
        else
            stim(y_st(s):y_st(s)+sz_pt(3)-1,x_st(s):x_st(s)+sz_pt(2)-1)=pattern_up(2,:,:);
        end
    end
    
    % Plotting the stimulus
    imagesc(stim);
    set(gca,'xtick',[],'ytick',[]); 
    if t<refresh
        t=t+1;
    else
        t=1;
    end
    
    % update the figures
    drawnow 
    del=toc;
    
    pause(1/refresh-del);
end
