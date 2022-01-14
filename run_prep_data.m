rootdir = '/space/md8/1/data/dhagler/work/projects/multivar_devel';
indir = 'diff_ROI/data';
instem_reg = 'merged_broca_vs_premotor_plus_demog2';

fname_script = '/home/dhagler/R/prep_data.R';
instem = 'MDwg_aparc_sel';
forceflag = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fname_reg = sprintf('%s/%s/%s.csv',rootdir,indir,instem_reg);
if ~exist(fname_reg,'file')
  error('file %s not found',fname_reg);
end;

cmd = sprintf('R2.15 --vanilla --file=%s --args',fname_script);
cmd = sprintf('%s %s',cmd,instem);
if forceflag
  cmd = sprintf('%s TRUE',cmd);
else
  cmd = sprintf('%s FALSE',cmd);
end;

fprintf('%s\n',cmd);
[s,r] = unix(cmd);

if s
  error('cmd %s failed:\n%s',cmd,r);
else
  fprintf('%s\n',r);  
end;

