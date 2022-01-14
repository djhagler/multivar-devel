instem_stem = 'multivar_MD1wg_sm_surf_surf_diff';
outstem_stem = 'distmat_MD1wg_sm_diff';
nbatches = 200;
niters = 10;
nhalves = 2;

for i=1:niters
  for j=1:nhalves
    instem = sprintf('%s%d_H%d',instem_stem,i,j);
    outstem = sprintf('%s%d_H%d',outstem_stem,i,j);
    create_distmat_multivar_diff_batch(instem,outstem,nbatches);
  end;
end;


