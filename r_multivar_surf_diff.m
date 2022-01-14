function r_multivar_surf_diff(p,q,indir,outdir,instem_surf,outstem,gender_flag,halves_flag,skip_flag)
%function r_multivar_surf_diff(p,q,indir,outdir,[instem_surf],[outstem],[gender_flag],[halves_flag],[skip_flag])
%
% Created:  07/02/2018 by Don Hagler
% Prev Mod: 11/03/2018 by Don Hagler
% Last Mod: 11/06/2018 by Don Hagler
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~mmil_check_nargs(nargin,2), return; end;

if ~exist('indir','var') || isempty(indir)
  indir = '/space/md8/1/data/dhagler/work/projects/multivar_devel/data';
end;
if ~exist('outdir','var') || isempty(outdir)
  outdir = '/space/md8/1/data/dhagler/work/projects/multivar_devel/output_batch';
end;
if ~exist('instem_surf','var') || isempty(instem_surf)
  instem_surf = 'multivar_surf_data';
end;
if ~exist('outstem','var') || isempty(outstem)
  outstem = 'multivar_surf_surf_diff';
end;
if ~exist('gender_flag','var') || isempty(gender_flag)
  gender_flag = 0;
end;
if ~exist('halves_flag','var') || isempty(halves_flag)
  halves_flag = 0;
end;
if ~exist('skip_flag','var') || isempty(skip_flag)
  skip_flag = 0;
end;

fname_script = '/home/dhagler/R/mvd_array.R';
outfix = 'multivar_diff_stats';

randseed_flag = 1;
cleanup_flag = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hemilist = {'lh','rh'};
nsmooth = 10; % smoothing steps after resampling back to ico7
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
  gender_list = {'M','F'};
else
  outstem_list = {outstem};
  gender_list = {[]};
end;
if halves_flag
  o_list = [];
  g_list = [];
  h_list = [];
  for k=1:length(outstem_list)
    for j=1:2
      o_list{end+1} = sprintf('%s_H%d',outstem_list{k},j);
      g_list{end+1} = gender_list{k};
      h_list{end+1} = j;
    end;
  end;
  outstem_list = o_list;
  gender_list = g_list;
  half_list = h_list;
