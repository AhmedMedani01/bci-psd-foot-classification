function [epochs, labels] = extract_foot_and_rest(sig, hdr, EEG_CH, foot_epoch_sec)
% EXTRACT_FOOT_AND_REST  Build epochs for Foot (class=1) and Rest (class=0).
% Foot: event 771; Rest: events 276/277. Skip epochs containing artifact event 1023.
% Rest segments are sliced into 4 s chunks to balance with Foot epochs.

    EV_IDLE_OPEN  = 276;  % eyes-open  :contentReference[oaicite:8]{index=8}
    EV_IDLE_CLOSE = 277;  % eyes-closed :contentReference[oaicite:9]{index=9}
    EV_CUE_FOOT   = 771;  % foot class  :contentReference[oaicite:10]{index=10}
    EV_ARTIFACT   = 1023; % artifact    :contentReference[oaicite:11]{index=11}

    fs = hdr.SampleRate;
    nSamp = size(sig,1);
    typ = hdr.EVENT.TYP(:);
    pos = hdr.EVENT.POS(:);
    dur = hdr.EVENT.DUR(:);

    segLen = round(foot_epoch_sec * fs);

    E = {}; L = [];   % cell of [T x 22], labels (1=foot,0=rest)

    % --- Foot epochs: take 4 s after cue onset (cue marks start of imagery window)
    idxFoot = find(typ == EV_CUE_FOOT);
    for k = 1:numel(idxFoot)
        i = idxFoot(k);
        st = pos(i);
        en = st + segLen - 1;
        if en > nSamp, continue; end

        % Skip if any artifact event lies inside the window
        if any(typ == EV_ARTIFACT & pos >= st & pos <= en)
            continue;
        end

        ep = sig(st:en, EEG_CH);
        if any(isnan(ep(:))), continue; end
        E{end+1} = ep; %#ok<AGROW>
        L(end+1,1) = 1; %#ok<AGROW>
    end

    % --- Rest segments: take full duration, then slice into 4 s windows
    idxRest = find(typ == EV_IDLE_OPEN | typ == EV_IDLE_CLOSE);
    for k = 1:numel(idxRest)
        i = idxRest(k);
        st = pos(i);
        if ~isnan(dur(i)) && dur(i) > 0
            en = min(st + dur(i) - 1, nSamp);
        else
            en = min(st + segLen - 1, nSamp); % fallback
        end
        if en - st + 1 < segLen, continue; end

        % slide in non-overlapping 4 s chunks
        for ss = st : segLen : (en - segLen + 1)
            ee = ss + segLen - 1;

            if any(typ == EV_ARTIFACT & pos >= ss & pos <= ee)
                continue;
            end

            ep = sig(ss:ee, EEG_CH);
            if any(isnan(ep(:))), continue; end
            E{end+1} = ep; %#ok<AGROW>
            L(end+1,1) = 0; %#ok<AGROW>
        end
    end

    epochs = E;
    labels = L;
end
