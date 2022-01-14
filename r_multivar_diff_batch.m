function r_multivar_diff_batch(instem,outstem,batchname,gender_flag,halves_flag)
%function r_multivar_diff_batch(instem,outstem,batchname,gender_flag,halves_flag)
%

if ~exist('instem','var') || isempty(instem), instem = 'multivar_MDwg_surf_data'; end;
if ~exist('outstem','var') || isempty(outstem), outstem = 'multivar_MDwg_surf_surf_diff'; end;
if ~exist('batchname','var') || isempty(batchname), batchname = 'multivar_MDwg_diff'; end;
if ~exist('gender_flag','var') || isempty(gender_flag), gender_flag = 0; end;
if ~exist('halves_flag','var') || isempty(halves_flag), halves_flag = 0; end;

rootdir = '/space/md8/1/data/dhagler/work/projects/multivar_devel';
outdir = [rootdir '/diff_surf/output/diff_batch'];
indir = [rootdir '/prep/data'];
hemilist = {'lh','rh'};
nbatches = 200;
forceflag = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nhemi = length(hemilist);

mmil_mkdir(outdir);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if gender_flag
  outstem_list = {...
    [outstem '_M']...
    [outstem '_F']...
  };
else
  outstem_list = {outstem};
end;
if halves_flag
  o_list = [];
  for i=1:length(outstem_list)
    o_list{end+1} = sprintf('%s_H%d',outstem_list{i},i);
  end;
  outstem_list = o_list;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fname_info = sprintf('%s/%s_info.mat',outdir,outstem);
if ~exist(fname_info,'file') || forceflag
  fname_surf_data = sprintf('%s/%s.mat',indir,instem);
  fprintf('%s: loading data and info from %s...\n',mfilename,fname_surf_data);
  data_struct = load(fname_surf_data);
  % write info to mat file (without data)
  fprintf('%s: saving info to %s...\n',mfilename,fname_info);
  data_struct = rmfield(data_struct,'surf_data');
  save(fname_info,'-struct','data_struct');
end;
load(fname_info);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create output batch directory
root_batchdir = sprintf('%s/batchdirs',getenv('HOME'));
mmil_mkdir(root_batchdir);
batchdir = sprintf('%s/batchdirs/%s',getenv('HOME'),batchname);
scriptlistfname = sprintf('%s/scriptlist.txt',batchdir);
if exist(batchdir,'dir')
  cmd = sprintf('rm -rf %s\n',batchdir);
  fprintf('cmd = %s',cmd);
  [status,result] = unix(cmd);
  if status
    fprintf('%s: WARNING: cmd %s failed:\n%s',mfilename,cmd,result);
  end;
end;

% create scriptlist
mmil_mkdir(batchdir)
fid = fopen(scriptlistfname,'w');
if fid==-1
  error('failed to open scriptlist file %s for writing\n',scriptlistfname);
end;
fclose(fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create jobs
q = 0;
batch_size = ceil(nverts/nbatches);
for j=1:nbatches
  p = q + 1;
  if p>nverts, break; end;
  q = min(nverts,p + batch_size - 1);
  jstem = sprintf('v%dto%d',p,q);

  % run one job to create data files
  if j==1
    fprintf('%s: running first job to create shared data files...\n',mfilename);
    r_multivar_surf_diff(p,q,indir,outdir,instem,outstem,gender_flag,halves_flag,1);
  end;
  
  % determine whether a job is required
  run_flag = 0;
  for i=1:length(outstem_list)
    fname_out = sprintf('%s/%s_%s.mat',outdir,outstem_list{i},jstem);
    if ~exist(fname_out,'file') || forceflag
      run_flag = 1;
      break;
    end;
  end;
  if ~run_flag
    fprintf('%s: skipping %s (already completed)...\n',mfilename,jstem);
    continue;
  end;
  
  % create job
  fprintf('%s: creating job for %s...\n',mfilename,jstem);
  jobID = sprintf('job_%03d_%s',j,jstem);
  jobfname = sprintf('%s/%s.m',batchdir,jobID);
  fid = fopen(jobfname,'wt');
  fprintf(fid,'r_multivar_surf_diff(%d,%d,''%s'',''%s'',''%s'',''%s'',%d,%d);\n',...
    p,q,indir,outdir,instem,outstem,gender_flag,halves_flag);
  fprintf(fid,'exit;\n');
  fclose(fid);
  % add to list
  fid = fopen(scriptlistfname,'a');
  fprintf(fid,'%s\n',jobID);
  fclose(fid);
 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n%%%% now run this:\n');
fprintf('    qmatjobs4 %s\n',batchname);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


