function seq = makeSequence(cfg,seqi,varargin)
% This function constructs a stimulus sequence.
% by using makeStimMainExp.m script

% it's also depending on getAllSeqDesign.m output with the given 
% run number==seqi (fmri) or expParam.numSequences == seqi (behav)


% ------
% INPUT
% ------
%     cfg:          structure with confuguration info
%     seqi:         sequence iterator index (which sequence in the
%                   experiment this is?)
% 
% ------
% OUTPUT
% ------
%     seq:          structure with stimulus sequence and info about it
%
%

if cfg.debug.do
    seqi = 1;
end
    
%% allocate variables to log

% main output structure (we'll put everything else into it)
seq = struct(); 

% vector of F0 (pitch) values for each pattern in the sequence
seq.F0 = zeros(1, cfg.pattern.nPatternPerSegment * ...
    cfg.pattern.nSegmPerStep * cfg.pattern.nStepsPerSequence); 

% vector of gridIOI values for each pattern in the sequence
seq.gridIOI = zeros(1, cfg.pattern.nPatternPerSegment * ...
    cfg.pattern.nSegmPerStep * cfg.pattern.nStepsPerSequence); 

% segment-category (A or B) for each pattern in the sequence 
seq.segmentCateg = cell(1, cfg.pattern.nPatternPerSegment * ...
    cfg.pattern.nSegmPerStep * cfg.pattern.nStepsPerSequence); 

% onset time of each pattern
% i'm still conflicting how to make this onset both BIDS compatible &
% explicit that it's PATTERN ONSET WE ARE RECORDING
seq.onset = nan(1, cfg.pattern.nPatternPerSegment * ...
    cfg.pattern.nSegmPerStep * cfg.pattern.nStepsPerSequence); 

% put together all the patterns from both categories, we will pick from
% this using the unique ID of each pattern (we know which IDs we want from
% the output of getAllSeq function. 
patterns2choose = [cfg.pattern.patternA,cfg.pattern.patternB]; 


% each pattern will have its own ID (integer number; patterns with the same
% ID number from category A vs. B will have the same inter-onset intervals,
% just rearranged in time)

% TL: I know the same thing is saved twice (i.e. the category information is, saved 
% in the "category" colum, but is also in the rhythm ID string. But I'd perhaps keep this
% redundancy for the sake of safety :) Because this way I can directly check if there is
% any discrepancy between what the script thinks is category A and the
% actual patterns that are used for that category. So this info is primarily for visual
% checking that the script is doing what it's meant to. If I need the
% rhythm ID number at any point I can always get it out of the string with regexp. 

seq.patternID = cell(1, cfg.pattern.nPatternPerSegment * ...
    cfg.pattern.nSegmPerStep * cfg.pattern.nStepsPerSequence); 


% audio waveform of the sequence
seq.outAudio = zeros(1,round(cfg.pattern.SequenceDur*cfg.fs)); 

% % audio envelop  of the sequence
% seq.outEnvelop = zeros(1,round(cfg.pattern.SequenceDur*cfg.fs)); 

% carries pitches length 
numPitch = cfg.pattern.nF0;

%% initialize counters 

% currently chosen F0 index (indexing value in cfg.pattern.F0s, initialize to 1)
currF0idx = 1; 

% currently chosen gridIOI index (indexing value in cfg.pattern.gridIOIs, initialize to 1)
currGridIOIidx = 1; 

% pattern counter (over the whole sequence)
cPat = 1; 

% current time point in the sequence as we go through the loops
currTimePoint = 0; 

% pitch counter 
cPitch = 1;

%% loop over steps
for stepi=1:cfg.pattern.nStepsPerSequence
    
    
    % take the timestamp for logging the current step time
    stepOnset  = currTimePoint;
    
    
    %% loop over segments in 1 sequence
    % to make 
    for segmi=1:cfg.pattern.nSegmPerStep
        
        % take the  timestamp for logging the current segment time
        segmentOnset  = currTimePoint;
        
%         % Determine which segment category this is (A or B), 
%         % the first 'cfg.pattern.nSegmentA' segments will be category A, 
%         % the rest will be B
%         if ismember(segmi, [1:cfg.pattern.nSegmentA])            
%             currCategLabel = cfg.pattern.labelCategA; 
%             currSegmentLabel = cfg.pattern.labelSegmentA;
%             
%         else
%             currCategLabel = cfg.pattern.labelCategB; 
%             currSegmentLabel = cfg.pattern.labelSegmentB;
%         end
        
        
        
        %% loop over pattern cycles in 1 segment
        % to create a segment
        for pati=1:cfg.pattern.nPatternPerSegment
            
            
            % --------------------------------------------------
            % ---- read current pattern from SequenceDesign ----
            % --------------------------------------------------
            
            % find the pattern ID from the seqDesignFullExp (output of
            % getAllSeq function)
            currPatID = cfg.pattern.seqDesignFullExp{seqi,stepi,segmi,pati}; 
            currPatIdx = find(strcmp(currPatID,{patterns2choose.ID}));

            % find if this pattern categ, simple or complex
            currPatternCateg = regexp(patterns2choose(currPatIdx(1)).ID, '\D*(?=\d.*)', 'match'); 
            currPatternCateg = currPatternCateg{1}; 
            currCategLabel = currPatternCateg;
            
            %find segment info, if it's A/B
            currSegmentLabel = cfg.pattern.seqDesignSegment{seqi,stepi,segmi,pati}; 
            
            % --------------------------------------------------
            % ----- determine if gridIOI needs to be changed ---
            % --------------------------------------------------
            CHANGE_IOI = 0; 
            
            % gridIOI change requested every segment (and this is the first
            % cycle in the segment)
            if cfg.pattern.changeGridIOISegm && pati == 1
                CHANGE_IOI = 1; 
                
            % gridIOI change requested every category (and this is the first
            % cycle in the segment, and a category just changed from A->B
            % or B->A)
            elseif cfg.pattern.changeGridIOICategory && pati == 1 && ...
                    ( segmi == 1 || segmi == cfg.pattern.nSegmentA+1 )
                CHANGE_IOI = 1; 
                
            % gridIOI change requested every step 
            elseif cfg.pattern.changeGridIOIStep && segmi==1
                CHANGE_IOI = 1; 
                
            end
                        
            % if change of gridIOI requested, randomly choose a new gridIOI
            % do this only if there is more than 1 gridIOI to choose from
            if CHANGE_IOI && length(cfg.pattern.gridIOIs)>1
                % get gridIOI to choose from 
                gridIOI2ChooseIdx = 1:length(cfg.pattern.gridIOIs); 
                % remove gridIOI used in the previous iteration (to prevent
                % repetition in the sequence) 
                gridIOI2ChooseIdx(gridIOI2ChooseIdx==currGridIOIidx) = []; 
                % randomly select new IOI
                currGridIOIidx = randsample(gridIOI2ChooseIdx); 
            end
            
            currGridIOI = cfg.pattern.gridIOIs(currGridIOIidx); 
            
            
            % --------------------------------------------------
            % ----- determine if pitch needs to be changed -----
            % --------------------------------------------------
            CHANGE_PITCH = 0; 
            
            % pitch change requested in every pattern cycle
            if cfg.pattern.changePitchCycle
                CHANGE_PITCH = 1; 
                
            % pitch change requested in every segment (and this is the first
            % pattern cycle in the segment)
            elseif cfg.pattern.changePitchSegm && pati==1
                CHANGE_PITCH = 1; 
                
            % pitch change requested every category (and this is the first
            % pattern cycle in the segment, and a category just changed from A->B
            % or B->A)
            elseif cfg.pattern.changePitchCategory && pati==1 && ...
                    ( segmi==1 || segmi==cfg.pattern.nSegmentA+1 )
                CHANGE_PITCH = 1; 
                
            % pitch change requested only in every step 
            elseif cfg.pattern.changePitchStep && segmi==1
                CHANGE_PITCH = 1; 
                
            end
            
            
%             %% ORIGINAL 
%             % if change of pitch requested, PSEUDOrandomly choose a new pitch
%             % do this only if there is more than 1 F0 to choose from
%             if CHANGE_PITCH && length(cfg.pattern.F0s)>1
%                 % get F0s to choose from 
%                 pitch2ChooseIdx = 1:length(cfg.pattern.F0s);
%                 % remove F0 used in the previous iteration (to prevent
%                 % repetition in the sequence) 
%                 pitch2ChooseIdx(pitch2ChooseIdx==currF0idx) = [];
%                 % randomly select new F0 idx
%                 currF0idx = randsample(pitch2ChooseIdx,1);
%             end
            
            %% NEW
            % % %
            % long !
            % % %
            % last checkpoint is if fixed-pitch  is requested for
            % CategB
            if isfield(cfg.pattern,'fixedPitchCategB')
                
                % only categB is with fixed pitch
                if cfg.pattern.fixedPitchCategB && strcmpi(currSegmentLabel,'B')
                    %assign to the 5th pitch to all categB patterns
                    currF0 = cfg.pattern.differF0;
                    currAmp = cfg.pattern.F0sAmps(end);
                    currF0idx = cfg.pattern.nF0 + 1; % 5th pitch !!!!!!!!
                    
                elseif cfg.pattern.fixedPitchCategB && strcmpi(currSegmentLabel,'A')
                    
                    currF0idx = squeeze(cfg.pattern.seqDesignToneF0(seqi,stepi,segmi,pati,:)); 

                    currF0idxMask = currF0idx > 0; 
                    
                    % assign the index to current F0 index
                    currF0idx(currF0idx==0) = []; 
                    
                    %assign the randomly chosen ones to current pitch
                    currF0 = zeros(size(currF0idxMask)); 
                    currF0(currF0idxMask) = cfg.pattern.F0s(currF0idx);
                    
                    currAmp = zeros(size(currF0idxMask)); 
                    currAmp(currF0idxMask) = cfg.pattern.F0sAmps(currF0idx);
                    
                    currF0idx = squeeze(cfg.pattern.seqDesignToneF0(seqi,stepi,segmi,pati,:)); 

                end
            end 

            
            if ~isfield(cfg.pattern,'fixedPitchCategB') || ~ cfg.pattern.fixedPitchCategB
                % if fixedPitchCategB is not defined
                if CHANGE_PITCH && length(cfg.pattern.F0s)>1
                    
                    % counterbalance the pitches across patterns
                    if mod(pati, numPitch) == 1
                        
                        %reset the counter
                        cPitch = 1;
                        
                        % shuffle the F0 array & get one F0
                        arrayPitchIdx = Shuffle(1:numPitch);
                        pitch2ChooseIdx = arrayPitchIdx(cPitch);
                        
                        % prevent repetition of pitch in sequential
                        % patterns
                        while pitch2ChooseIdx == currF0idx
                            
                            % shuffle the F0 array & get one F0
                            arrayPitchIdx = Shuffle(1:numPitch);
                            pitch2ChooseIdx = arrayPitchIdx(cPitch);
                            
                        end
                        
                    else
                        % increase pitch counter
                        cPitch = cPitch+1;
                        % get the following F0
                        pitch2ChooseIdx = arrayPitchIdx(cPitch);
                    end

                    
                    % assign the index to current F0 index
                    currF0idx = pitch2ChooseIdx; 
                    
                    %assign the randomly chosen ones to current pitch
                    currF0 = cfg.pattern.F0s(currF0idx);
                    currAmp = cfg.pattern.F0sAmps(currF0idx);

                else
                    currF0 = cfg.pattern.F0s(currF0idx);
                    currAmp = cfg.pattern.F0sAmps(currF0idx);
                    
                end
            end
        
                    
            % --------------------------------------------------
            % ----------------- make the audio -----------------
            % --------------------------------------------------
            
            % get the pattern
            currPattern = patterns2choose(currPatIdx).pattern;

            
            % First, check for fmri task exists
            if isfield(cfg.pattern,'taskIdxMatrix')
                cfg.isTask.Idx = cfg.pattern.taskIdxMatrix(seqi,stepi,segmi,pati);
                % the current F0s index is used for finding the
                % taskSound
                cfg.isTask.F0Idx = currF0idx;

                
            else 
                cfg.isTask.Idx = 0;
            end
            
            % make audio 
%             [patternAudio,patternEnv] = makeStimMainExp(currPattern, ...
%                 cfg, currGridIOI, ...
%                 currF0,currAmp);
            
            [patternAudio,~] = makeStimMainExp(currPattern, ...
                cfg, currGridIOI, ...
                currF0,currAmp);
            
            % get current audio index in the sequence, and append the audio
            currAudioIdx = round(currTimePoint*cfg.fs); 
            
           
            % we only put the audio data in the first structure in the
            % array of structures to save memory...
            seq(1).outAudio(currAudioIdx +1:currAudioIdx +...
                length(patternAudio)) = patternAudio; 
            
%             seq(1).outEnv(currAudioIdx +1:currAudioIdx +...
%                 length(patternEnv)) = patternEnv;
            
            
            seq(cPat,1).patternID   = currPatID;
            seq(cPat,1).segmentCateg   = currCategLabel;
            seq(cPat,1).segmentLabel   = currSegmentLabel;
            seq(cPat,1).onset       = currTimePoint;
            seq(cPat,1).segmentNum  = segmi;
            seq(cPat,1).segmentOnset = segmentOnset;
            seq(cPat,1).stepNum     = stepi;
            seq(cPat,1).stepOnset   = stepOnset;
            seq(cPat,1).isTask      = cfg.isTask.Idx;
            
            seq(cPat,1).pattern     = currPattern; 
            seq(cPat,1).F0          = currF0(1);
            seq(cPat,1).gridIOI     = currGridIOI;
            seq(cPat,1).patternAmp  = currAmp(1);

            
            % get pattern info e.g. PE and LHL
            seq(cPat,1).PE4        = patterns2choose(currPatIdx).PE4;
            seq(cPat,1).minPE4     = patterns2choose(currPatIdx).minPE4;
            seq(cPat,1).rangePE4   = patterns2choose(currPatIdx).rangePE4;
            seq(cPat,1).LHL24      = patterns2choose(currPatIdx).LHL24;
            seq(cPat,1).minLHL24   = patterns2choose(currPatIdx).minLHL24;
            seq(cPat,1).rangeLHL24 = patterns2choose(currPatIdx).rangeLHL24;
            
            
            % --------------------------------------------------
            % update current time point
            currTimePoint = currTimePoint + cfg.pattern.interPatternInterval;         

            % increase pattern counter
            cPat = cPat+1; 
            
                       
            
        end % segment loop 
        
        
        % add delay after each category (if applicable)
        % by shifting the current time point with delay
        if strcmpi(currCategLabel,cfg.pattern.labelCategA)
            currTimePoint = currTimePoint + cfg.pattern.delayAfterA;         
        elseif strcmpi(currCategLabel,cfg.pattern.labelCategB)
            currTimePoint = currTimePoint + cfg.pattern.delayAfterB;         
        end
        

    end
    

end



