function out = makeOut(cfg,set_target,set_standard,varargin)
% documentation needed
% 
%
% 
% 


use_nonmeter_ratios = [0,0]; 
if any(strcmpi(varargin,'nonmeter'))
    use_nonmeter_ratios = varargin{find(strcmpi(varargin,'nonmeter'))+1}; 
end

cfg.rep_rate = cfg.n_target+cfg.n_standard; 
pat_type_out = [repmat(1,1,cfg.n_target),repmat(0,1,cfg.n_standard)]; 


fprintf('\n\nminimum IOI = %.3f s\nmaximum IOI = %.3f s\n',cfg.min_IOI,cfg.max_IOI); 



%%%%%%%%%%%%%%%%%% PARSE F0 CHANGE-TYPE %%%%%%%%%%%%%%%%%%

pitch_change_type = 0; 
% change pitch for each step (i.e. each [target-standard] cycle)
if isfield(cfg,'change_pitch_step')
    if cfg.change_pitch_step==1
        pitch_change_type = 1; 
    end
end
% change pitch for each pattern-type (i.e. in every step, the target will have one pitch and standard another)
if isfield(cfg,'change_pitch_type')
    if cfg.change_pitch_type==1
        pitch_change_type = 2; 
    end
end
% change pitch for each pattern
if isfield(cfg,'change_pitch_pattern')
    if cfg.change_pitch_pattern==1
        pitch_change_type = 3; 
    end
end



%%%%%%%%%%%%%%%%%% RUN %%%%%%%%%%%%%%%%%%

% allocate variables
out = struct(); 
curr_f0_idx = 1; 
out.pat_type_out = {}; 
out.pat_out = nan(cfg.n_steps,length(set_standard(1).pattern{1})); 
out.s_out = zeros(1, round((cfg.n_target+cfg.n_standard)*cfg.n_steps*cfg.base_T*cfg.fs)); 
out.patID_out = nan(1,cfg.n_steps); 
out.LHL22_out = nan(1,cfg.n_steps); 
out.ChiuFFT_out = nan(1,cfg.n_steps); 


c_pat = 1; 
c_time_sec = 0; 


% choose random f0 to initialize
available_f0_idx = [1:length(cfg.f0s)]; 
available_f0_idx(available_f0_idx==curr_f0_idx) = []; 
curr_f0_idx = randsample(available_f0_idx,1); 
cfg.f0 = cfg.f0s(curr_f0_idx); 



