%% This script collects all of the BCI epochs to be processed in to a convenient data structure
% it downsamples native sampling rates (2.4kHz, 1.2kHz, 1kHz) to lower sampling
% rates (600 Hz, 500 Hz) to keep future computation tractable.

% TODO
%   currently, we CAR the signals first thing.  The problem with this is if
%   there are any noise epochs, or noisy channels that were not listed in
%   screen bad channels, etc, they will inject noise in to the other
%   channels.

%% select a subject to run.  If running from the batch file make sure to comment these out

subjid = 'fc9643';
% subjid = '4568f4';
% subjid = '30052b';
% subjid = '9ad250';

[ftemp, odir, hemi, bads] = filesForSubjid(subjid);
TouchDir(odir);

%% process each bci file in ftemp, file by file, concatenating new epochs, targets, and results

tgts = [];
ress = [];
epochs = [];

for mfile = ftemp

    fprintf('working file %s\n', mfile{:});

    
%     load a file
    [sig, sta, par] = load_bcidat(mfile{:});
    load(strrep(mfile{:}, '.dat', '_montage.mat'));
    
    fs = par.SamplingRate.NumericValue;

    % common average re-ref
    sig = ReferenceCAR(Montage.Montage, union(Montage.BadChannels, bads), double(sig));

    % downsample to 600 hz / 500 Hz to keep us sane
    if (fs == 2400)
        sig2 = [];
        
        for c = 1:size(sig,2)
            sig2(:,c) = decimate(sig(:,c), 4);
        end
        
        sig = sig2; clear sig2;
        
        sta.TargetCode = sta.TargetCode(1:4:end);
        sta.ResultCode = sta.ResultCode(1:4:end);
        sta.Feedback   = sta.Feedback(1:4:end);
        fs = 600;
    elseif (fs == 1200)
        sig2 = [];
        
        for c = 1:size(sig,2)
            sig2(:,c) = decimate(sig(:,c), 2);
        end
        
        sig = sig2; clear sig2;
        
        sta.TargetCode = sta.TargetCode(1:2:end);
        sta.ResultCode = sta.ResultCode(1:2:end);
        sta.Feedback   = sta.Feedback(1:2:end);
        fs = 600;
    elseif (fs == 1000)
        sig2 = [];
        
        for c = 1:size(sig,2)
            sig2(:,c) = decimate(sig(:,c), 2);
        end
        
        sig = sig2; clear sig2;
        
        sta.TargetCode = sta.TargetCode(1:2:end);
        sta.ResultCode = sta.ResultCode(1:2:end);
        sta.Feedback   = sta.Feedback(1:2:end);
        fs = 500;        
    else
        error('unknown fs');
    end

    % notch filter
    sig = NotchFilter(sig, [120 180], fs);
    
    % collect epochs
    rends = find(diff(double(sta.TargetCode)) > 0);
    rstarts = rends-par.ITIDuration.NumericValue * fs;
    
    fstarts = rends+par.PreFeedbackDuration.NumericValue * fs;
    fends = rends+(par.PreFeedbackDuration.NumericValue+par.FeedbackDuration.NumericValue) * fs;
    
    pends = fends + (par.PostFeedbackDuration.NumericValue) * fs;
    
    bi = rstarts < 0 | pends > length(sta.TargetCode);

    t  = -par.ITIDuration.NumericValue-par.PreFeedbackDuration.NumericValue:1/fs:par.FeedbackDuration.NumericValue+par.PostFeedbackDuration.NumericValue;
    
    rends(bi) = [];
    rstarts(bi) = [];
    fends(bi) = [];
    fstarts(bi) = [];
    pends(bi) = [];
    
    if (~isempty(rstarts))
        mepochs = zeros(size(sig,2), length(rstarts), mode(pends-rstarts+1));

        for e_ctr = 1:length(rstarts)
            e = rstarts(e_ctr):pends(e_ctr);        
            mepochs(:, e_ctr, :) = sig(e,:)'; 
        end

        tgts = cat(1, tgts, sta.TargetCode(fstarts));
        ress = cat(1, ress, sta.ResultCode(fends));
        epochs = cat(2, epochs, mepochs);    
    end
end

clear bi c e e_ctr fends files* fstarts ftemp mepochs mfile par pends rends rstarts sig sta

ofile = fullfile(odir, [subjid '_epochs']);
fprintf('saving output to %s\n', ofile);
save(ofile);

