batchname_stem = 'multivar_MD1wg_sm_diff_halves';
outstem_stem = 'multivar_MD1wg_sm_surf_surf_diff';
instem = 'multivar_MD1wg_sm_surf_data';
clustername = 'mmilcluster4';
gender_flag = 0;
halves_flag = 1;
niters = 10;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:niters
  batchname = sprintf('%s%d',batchname_stem,i);
  outstem = sprintf('%s%d',outstem_stem,i);
  fprintf('%s: making jobs for %s...\n',mfilename,outstem);
  r_multivar_diff_batch(instem,outstem,batchname,gender_flag,halves_flag);
  cmd = sprintf('ssh %s qmatjobs4 %s',clustername,batchname);
  fprintf('%s: submitting jobs to %s...\n',mfilename,clustername);
  fprintf('cmd: %s\n',cmd);
  [s,r] = unix(cmd);
  if s, error('cmd %s failed:\n%s',cmd,r); end;
  fprintf(r);
end;
