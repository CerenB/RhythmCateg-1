function cfg = makefMRISeqDesign(cfg)

% this function creates counterbalanced audio sequences for fMRI in
% by using subfunction as:
% makeSequecen.m
% getAllSeqDesign.m
% makeStimMainExp.m

% In the future it can be embedded into getParams.m script but since it's
% depending on the expParam.runNb parameter, it should be causiously
% embedded. (e.g. after the script gets runNb)
% if debug, put back run =1 so in the main script sequence =runNb ==1
if cfg.debug.do 
    cfg.subject.runNb = 1;
end

% path to save output
savepath = fullfile(fileparts(mfilename('fullpath')),'../');

%% Get counterbalanced sequences according to the total fMRI RUNs
% to do! 
% ADD SHUFFLE ORDER FOR STARTING WITH A OR B CATEG for BLOCK DESING !

% to do! 
% CREATE counterbalanced sequences for every 3 sequence then multiply with
% 3 (in case they stop fMRI, or we want ot increase to 12 runs)
% expParam.numSequences = 3


%%%%%%%%%%%%
% ! important, the order of arguments matters ! -> getAllSeq(categA, categB, ...)
% getAllSeqDesign(cfg.patternSimple, cfg.patternComplex, cfg, expParam);
%%%%%%%%%%%%

if strcmp(cfg.testingDevice,'mri')
    if cfg.subject.runNb == 1
        
        % get the design
        DesignFullExp = getAllSeqDesign(cfg.pattern.patternSimple, cfg.pattern.patternComplex, cfg);
        % DesginFullExp (runNum, stepNum,segmentNum,patternNum)
        
        if cfg.fmriTask
            %create an empty cell to store the task==1s and 0s
            cfg.fMRItaskidx =  zeros(...
                cfg.pattern.numSequences, ...
                cfg.pattern.nStepsPerSequence,...
                cfg.pattern.nSegmPerStep, ...
                cfg.pattern.nPatternPerSegment);
            
            % find the categA and categB
            idxCategA = contains(DesignFullExp(:),cfg.pattern.labelCategA);
            idxCategB = contains(DesignFullExp(:),cfg.pattern.labelCategB);
            
            %count the number of categA and categB
            categANum = sum(idxCategA);
            categBNum = sum(idxCategB);
            
            % take the 10%
            cfg.pattern.categANumTask = round(categANum*0.1);
            cfg.pattern.categBNumTask = round(categBNum*0.1);
            
            %create zero array
            categA = zeros(categANum,1);
            categB = zeros(categBNum,1);
            
            %assign 1s to indicate the targets
            categA(1:cfg.pattern.categANumTask) = 1;
            categB(1:cfg.pattern.categBNumTask) = 1;
            
            %and shuffle the order or target across seq (runs), steps, segments, ...
            idxCategATarget = Shuffle(categA);
            idxCategBTarget = Shuffle(categB);
            
%             %insert control
%             % dont put target into first pattern of sequence
%             DesignFullExp(:)
%             idx = find(DesignFullExp(:,1,1,1))
            
            %save it to expParams for using the order in makeSequence.m
            cfg.fMRItaskidx(idxCategA)= idxCategATarget;
            cfg.fMRItaskidx(idxCategB)= idxCategBTarget;
            
        end
        
        %save the Design
        save([savepath,'SeqDesign'],'DesignFullExp','cfg');
        cfg.pattern.seqDesignFullExp = DesignFullExp;
        
    else
        
        design = load([savepath,'SeqDesign']);
        cfg.pattern.seqDesignFullExp = design.DesignFullExp;
        cfg.fMRItaskidx = design.cfg.fMRItaskidx;
        
    end
    

end


end