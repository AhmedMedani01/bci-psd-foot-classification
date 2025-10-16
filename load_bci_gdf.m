function [sig, hdr] = load_bci_gdf(gdfPath)
% LOAD_BCI_GDF  Read BCI IV 2a GDF using BioSig's sload.
% Notes: 22 EEG + 3 EOG channels (we'll pick EEG later).
%        Sample rate ~250 Hz. Events are in hdr.EVENT.* per spec.

    [sig, hdr] = sload(gdfPath);  % requires BioSig
    if ~isfield(hdr, 'EVENT') || ~isfield(hdr.EVENT, 'TYP')
        error('No events found in file: %s', gdfPath);
    end
end
