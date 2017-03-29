%%
Z_Constants;
addpath ./scripts;

%% lets build a table of electrode information
result = [];
earlyresult = [];
lateresult = [];

resultA = [];
earlyresultA = [];
lateresultA = [];

SHOW_INT_PLOTS = false;

ctr = 0;

for ctr = 1:length(SIDS)
    sid = SIDS{ctr};
    
    fprintf('working on subject %s\n', sid);
    
    %% set up to work on this subject    
    
    load(fullfile(META_DIR, [sid '_results']), 'bas', 'class', 'hmats', 'tlocs');
    load(fullfile(META_DIR, [sid '_extracted']), 'trodes', 't', 'alignedT', 'fs');
    
    tConsidered = t >= 0 & t < 1;
    tAConsidered = alignedT >= -0.502 & alignedT <= 0.5;
    
    controlLocs(ctr, :) = tlocs(trodes(1), :);
    
    %% first, go out and get all the simulation results
    allmaxes = [];
    allmins = [];
    earlymaxes = [];
    earlymins = [];
    latemaxes = [];
    latemins = [];
    
    arrs = [];
    earlyarrs = [];
    earlyarrs2 = [];
    latearrs = [];
    
    for chani = 2:length(trodes)
        chan = trodes(chani);
        
        load(fullfile(META_DIR, sid, [sid '_simulations_' num2str(chan) '.mat']), '*mins*', '*maxes*');
        if (size(maxes, 2) ~= 100 || size(mins, 2) ~= 100)
            warning(sprintf('incorrect number of simulation runs for %s', sid));
        else            
            allmaxes = cat(2, allmaxes, maxes);        
            allmins  = cat(2, allmins, mins);
            
            earlymaxes = cat(2, earlymaxes, maxesEarly);
            earlymins  = cat(2, earlymins,  minsEarly);
            
            latemaxes = cat(2, latemaxes, maxesLate);
            latemins  = cat(2, latemins,  minsLate);
            
%             arrs(:,:,end+1) = max(maxes, abs(mins));
            arrs(:,:,end+1) = maxes;
            earlyarrs(:,:,end+1) = maxesEarly;
            latearrs(:,:,end+1) = maxesLate;
        end
    end       
    
%     % sort out what the thresholds are for this specific subject
    
    lims = max(arrs, [], 3);
    earlylims = max(earlyarrs, [], 3);
    latelims = max(latearrs, [], 3);
    
    for interactionType = 1:size(lims, 1)
        lims(interactionType, :) = sort(lims(interactionType, :), 'descend');
        earlylims(interactionType, :) = sort(earlylims(interactionType, :), 'descend');
        latelims(interactionType, :) = sort(latelims(interactionType, :), 'descend');
    end
    
    % get uncorrected distributions
    arrs = sort(arrs,2,'descend');
    earlyarrs = sort(earlyarrs, 2, 'descend');
    latearrs = sort(latearrs, 2, 'descend');
    
