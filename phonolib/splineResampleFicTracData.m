function resampled_signal = splineResampleFicTracData(frame_inds, fictrac_vals, n_samples)
    frame_inds = frame_inds - frame_inds(1) + 1;
    frame_inds_dup = [frame_inds];
    fictrac_vals_dup = [fictrac_vals]';
    resampled_signal = pchip(frame_inds_dup, fictrac_vals_dup, 1:n_samples);
end