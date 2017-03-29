%%
Z_Constants;
addpath ./scripts;

%%

DO_BASICS = 0;
DO_XTRODE_HG = 1;
% DO_XTRODE_XFREQ = 1;

for sIdx = 1:length(SIDS)
    sid = SIDS{sIdx};
    fprintf('working on %s\n', sid);
    
    fprintf('  loading data: '); tic;
    load(fullfile(META_DIR, sprintf('%s_extracted.mat', sid)));
    toc;
        
    % perform covariance analses
    winWidthSec = .500;
    winWidth = ceil(winWidthSec * fs);
    maxLagSec = .30;
    maxLag = ceil(maxLagSec * fs);
    lags = -maxLag:maxLag;

    windowFunction = single(ones(winWidth+1, 1));
    
%     [onsetSamples, modulationDepths] = findHGOnsets(c_hg, t, fs);

%     %% simple effect plots
%     if (DO_BASICS)
%         [aligned_c_hg, t_relOnset] = alignActivationsByOnset(c_hg, onsetSamples, t);
%         figure, subplot(121);
%         imagesc(t_relOnset, 1:size(aligned_c_hg, 2), aligned_c_hg');
%         hold on;
%         for c = 1:size(aligned_c_hg, 2)
%             plot(-t(onsetSamples(c)), c, 'k.');
%         end
%         vline(0,'k');        
%         xlabel('time rel. HG onset at CTL'); ylabel('trials');
%         title([sid ' HG ' trodeNameFromMontage(cchan, montage)]);
%         
%         aligned_c_beta = alignActivationsByOnset(c_beta, onsetSamples, t);
%         subplot(122);
%         imagesc(t_relOnset, 1:size(aligned_c_beta, 2), aligned_c_beta');
%         hold on;
%         for c = 1:size(aligned_c_hg, 2)
%             plot(-t(onsetSamples(c)), c, 'k.');
%         end
%         vline(0,'k');       
%         xlabel('time rel. HG onset at CTL'); ylabel('trials');
%         title([sid 'Beta ' trodeNameFromMontage(cchan, montage)]);
%         set(gcf, 'pos', [680   558   931   420]);
%         SaveFig(fullfile(pwd, 'figures', 'activity'), [sid '_ctl'], 'png');
%         
%         figure
%         for chanIdx = 1:size(p_hg, 1)
%             p_hg_temp = squeeze(p_hg(chanIdx, :, all));
%             
%             aligned_p_hg = alignActivationsByOnset(p_hg_temp, onsetSamples, t);
%             subplot(1, size(p_hg, 1), chanIdx);
%             imagesc(t_relOnset, 1:size(aligned_p_hg, 2), aligned_p_hg');
%             hold on;
%             for c = 1:size(aligned_p_hg, 2)
%                 plot(-t(onsetSamples(c)), c, 'k.');
%             end            
%             vline(0,'k');
%             xlabel('time rel. HG onset at CTL'); ylabel('trials');
%             title([sid 'HG ' trodeNameFromMontage(trs(chanIdx), montage)]);            
%         end
%         set(gcf, 'pos', [680   558   931   420]);        
%         SaveFig(fullfile(pwd, 'figures', 'activity'), [sid '_pmv'], 'png');
%     end
    
    if (DO_XTRODE_HG)
        %% cross-electrode hg interactions
        hgInteraction = zeros(size(p_hg, 1), sum(all), 2*maxLag + 1, size(c_hg, 1));

        allTs = [];
        allLags = [];
        alignedAverages = [];
        alignedEarly = [];
        alignedLate = [];
        method = 'corr';
            
        for chanIdx = 1:size(p_hg, 1)
            fprintf('  calculating cross electrode interactions (%d of %d): ', chanIdx, size(p_hg, 1)); tic    
            p_hg_temp = squeeze(p_hg(chanIdx, :, all));

            for epochIdx = 1:size(c_hg, 2)
                hgInteraction(chanIdx, epochIdx, :, :) = gausswc(c_hg(:, epochIdx), p_hg_temp(:, epochIdx), winWidth, maxLag, windowFunction, method);            
%                 hgInteraction(chanIdx, epochIdx, :, :) = stwc(c_hg(:, epochIdx), p_hg_temp(:, epochIdx), winWidth, maxLag);            
            end

            tempInteractions = squeeze(hgInteraction(chanIdx, :, :, :));
            [alignedInteractions, t_relOnset] = alignInteractionsByOnset(tempInteractions, onsetSamples, t);

%             for c = 1:2
%                 switch (c)
%                     case 1
%                         idx = earlies;
%                         str = 'early up hit';
%                     case 2
%                         idx = lates;
%                         str = 'late up hit';
%                 end
% 
%                 subplot(2,1,c);
%                 interactionPlot(t_relOnset, lags/fs, alignedInteractions(idx, : ,:));
%                
%                 vline([0 -mean(t(onsetSamples))],'k:');
%                 hline(0, 'k--');
%                 ylabel('lag (sec) [neg implies ctl leads]');
%                 xlabel('time(sec)');
%                 title(sprintf('Cross-electrode interaction (%d<->%d) (%s): %s', cchan, trs(chanIdx), str, sid));
%             end
% 
%             set(gcf, 'pos', [  560   109   689   839]);

            interactionPlot(t_relOnset, lags/fs, alignedInteractions(:, : ,:));
            axis xy;
            
            vline([0 -mean(t(onsetSamples))],'k:');
            hline(0, 'k--');
            ylabel('lag (sec) [neg implies ctl leads]');
            xlabel('time(sec)');
            title(sprintf('Cross-electrode interaction (%d<->%d): %s', cchan, trs(chanIdx), sid));

            SaveFig(fullfile(pwd, 'figures'), sprintf('%s-%d-xtrode', sid, chanIdx), 'png');

            toc
            
            allTs(chanIdx, :) = t_relOnset;
            allLags(chanIdx, :) = lags / fs;
            alignedAverages(chanIdx, :, :) = squeeze(mean(alignedInteractions, 1));
            alignedEarly(chanIdx, :, :) = squeeze(mean(alignedInteractions(earlies, :, :), 1));
            alignedLate(chanIdx, :, :) = squeeze(mean(alignedInteractions(lates, : ,:), 1));
        end
        
        save(fullfile('meta', [sid, '_interactions.mat']), 'allLags', 'allTs', 'alignedAverages', 'alignedEarly', 'alignedLate', 'method');
        
    end
    
    if (DO_XTRODE_XFREQ)
        %% cross-electrode hg interactions
        betaInteraction = zeros(size(p_hg, 1), sum(all), 2*maxLag + 1, size(c_beta, 1));

        allBetaTs = [];
        allBetaLags = [];
        alignedBetaAverages = [];
        alignedBetaEarly = [];
        alignedBetaLate = [];
        method = 'corr';
        
        for chanIdx = 1:size(p_hg, 1)
            fprintf('  calculating cross electrode, cross frequency interactions (%d of %d): ', chanIdx, size(p_hg, 1)); tic    
            p_hg_temp = squeeze(p_hg(chanIdx, :, all));

            for epochIdx = 1:size(c_beta, 2)
                betaInteraction(chanIdx, epochIdx, :, :) = gausswc(c_beta(:, epochIdx), p_hg_temp(:, epochIdx), winWidth, maxLag, windowFunction, 'corr');            
%                 betaInteraction(chanIdx, epochIdx, :, :) = stwc(c_beta(:, epochIdx), p_hg_temp(:, epochIdx), winWidth, maxLag);            
            end

            tempInteractions = squeeze(betaInteraction(chanIdx, :, :, :));
            [alignedInteractions, t_relOnset] = alignInteractionsByOnset(tempInteractions, onsetSamples, t);

%             for c = 1:2
%                 switch (c)
%                     case 1
%                         idx = earlies;
%                         str = 'early up hit';
%                     case 2
%                         idx = lates;
%                         str = 'late up hit';
%                 end
% 
%                 subplot(2,1,c);
%                 interactionPlot(t_relOnset, lags/fs, alignedInteractions(idx, : ,:), ...
%                     [], ... % smoothing window width
%                     [] ... % gaussian std dev
%                     );
%                 vline([0 -mean(t(onsetSamples))],'k:');
%                 hline(0, 'k--');
%                 ylabel('lag (sec) [neg implies ctl leads]');
%                 xlabel('time(sec)');
%                 title(sprintf('Cross-electrode cross-frequency interaction (%d<->%d) (%s): %s', cchan, trs(chanIdx), str, sid));
%             end
% 
%             set(gcf, 'pos', [  560   109   689   839]);
% 
%             SaveFig(fullfile(pwd, 'figures_beta'), sprintf('%s-%d-xtrodexfreq', sid, chanIdx), 'png');
% 
%             toc

            interactionPlot(t_relOnset, lags/fs, alignedInteractions(:, : ,:));
            axis xy;
            
            vline([0 -mean(t(onsetSamples))],'k:');
            hline(0, 'k--');
            ylabel('lag (sec) [neg implies ctl leads]');
            xlabel('time(sec)');
            title(sprintf('Cross-electrode cross-frequency interaction (%d<->%d): %s', cchan, trs(chanIdx), sid));

            SaveFig(fullfile(pwd, 'figures'), sprintf('%s-%d-xfreq', sid, chanIdx), 'png');

            toc
            
            allBetaTs(chanIdx, :) = t_relOnset;
            allBetaLags(chanIdx, :) = lags / fs;
            alignedBetaAverages(chanIdx, :, :) = squeeze(mean(alignedInteractions, 1));
            alignedBetaEarly(chanIdx, :, :) = squeeze(mean(alignedInteractions(earlies, :, :), 1));
            alignedBetaLate(chanIdx, :, :) = squeeze(mean(alignedInteractions(lates, : ,:), 1));
        end
        
        save(fullfile('meta', [sid, '_beta_interactions.mat']), 'allBetaLags', 'allBetaTs', 'alignedBetaAverages', 'alignedBetaEarly', 'alignedBetaLate', 'method');
        
    end
    
    close all;
    
%     clearvars -except SIDS sIdx trodesOfInterest
end