else
  half_list = cell(size(gender_list));
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subj_sets = [];
data_struct = [];
fname_info = sprintf('%s/%s_info.mat',outdir,outstem);
for k=1:length(outstem_list)
  ostem = sprintf('%s_v%04d_to_v%04d',outstem_list{k},p,q);
  fname_mat = sprintf('%s/%s.mat',outdir,ostem);
  if ~exist(fname_mat,'file') || forceflag || skip_flag

    fname_reg = sprintf('%s/%s_reg.csv',outdir,outstem_list{k});
    fname_dat = sprintf('%s/%s_data.dat',outdir,outstem_list{k});
    if ~exist(fname_dat,'file') || ~exist(fname_info,'file') || forceflag
      fname_surf_data = sprintf('%s/%s.mat',indir,instem_surf);
      data_struct = load(fname_surf_data);
    elseif exist(fname_info,'file')
      data_struct = load(fname_info);
    end;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % create sets of subjects to include in analysis
    if isempty(subj_sets)
      measlist = data_struct.measlist;
      nmeas = data_struct.nmeas;
      nverts = data_struct.nverts;
      nverts_hemi = data_struct.nverts_hemi;
      verts_hemi = data_struct.verts_hemi;
      VisitIDs = data_struct.VisitIDs;
      Gender = data_struct.Gender;
      nsubj = data_struct.nsubj;

      if gender_flag || halves_flag
        if gender_flag && ~halves_flag
          fname_sets = sprintf('%s/%s_gender_sets.mat',outdir,outstem);
        elseif gender_flag && halves_flag
          fname_sets = sprintf('%s/%s_gender_halves_sets.mat',outdir,outstem);
        elseif halves_flag
          fname_sets = sprintf('%s/%s_halves_sets.mat',outdir,outstem);
        end;
        if ~exist(fname_sets,'file') || forceflag
          % split by gender M/F
          if gender_flag
            ind_M = find(strcmp(Gender,'M'));
            ind_F = find(strcmp(Gender,'F'));
            subj_sets = {ind_M,ind_F};
          else
            subj_sets = {[1:nsubj]};
          end;
          % split into random halves
          if halves_flag
            t_sets = [];
            for j=1:length(subj_sets)
              ind_set = subj_sets{j};
              nvisits = length(ind_set);
              if randseed_flag, rng('shuffle'); end;
              ind_rand = randperm(nvisits);
              ind_half = round(nvisits/2);
              ind_h1 = ind_rand(1:ind_half);
              ind_h2 = ind_rand(ind_half+1:nvisits);
              t_sets{end+1} = sort(ind_set(ind_h1));
              t_sets{end+1} = sort(ind_set(ind_h2));
            end;
            subj_sets = t_sets;
          end;
          save(fname_sets,'subj_sets');
        else
          load(fname_sets);
        end;
      else
        subj_sets = {[1:nsubj]};
      end;
    end;
    
    ind_set = subj_sets{k};
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % save regressors to fname_reg
    if ~exist(fname_reg) || forceflag
      reg_data = [];
      for i=1:length(reg_labels)
        tag = reg_labels{i};
        reg_data = cat(2,reg_data,data_struct.(tag)');
      end;
      reg_data = cat(1,reg_labels,reg_data(ind_set,:));
      mmil_write_csv(fname_reg,reg_data);
    end;
    
    % write binary data for R with all vertices and measures
    if ~exist(fname_dat,'file') || forceflag
      fprintf('%s: saving data to %s...\n',mfilename,fname_dat);
      fid = fopen(fname_dat,'w');
      if fid<0, error('failed to open %s for writing',fname_dat); end;
      % write number of elements for each dimension
      surf_data = data_struct.surf_data(:,:,ind_set);
      volsz = size(surf_data);
      ndims = length(volsz);
      fwrite(fid,ndims,'integer*4');
      for i=1:ndims
        fwrite(fid,volsz(i),'integer*4');
      end;
      fwrite(fid,surf_data(:),'double');
      fclose(fid);
    end;
    
    if skip_flag, continue; end;
    
    % calculate difference statistics for each vertex to ever other vertex within each measure
    fprintf('%s: running analysis...\n',mfilename);
    tic;
    fname_out = sprintf('%s/%s_%s_F.dat',...
        outdir,ostem,outfix);
    if ~exist(fname_out,'file') || forceflag
      % call r_multivar_diff      
      stats = r_multivar_diff_array(p,q,fname_reg,fname_dat,...
        'fname_script',fname_script,...
        'outdir',outdir,...
        'outstem',ostem,...
        'outfix',outfix,...
        'gender_flag',~gender_flag,...
        'forceflag',forceflag);
    else
      % load binary data files
      stats.F = load_data(fname_out);
      fname_out = sprintf('%s/%s_%s_Pillai.dat',outdir,ostem,outfix);
      if exist(fname_out,'file')
        stats.Pillai = load_data(fname_out);
      end;
      fname_out = sprintf('%s/%s_%s_p.dat',outdir,ostem,outfix);
      if exist(fname_out,'file')
        stats.p = load_data(fname_out);
      end;
    end;
    toc;
    
    % store results as mat file
    fprintf('%s: saving output to %s...\n',mfilename,fname_mat);
    tic;
    Pillai = stats.Pillai;
    F = stats.F; % F-stat from likelihood ratio test
    P = -log10(stats.p); % pvalue  from likelihood ratio test
    save(fname_mat,'Pillai','F','P','p','q',...
      'measlist','nmeas','nverts','nverts_hemi','verts_hemi',...
      '-v7.3');
    toc;
  else
    fprintf('%s: output file %s already exists\n',mfilename,fname_mat);
  %  load(fname_mat);
  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data = load_data(fname_data)
  data = [];
  fid = fopen(fname_data,'r');
  if fid<0, error('failed to open %s for reading',fname_data); end;
  nd = fread(fid,1,'integer*4');
  vz = zeros(1,nd);
  for i=1:nd
    vz(i) = fread(fid,1,'integer*4');
  end;
  nv = prod(vz);
  d = fread(fid,nv,'double');
  fclose(fid);
  data = reshape(d,vz);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


