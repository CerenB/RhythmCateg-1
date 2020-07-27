function [cfg, expParameters] = checkCFG(cfg, expParameters)
    % check that we have all the fields that we need in the experiment parameters

    checkCppBidsDependencies();

    if nargin < 1 || isempty(cfg)
        cfg = struct();
    end
    if nargin < 2 || isempty(expParameters)
        expParameters = struct();
    end

    %% set the expParameters defaults

    fieldsToSet.verbose = false;
    fieldsToSet.outputDir = fullfile( ...
        fileparts(mfilename('fullpath')), ...
        '..', ...
        'output');

    fieldsToSet = mriDefaults(fieldsToSet);

    fieldsToSet.subjectGrp = ''; % in case no group was provided
    fieldsToSet.sessionNb = 1; % in case no session was provided
    fieldsToSet.askGrpSess = [true true];

    expParameters = setDefaultFields(expParameters, fieldsToSet);

    %% BIDS
    clear fieldsToSet;
    fieldsToSet.bids = struct();
    expParameters = setDefaultFields(expParameters, fieldsToSet);

    clear fieldsToSet;
    fieldsToSet.MRI = struct();
    fieldsToSet.datasetDescription = struct();
    expParameters.bids = setDefaultFields(expParameters.bids, fieldsToSet);

    clear fieldsToSet;
    fieldsToSet = datasetDescriptionDefaults();

    expParameters.bids.datasetDescription = ...
        setDefaultFields(expParameters.bids.datasetDescription, fieldsToSet);

    clear fieldsToSet;
    fieldsToSet = mriJsonDefaults();
    if isfield(expParameters, 'task')
        fieldsToSet.TaskName = expParameters.task;
    end

    expParameters.bids.MRI = ...
        setDefaultFields(expParameters.bids.MRI, fieldsToSet);

    % sort fields alphabetically
    expParameters = orderfields(expParameters);

    %% set the cfg defaults

    clear fieldsToSet;
    fieldsToSet.verbose = false;
    fieldsToSet.testingDevice = 'pc';
    fieldsToSet.eyeTracker = false;

    cfg = setDefaultFields(cfg, fieldsToSet);

    % sort fields alphabetically
    cfg = orderfields(cfg);

end

function fieldsToSet = mriDefaults(fieldsToSet)

    % for file naming
    fieldsToSet.MRI.ce = [];
    fieldsToSet.MRI.dir = []; % phase encoding direction of acquisition for fMRI
    fieldsToSet.MRI.rec = []; % reconstruction of fMRI images
    fieldsToSet.MRI.echo = []; % echo fMRI images
    fieldsToSet.MRI.acq = []; % acquisition of fMRI images

end

function fieldsToSet = datasetDescriptionDefaults()
    % required
    fieldsToSet.Name = '';
    fieldsToSet.BIDSVersion = '';
    % recommended
    fieldsToSet.License = '';
    fieldsToSet.Authors = {''};
    fieldsToSet.Acknowledgements = '';
    fieldsToSet.HowToAcknowledge = '';
    fieldsToSet.Funding = {''};
    fieldsToSet.ReferencesAndLinks = {''};
    fieldsToSet.DatasetDOI = '';
end

function fieldsToSet = mriJsonDefaults()

    % for json for funcfional data
    % required
    fieldsToSet.RepetitionTime = [];
    fieldsToSet.SliceTiming = [];
    fieldsToSet.TaskName = [];
    %     fieldsToSet.PhaseEncodingDirection = [];
    %     fieldsToSet.EffectiveEchoSpacing = [];
    %     fieldsToSet.EchoTime = [];
    % recommended
    fieldsToSet.Instructions = [];
    fieldsToSet.TaskDescription = [];

end