for stepi=1:cfg.n_steps
    
    % choose random f0
    if pitch_change_type==1
        available_f0_idx = [1:length(cfg.f0s)]; 
        available_f0_idx(available_f0_idx==curr_f0_idx) = []; 
        curr_f0_idx = randsample(available_f0_idx,1); 
        cfg.f0 = cfg.f0s(curr_f0_idx); 
    end
    
    
    
    
    for typei=1:length(pat_type_out)
        
        % choose random f0
        if pitch_change_type==3
            available_f0_idx = [1:length(cfg.f0s)]; 
            available_f0_idx(available_f0_idx==curr_f0_idx) = []; 
            curr_f0_idx = randsample(available_f0_idx,1); 
            cfg.f0 = cfg.f0s(curr_f0_idx); 
        end


    
        % choose IOI
        cfg.IOI = cfg.IOIs(randsample(length(cfg.IOIs),1)); 
        cfg.sound_dur = cfg.IOI; 


        if pat_type_out(typei)==0

            out.pat_type_out{end+1} = 'standard'; 

            % choose pattern
            patidx = randsample(length(set_standard),1); 

            % only allow phases where the pattern starts with sound event
            allowed_phases = find(cellfun(@(x) x(1)==1, set_standard(patidx).pattern)); 
            phaseidx = randsample(allowed_phases,1);

            % choose phase based on the specified method
            if strcmpi(cfg.phase_choose_method,'random')
                phaseidx = randsample(allowed_phases,1);      
            elseif strcmpi(cfg.phase_choose_method,'extreme_LHL')
                [~,sorted_idx] = sort(set_standard(patidx).LHL_22(allowed_phases),'descend'); 
                phaseidx = allowed_phases(sorted_idx(1)); 
            elseif strcmpi(cfg.phase_choose_method,'original')
                phaseidx = 1; 
            end

            % make sound
            if use_nonmeter_ratios(1)
                s2add = makeS(set_standard(patidx).ioi_ratios, cfg, 'nonmeter'); 
            else
                s2add = makeS(set_standard(patidx).pattern{phaseidx}, cfg); 
            end

            % log 
            out.patID_out(c_pat) = set_standard(patidx).ID; 
            out.pat_out(c_pat,:) = set_standard(patidx).pattern{phaseidx}; 
            if isfield(set_standard,'LHL_22')
                out.LHL22_out(c_pat) = set_standard(patidx).LHL_22(phaseidx); 
            end
            if isfield(set_standard,'chiuFFT_z36')
                out.ChiuFFT_out(c_pat) = set_standard(patidx).chiuFFT_z36;
            end
            
            
        elseif pat_type_out(typei)==1

            out.pat_type_out{end+1} = 'target'; 

            % choose pattern
            patidx = randsample(length(set_target),1); 

            % only allow phases where the pattern starts with sound event
            allowed_phases = find(cellfun(@(x) x(1)==1, set_target(patidx).pattern)); 
            phaseidx = randsample(allowed_phases,1);

            % choose phase based on the specified method
            if strcmpi(cfg.phase_choose_method,'random')
                phaseidx = randsample(allowed_phases,1);      
            elseif strcmpi(cfg.phase_choose_method,'extreme_LHL')
                [~,sorted_idx] = sort(set_target(patidx).LHL_22(allowed_phases),'descend'); 
                phaseidx = allowed_phases(sorted_idx(1)); 
            elseif strcmpi(cfg.phase_choose_method,'original')
                phaseidx = 1; 
            end

            % make sound
            if use_nonmeter_ratios(2)
                s2add = makeS(set_target(patidx).ioi_ratios, cfg, 'nonmeter'); 
            else
                s2add = makeS(set_target(patidx).pattern{phaseidx}, cfg); 
            end

            % log 
            out.patID_out(c_pat) = set_target(patidx).ID; 
            out.pat_out(c_pat,:) = set_target(patidx).pattern{phaseidx}; 
            if isfield(set_target,'LHL_22')
                out.LHL22_out(c_pat) = set_target(patidx).LHL_22(phaseidx); 
            end
            if isfield(set_target,'chiuFFT_z36')
                out.ChiuFFT_out(c_pat) = set_target(patidx).chiuFFT_z36;
            end
        end


        % check if not longer than base_T
        if length(s2add)/cfg.fs > cfg.base_T
            warning(sprintf('trying to add %.3f sec step, but only %.3f s allowed',length(s2add)/cfg.fs, cfg.base_T))
        else
            fprintf('adding %.3f sec step\n',length(s2add)/cfg.fs); 
        end

        % find starting index
        t_idx = round(c_time_sec*cfg.fs); 

        % add the sound
        out.s_out(t_idx+1:t_idx+length(s2add)) = s2add; 
        
        
        % ========== update f0 ==========
               
        if pitch_change_type==2
            if ((pat_type_out(typei)==1 & pat_type_out(typei+1)==0) | typei==length(pat_type_out))            
                available_f0_idx = [1:length(cfg.f0s)]; 
                available_f0_idx(available_f0_idx==curr_f0_idx) = []; 
                curr_f0_idx = randsample(available_f0_idx,1); 
                cfg.f0 = cfg.f0s(curr_f0_idx); 
            end
        end
    
        
        
        % ========== update current time position ==========
        
        c_time_sec = c_time_sec + cfg.base_T;         

        % if this is last target, and delay requested, add it to the time position 
        if isfield(cfg,'delay_after_tar') & pat_type_out(typei)==1 & pat_type_out(typei+1)==0
            c_time_sec = c_time_sec + cfg.delay_after_tar;         
        end        
        % if this is last standard, and delay requested, add it to the time position 
        if isfield(cfg,'delay_after_std') & typei==length(pat_type_out)
            c_time_sec = c_time_sec + cfg.delay_after_std;         
        end
        
        c_pat = c_pat+1; 

    end
    
end


out.set_standard = set_standard; 
out.set_target = set_target; 
out.use_nonmeter_ratios = use_nonmeter_ratios; 