%     uncorr = prctile(abs([allmins allmaxes]), 95, 2);
%     bonf = prctile(lims, 95, 2);
    
    
    %% now, evaluate all interactions
    for chani = 2:length(trodes)
        chan = trodes(chani);
        
        % ok, a little confusing, but for each channel, we want to ask
        % whether any of the interactions, aligned or not, were
        % significant.  The bootstrapping approach as it's currently
        % written only looks at 1 sec worth of data, so we have to do the
        % same to be fair, when examining real interactions.  In the case
        % of the unaligned interactions, we're going to look at t>=0 & t<1.
        % For the aligned interactions, on the other hand, we're going to
        % look at t_a >= -0.5 & t_b < 0.5.
        
        % now load the interaction data
        load(fullfile(META_DIR, sid, [sid '_interactions_' num2str(chan) '.mat']), 'lags', 'mAlInt*', 'mInt*');
        lags = lags / fs;
                
        % the way we report this is by building six tables of
        % interactions, three for the unaligned and three for the aligned
        % trials.  Here is the makeup of each table
        
        % row 1 is sid
        % row 2 is channel number
        % row 3-5 are tal coords
        % row 6 is electrode class (-1,0,1,2)
        % row 7 is electrode HMAT
        % row 8 is electrode BA
        % row 9 is interaction type (1,2,3,4, or 5)
        % row 10 is corrected p-value
        % row 11 is interaction coeff
        % row 12 is interaction time
        % row 13 is interaction lag

        % done separately for unaligned and aligned trials            
        for d = 1:size(mInt, 1)
            [weight, tcenter, lcenter] = findBestLag(squeeze(mInt(d,:,tConsidered)), t(tConsidered), lags, lims(d,5), SHOW_INT_PLOTS);            
            
            result(end+1, :) = [...
                ctr ...
                chan ...
                tlocs(chan,1) ...
                tlocs(chan,2) ...
                tlocs(chan,3) ...
                class(chan) ...
                hmats(chan) ...
                bas(chan) ...
                d ...
                pValueForWeight(weight, lims(d, :)) ...
                weight ...
                tcenter ...
                lcenter ...
                ];                        
            
            [weight, tcenter, lcenter] = findBestLag(squeeze(mIntEarly(d,:,tConsidered)), t(tConsidered), lags, arrs(d, 5, chani), SHOW_INT_PLOTS);
            
            earlyresult(end+1, :) = [...
                ctr ...
                chan ...
                tlocs(chan,1) ...
                tlocs(chan,2) ...
                tlocs(chan,3) ...
                class(chan) ...
                hmats(chan) ...
                bas(chan) ...
                d ...
                pValueForWeight(weight, earlyarrs(d, :, chani)) ...
                weight ...
                tcenter ...
                lcenter ...
                ];                        
            
            [weight, tcenter, lcenter] = findBestLag(squeeze(mIntLate(d,:,tConsidered)), t(tConsidered), lags, latearrs(d, 5, chani), SHOW_INT_PLOTS);
            
            lateresult(end+1, :) = [...
                ctr ...
                chan ...
                tlocs(chan,1) ...
                tlocs(chan,2) ...
                tlocs(chan,3) ...
                class(chan) ...
                hmats(chan) ...
                bas(chan) ...
                d ...
                pValueForWeight(weight, latearrs(d, :, chani)) ...
                weight ...
                tcenter ...
                lcenter ...
                ];                                    
            
            if (d==1 && (result(end, 10) <= 0.05))
                lagPlot(squeeze(mInt(d, :, tConsidered)), (squeeze(mInt(d, :, tConsidered)) >= lims(d, 5)), ...
                        squeeze(mIntEarly(d, :, tConsidered)), (squeeze(mIntEarly(d, :, tConsidered)) >= earlyarrs(d, 5, chani)), ...
                        squeeze(mIntLate(d, :, tConsidered)), (squeeze(mIntLate(d, :, tConsidered)) >= latearrs(d, 5, chani)), ...
                        t(tConsidered), lags);
                mtit(['unaligned - ' sid ' ' num2str(chan) '/' num2str(class(chan))], 'xoff', 0, 'yoff', .035);
                set(gcf, 'pos', [624         474        1250         504]);
                
                SaveFig(OUTPUT_DIR, sprintf('ints_%s_%d', sid, chan), 'png', '-r600');
                close
            end
        end
            
        for d = 1:size(mAlInt, 1)
            [weight, tcenter, lcenter] = findBestLag(squeeze(mAlInt(d,:,tAConsidered)), alignedT(tAConsidered), lags, lims(d, 5), SHOW_INT_PLOTS);
            
            resultA(end+1, :) = [...
                ctr ...
                chan ...
                tlocs(chan,1) ...
                tlocs(chan,2) ...
                tlocs(chan,3) ...
                class(chan) ...
                hmats(chan) ...
                bas(chan) ...
                d ...
                pValueForWeight(weight, lims(d, :)) ...
                weight ...
                tcenter ...
                lcenter ...
                ];                        
            
            [weight, tcenter, lcenter] = findBestLag(squeeze(mAlIntEarly(d,:,tAConsidered)), alignedT(tAConsidered), lags, earlyarrs(d, 5, chani), SHOW_INT_PLOTS);
            
            earlyresultA(end+1, :) = [...
                ctr ...
                chan ...
                tlocs(chan,1) ...
                tlocs(chan,2) ...
                tlocs(chan,3) ...
                class(chan) ...
                hmats(chan) ...
                bas(chan) ...
                d ...
                pValueForWeight(weight, earlyarrs(d, :, chani)) ...
                weight ...
                tcenter ...
                lcenter ...
                ];                        
            
            [weight, tcenter, lcenter] = findBestLag(squeeze(mAlIntLate(d,:,tAConsidered)), alignedT(tAConsidered), lags, latearrs(d, 5, chani), SHOW_INT_PLOTS);
            
            lateresultA(end+1, :) = [...
                ctr ...
                chan ...
                tlocs(chan,1) ...
                tlocs(chan,2) ...
                tlocs(chan,3) ...
                class(chan) ...
                hmats(chan) ...
                bas(chan) ...
                d ...
                pValueForWeight(weight, latearrs(d, :, chani)) ...
                weight ...
                tcenter ...
                lcenter ...
                ];                                    
            
            if (d==1 && (resultA(end, 10) <= 0.05))
                lagPlot(squeeze(mAlInt(d, :, tAConsidered)), (squeeze(mAlInt(d, :, tAConsidered)) >= lims(d, 5)), ...
                        squeeze(mAlIntEarly(d, :, tAConsidered)), (squeeze(mAlIntEarly(d, :, tAConsidered)) >= earlyarrs(d, 5, chani)), ...
                        squeeze(mAlIntLate(d, :, tAConsidered)), (squeeze(mAlIntLate(d, :, tAConsidered)) >= latearrs(d, 5, chani)), ...
                        alignedT(tAConsidered), lags);
                mtit(['aligned - ' sid ' ' num2str(chan) '/' num2str(class(chan))], 'xoff', 0, 'yoff', .035);
                set(gcf, 'pos', [624         474        1250         504]);
                
                SaveFig(OUTPUT_DIR, sprintf('aints_%s_%d', sid, chan), 'png', '-r600');
                close
            end            
        end
    end      
end

save(fullfile(META_DIR, 'screened_interactions.mat'), '*result*', 'controlLocs');

