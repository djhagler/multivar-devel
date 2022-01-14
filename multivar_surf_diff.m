function multivar_surf_surf_diff(indir,outdir,p,q,instem_surf,outstem,gender_flag,halves_flag)
%function multivar_surf_surf_diff(indir,outdir,p,q,[instem_surf],[outstem]),[gender_flag],[halves_flag])
%
% Created:  ? by Don Hagler
% Early Mod: 02/24/2017 by Don Hagler
% Prev Mod: 03/13/2017 by Don Hagler
% Last Mod: 06/06/2017 by Don Hagler
%
% NOTE: requires matlab version R2014b
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
  outstem = 'multivar_surf_surf_diff';
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
    F = zeros(nv,nverts);
    P = zeros(nv,nverts);
    Fi = zeros(nv,nverts);
    Pi = zeros(nv,nverts);
    model_spec = sprintf('%s%s~age',sprintf('%s,',measlist{1:end-1}),measlist{end});
    meas_table = table([1:nmeas]','VariableNames',{'Measurements'});
    var_names = cat(2,{'age'},measlist);
    for i=p:q
      fprintf('%s: vertex %d...\n',mfilename,i);
      tic;
      data1 = squeeze(surf_data.surf_data(i,:,ind_set))';
      for j=1:nverts
        % extract data for vertex
        data2 = squeeze(surf_data.surf_data(j,:,ind_set))';
        % calculate the difference
        data_diff = data1 - data2;
        % setup repeated measure model
        data_table = array2table(cat(2,Ages(ind_set)',data_diff),'VariableNames',var_names);
        rm = fitrm(data_table,model_spec,'WithinDesign',meas_table);
        % run manova
        fit  = manova(rm);
        % store results
        Fi(i,j) = fit.F(1); % F-stat from Pillai's trace for intercept
        Pi(i,j) = -log10(fit.pValue(1)); % pvalue from Pillai's trace for intercept
        F(i,j) = fit.F(5); % F-stat from Pillai's trace for age slope
        P(i,j) = -log10(fit.pValue(5)); % pvalue from Pillai's trace for age slope
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

