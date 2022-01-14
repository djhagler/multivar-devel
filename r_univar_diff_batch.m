function r_univar_diff_batch(instem,outstem,batchname,gender_flag,halves_flag)
%function r_univar_diff_batch(instem,outstem,batchname,gender_flag,halves_flag)
%

if ~exist('instem','var') || isempty(instem), instem = 'multivar_MDwg_surf_data'; end;
if ~exist('outstem','var') || isempty(outstem), outstem = 'univar_MDwg_surf_surf_diff'; end;
if ~exist('batchname','var') || isempty(batchname), batchname = 'univar_MDwg_diff'; end;
if ~exist('gender_flag','var') || isempty(gender_flag), gender_flag = 0; end;
if ~exist('halves_flag','var') || isempty(halves_flag), halves_flag = 0; end;

rootdir = '/space/md8/1/data/dhagler/work/projects/multivar_devel';
outdir = [rootdir '/diff_surf/output/diff_batch'];
indir = [rootdir '/prep/data'];
hemilist = {'lh','rh'};
nbatches = 200;
forceflag = 0;

reg_labels = {...
  'Age_At_IMGExam','Gender',...
  'DeviceSerialNumber',...
  'GAF_africa','GAF_amerind','GAF_eastAsia','GAF_oceania','GAF_centralAsia',...
  'FDH_Highest_Education','FDH_3_Household_Income'};

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save separate copies of info and data
for i=1:length(outstem_list)
  fname_mat = sprintf('%s/%s_info.mat',outdir,outstem_list{i});
  fname_dat = sprintf('%s/%s_data.dat',outdir,outstem_list{i});
  fname_reg = sprintf('%s/%s_reg.csv',outdir,outstem_list{i});
  if ~exist(fname_mat,'file') || ~exist(fname_reg,'file') ||...
     ~exist(fname_dat,'file') || forceflag
    fname_surf_data = sprintf('%s/%s.mat',indir,instem);
    fprintf('%s: loading data and info from %s...\n',mfilename,fname_surf_data);
    data_struct = load(fname_surf_data);
    surf_data = data_struct.surf_data;
    % write info to mat file (without data)
    fprintf('%s: saving info to %s...\n',mfilename,fname_mat);
    data_struct = rmfield(data_struct,'surf_data');
    save(fname_mat,'-struct','data_struct');
    % save regressors to fname_reg
    fprintf('%s: saving regressors to %s...\n',mfilename,fname_reg);
    reg_data = [];
    for i=1:length(reg_labels)
      tag = reg_labels{i};
      reg_data = cat(2,reg_data,data_struct.(tag)');
    end;
    reg_data = cat(1,reg_labels,reg_data);      
    mmil_write_csv(fname_reg,reg_data);
    % write matrix to binary file for R
    fprintf('%s: saving data to %s...\n',mfilename,fname_dat);
    fid = fopen(fname_dat,'w');
    if fid<0, error('failed to open %s for writing',fname_dat); end;
    % write number of elements for each dimension
    volsz = size(surf_data);
    ndims = length(volsz);
    fwrite(fid,ndims,'integer*4');
    for i=1:ndims
      fwrite(fid,volsz(i),'integer*4');
    end;
    fwrite(fid,surf_data(:),'double');
    fclose(fid);
    clear surf_data data_struct reg_data
  end;
end;
fname_mat = sprintf('%s/%s_info.mat',outdir,outstem_list{1});
load(fname_mat);

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
  
  % determine whether a job is required
  run_flag = 0;
  for i=1:length(outstem_list)
    fname_out = sprintf('%s/%s_%s.mat',outdir,outstem_list{i},jstem);
    if ~exist(fname_out,'file') || forceflag
      run_flag = 1;
      break;;
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
  fprintf(fid,'r_univar_surf_diff(%d,%d,''%s'',''%s'',''%s'',''%s'',%d,%d);\n',...
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


