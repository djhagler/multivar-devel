function univvar_surf_surf_diff(indir,outdir,p,q,instem_surf,outstem,gender_flag,halves_flag)
%function univar_surf_surf_diff(indir,outdir,p,q,[instem_surf],[outstem]),[gender_flag],[halves_flag])
%
% Created:  05/08/2017 by Don Hagler
% Prev Mod: 05/08/2017 by Don Hagler
% Last Mod: 06/06/2017 by Don Hagler
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~mmil_check_nargs(nargin,2), return; end;

if ~exist('indir','var') || isempty(indir)
  indir = '/space/md8/1/data/dhagler/work/projects/multivar_devel/data_resid';
end;
if ~exist('outdir','var') || isempty(outdir)
  outdir = '/space/md8/1/data/dhagler/work/projects/multivar_devel/output_batch';
end;
if ~exist('instem_surf','var') || isempty(instem_surf)
  instem_surf = 'multivar_surf_data';
end;
if ~exist('outstem','var') || isempty(outstem)
  outstem = 'univar_surf_surf_diff';
end;
if ~exist('gender_flag','var') || isempty(gender_flag)
  gender_flag = 0;
end;
if ~exist('halves_flag','var') || isempty(halves_flag)
  halves_flag = 0;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hemilist = {'lh','rh'};
nsmooth = 10; % smoothing steps after resampling back to ico7
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
for k=1:length(outstem_list)
  fname_mat = sprintf('%s/%s_v%dto%d.mat',outdir,outstem_list{k},p,q);
  if ~exist(fname_mat,'file') || forceflag

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % create sets of subjects to include in analysis
    if isempty(subj_sets)
      % load surf data
      fname_surf_data = sprintf('%s/%s.mat',indir,instem_surf);
      surf_data = load(fname_surf_data);
      measlist = surf_data.measlist;
      nmeas = surf_data.nmeas;
      nverts = surf_data.nverts;
      nverts_hemi = surf_data.nverts_hemi;
      verts_hemi = surf_data.verts_hemi;
      VisitIDs = surf_data.VisitIDs;
      Ages = cell2mat(surf_data.Ages);
      Genders = surf_data.Genders;
      nsubj = length(VisitIDs);

      % split by gender M/F
      if gender_flag
        ind_M = find(strcmp(Genders,'M'));
        ind_F = find(strcmp(Genders,'F'));
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
          ind_rand = randperm(nvisits);
          ind_half = round(nvisits/2);
          ind_h1 = ind_rand(1:ind_half);
          ind_h2 = ind_rand(ind_half+1:nvisits);
          t_sets{end+1} = ind_h1;
          t_sets{end+1} = ind_h2;
        end;
        subj_sets = t_sets;
      end;
    end;
    
    ind_set = subj_sets{k};
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % calculate difference statistics for each vertex to ever other vertex within each measure
    fprintf('%s: running analysis...\n',mfilename);
    tic;
    nv = length(p:q);
    F = zeros(nv,nverts,nmeas);
    P = zeros(nv,nverts,nmeas);
    Fi = zeros(nv,nverts,nmeas);
    Pi = zeros(nv,nverts,nmeas);
    for i=p:q
      fprintf('%s: vertex %d...\n',mfilename,i);
      tic;
      age = Ages(ind_set)';
      for m=1:nmeas
        % calculate difference
        data1 = surf_data.surf_data(i,m,ind_set);
        data2 = surf_data.surf_data(:,m,ind_set);
        D = squeeze(bsxfun(@minus,data1,data2))';
        % run glm with age only
        X = mmil_glm_design(age);
        contrasts = mmil_glm_contrasts(age,'regnames',{'age'});
        glm_results = mmil_glm_calc(X,D,...
          'contrast_vectors',contrasts.contrast_vectors,...
          'contrast_names',contrasts.contrast_names);
        % store results for intercept
        Fi(i,:,m) = glm_results.contrasts(1).Fstat;
        Pi(i,:,m) = glm_results.contrasts(1).log10_pval;
        % store results for slope
        F(i,:,m) = glm_results.contrasts(2).Fstat;
        P(i,:,m) = glm_results.contrasts(2).log10_pval;
      end;
      toc;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fprintf('%s: saving output to %s...\n',mfilename,fname_mat);
    tic;
    save(fname_mat,'Fi','Pi','F','P','p','q',...
      'measlist','nmeas','nverts','nverts_hemi','verts_hemi','Ages','Genders',...
      '-v7.3');
    toc;
  else
    fprintf('%s: output file %s already exists\n',mfilename,fname_mat);
  %  load(fname_mat);
  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

