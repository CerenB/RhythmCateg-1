function [seq] = makeStimTrain(cfg,currPatterni,cueDBleveli)


% add parameters to output structure 
seq                 = []; 
seq.fs              = cfg.fs; 
seq.pattern         = cfg.patterns{currPatterni}; 
seq.cueDB           = cfg.cueDB(cueDBleveli); 
seq.cue             = repmat([1,zeros(1,cfg.cuePeriod(currPatterni)-1)],...
                                1,floor(length(seq.pattern)/cfg.cuePeriod(currPatterni))); 
seq.nCycles         = cfg.nCyclesPerWin; 
seq.dur             = length(seq.pattern)*seq.nCycles*cfg.gridIOI; 
seq.nSamples        = round(seq.dur*seq.fs); 



% set the requested cue dB
rmsBeat = rms(cfg.soundBeat);
cfg.soundBeat = cfg.soundBeat/rmsBeat * rmsBeat*10^(seq.cueDB/20); 

rmsGrid = rms(cfg.soundGrid); 
cfg.soundGrid = cfg.soundGrid/rmsGrid * rmsGrid*10^(seq.cueDB/20); 

% further attenuate grid sound (fixed attenuation)
cfg.soundGrid = cfg.soundGrid * 1/4; 



% generate pattern sequence
seqPattern = zeros(1,seq.nSamples); 
sPatIdx = round( (find(repmat(seq.pattern,1,seq.nCycles))-1) * cfg.gridIOI * seq.fs ); 
for i=1:length(sPatIdx)   
    seqPattern(sPatIdx(i)+1:sPatIdx(i)+length(cfg.soundPattern)) = cfg.soundPattern; 
end

% generate metrononme sequence
seqBeat = zeros(1,seq.nSamples); 
sBeatIdx = round( (find(repmat(seq.cue,1,seq.nCycles))-1) * cfg.gridIOI * seq.fs ); 
for i=1:length(sBeatIdx)   
    seqBeat(sBeatIdx(i)+1:sBeatIdx(i)+length(cfg.soundBeat)) = cfg.soundBeat; 
end

% generate grid sequence
seqGrid = zeros(1,seq.nSamples); 
sGridIdx = round( (find(ones(1,seq.nCycles*length(seq.pattern)))-1) * cfg.gridIOI * seq.fs ); 
for i=1:length(sGridIdx)   
    seqGrid(sGridIdx(i)+1:sGridIdx(i)+length(cfg.soundGrid)) = cfg.soundGrid; 
end

% add them together
seq.s = seqPattern + seqBeat + seqGrid; 


% check sound amplitude for clipping
if max(abs(seq.s))>1 
    warning('sound amplitude larger than 1...normalizing'); 
    seq.s = seq.s./max(abs(seq.s)); 
end






% % create pure tone and save as audio sample
% seq.rampon = 0.010; 
% seq.rampof = 0.050; 
% seq.tone_dur = 0.100; 
% seq.tone_f0 = 440; 
% 
% env_event = ones(1,round(seq.tone_dur*seq.fs)); 
% env_event(1:round(seq.rampon*seq.fs)) = linspace(0,1,round(seq.rampon*seq.fs)) .* env_event(1:round(seq.rampon*seq.fs)); 
% env_event(end-round(seq.rampof*seq.fs)+1:end) = linspace(1,0,round(seq.rampof*seq.fs)) .* env_event(end-round(seq.rampof*seq.fs)+1:end); 
% t_event = [0:length(env_event)-1]/seq.fs; 
% s_event = sin(2*pi*t_event*seq.tone_f0); 
% s_event = s_event .* env_event; 
% 
% audiowrite('./stimuli/tone440Hz_10-50ramp.wav',s_event,seq.fs)


