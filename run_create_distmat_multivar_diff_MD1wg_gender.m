instem_list = {...
  'multivar_MD1wg_sm_surf_surf_diff_F'...
  'multivar_MD1wg_sm_surf_surf_diff_M'...
};
outstem_list = {...
  'distmat_MD1wg_sm_diff_F'...
  'distmat_MD1wg_sm_diff_M'...
};
nbatches = 200;

for i=1:length(instem_list)
  instem = instem_list{i};
  outstem = outstem_list{i};
  create_distmat_multivar_diff_batch(instem,outstem,nbatches);
end;

