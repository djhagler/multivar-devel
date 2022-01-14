function multivar_compile_surf_data(varargin)
%function multivar_compile_surf_data(varargin)
%
% Created:  03/19/2019 by Don Hagler
%

parms = mmil_args2parms(varargin,{...
  'indir',[pwd '/data'],[],...
  'indir_demog','/space/md12/8/data/MMILDB/HAG_PING/analysis/PING/data',[],...
  'instem_demog','PING_demog_150424',[],...
  'outdir',[pwd '/data'],[],...
  'outstem','multivar_MD1wg_sm_surf_data',[],...
  'measlist',{'thick' 'area' 'sulc'...
    'FA_wm' 'LD_wm' 'TD_wm' 'T2w_wm' 'T1w_wm'...
    'FA_gm' 'LD_gm' 'TD_gm' 'T2w_gm' 'T1w_gm'},[],...
  'instem_list',{...
    'MRI_thick_sm1024_ico4'...
    'MRI_area_sm1024_ico4'...
    'MRI_sulc_sm1024_ico4'...
    'DTI_gwcsurf_FA_gwcsurf_wm_sm1024_ico4'...
    'DTI_gwcsurf_LD_gwcsurf_wm_sm1024_ico4'...
    'DTI_gwcsurf_TD_gwcsurf_wm_sm1024_ico4'...
    'DTI_gwcsurf_T2w_gwcsurf_wm_sm1024_ico4'...
    'DTI_gwcsurf_T1w_gwcsurf_wm_sm1024_ico4'...
    'DTI_gwcsurf_FA_gwcsurf_gm_sm1024_ico4'...
    'DTI_gwcsurf_LD_gwcsurf_gm_sm1024_ico4'...
    'DTI_gwcsurf_TD_gwcsurf_gm_sm1024_ico4'...
    'DTI_gwcsurf_T2w_gwcsurf_gm_sm1024_ico4'...
    'DTI_gwcsurf_T1w_gwcsurf_gm_sm1024_ico4'},[],...
  'info_list',{'MRI_thick_info'...
              'MRI_area_info'...
              'MRI_sulc_info'...
              'DTI_gwcsurf_info'...
              'DTI_gwcsurf_info'...
              'DTI_gwcsurf_info'...
              'DTI_gwcsurf_info'...
              'DTI_gwcsurf_info'...
              'DTI_gwcsurf_info'...
              'DTI_gwcsurf_info'...
              'DTI_gwcsurf_info'...
              'DTI_gwcsurf_info'...
              'DTI_gwcsurf_info'},[],...
  'reg_labels',{'Age_At_IMGExam','Gender','DeviceSerialNumber',...
    'GAF_africa','GAF_amerind','GAF_eastAsia','GAF_oceania','GAF_centralAsia',...
    'FDH_Highest_Education','FDH_3_Household_Income'},[],...
  'subjdir','/space/syn02/1/data/MMILDB/BACKUP/md7/1/pubsw/packages/freesurfer/RH4-x86_64-R530/subjects',[],...
  'subjname','fsaverage4',[],...
  'hemilist',{'lh','rh'},{'lh','rh'},...
  'forceflag',false,[false true],...
});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nhemi = length(parms.hemilist);
nmeas = length(parms.measlist);
nregs = length(parms.reg_labels);

mmil_mkdir(parms.outdir);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fname_out = sprintf('%s/%s.mat',parms.outdir,parms.outstem);
if ~exist(fname_out,'file') || parms.forceflag

  % specify demographics / regressors file
  fname_demog = sprintf('%s/%s.csv',parms.indir_demog,parms.instem_demog);

  output_struct = [];
  data_struct = [];
  VisitIDs = [];
  nverts_hemi = []; nverts = [];
  for m=1:nmeas
    meas = parms.measlist{m};
    instem = parms.instem_list{m};
    instem_info = parms.info_list{m};

    % merge info and demog files
    fname_info = sprintf('%s/%s.csv',parms.indir,instem_info);
    fname_merged = sprintf('%s/%s_%s.csv',...
      parms.outdir,instem_info,parms.instem_demog);
    fprintf('%s: merging info from %s and %s...\n',mfilename,fname_info,fname_demog);
    mmil_merge_csv(fname_info,fname_demog,fname_merged,'VisitID',1,parms.forceflag);
    
    % load merged file
    fprintf('%s: loading merged info from %s...\n',mfilename,fname_merged);
    tic;
    info_struct = mmil_csv2struct(fname_merged);  
    toc;
    
    % get VisitIDs
    tmp_VisitIDs = {info_struct.VisitID};
    if isempty(VisitIDs)
      VisitIDs = tmp_VisitIDs;
    else
      VisitIDs = intersect(VisitIDs,tmp_VisitIDs);
    end;
    data_struct(m).VisitIDs = tmp_VisitIDs;
    for k=1:nregs
      tag = parms.reg_labels{k};
      data_struct(m).(tag) = {info_struct.(tag)};
    end;
    nsubj = length(tmp_VisitIDs);

    % load data file
    vals = [];
    vals_hemi = cell(nhemi,1);
    nverts_hemi = zeros(nhemi,1);
    verts_hemi = cell(nhemi,1);
    for h=1:nhemi
      hemi = parms.hemilist{h};

      % load cortex label
      fname_label = sprintf('%s/%s/label/%s.cortex.label',parms.subjdir,parms.subjname,hemi);
      fprintf('%s: loading cortex label from %s...\n',mfilename,fname_label);
      tic;
      v_ctx = fs_read_label(fname_label);
      toc;
      
      fname_data = sprintf('%s/%s-%s.mgz',parms.indir,instem,hemi);
      fprintf('%s: loading data from %s...\n',mfilename,fname_data);
      tic;
      tvals = squeeze(fs_load_mgh(fname_data));
      toc;

      % exclude non-cortical vertices
      vals_hemi{h} = tvals(v_ctx,:);
      nverts_hemi(h) = length(v_ctx);
      % keep track of original vertex indices for each hemisphere
      verts_hemi{h} = v_ctx;
    end;      
    nverts = sum(nverts_hemi);

    % compile data across hemispheres
    vals = zeros(nverts,nsubj);
    j = 0;
    for h=1:nhemi
      i = j + 1;
      j = i + nverts_hemi(h) - 1;
      vals(i:j,:) = vals_hemi{h};
    end;
        
    data_struct(m).vals = vals;
  end;
  nsubj = length(VisitIDs);

  % merge across measures (intersection of VisitIDs)
  surf_data = zeros(nverts,nmeas,nsubj);
  for m=1:nmeas
    [tmp,idx] = intersect(data_struct(m).VisitIDs,VisitIDs);
    tmp_vals = data_struct(m).vals(:,idx);
    surf_data(:,m,:) = reshape(tmp_vals,[nverts,1,nsubj]);
    if m==1
      for k=1:nregs
        tag = parms.reg_labels{k};
        output_struct.(tag) = data_struct(m).(tag)(idx);
      end;
    end;
  end;
  output_struct.surf_data = surf_data;
  output_struct.VisitIDs = VisitIDs;
  output_struct.nsubj = nsubj;
  output_struct.nverts_hemi = nverts_hemi;
  output_struct.verts_hemi = verts_hemi;
  output_struct.nhemi = nhemi;
  output_struct.nverts = nverts;
  output_struct.nmeas = nmeas;
  output_struct.measlist = parms.measlist;

  % identify subjects with NA or [] for reg_labels
  i_excl = [];
  for k=1:nregs
    tag = parms.reg_labels{k};
    reg_vals =  output_struct.(tag);
    i_tmp = find(strcmp(reg_vals,'NA') | cellfun(@isempty,reg_vals));
    i_excl = union(i_excl,i_tmp);
  end;
  idx = setdiff([1:nsubj],i_excl);
  
  % exclude subjects with NA or [] for reg_labels
  if length(idx<nsubj)
    output_struct.surf_data = surf_data(:,:,idx);
    for k=1:nregs
      tag = parms.reg_labels{k};
      output_struct.(tag) = output_struct.(tag)(idx);
    end;
    output_struct.VisitIDs = VisitIDs(idx);
    output_struct.nsubj = length(idx);
  end;
  
  % save output struct
  fprintf('%s: saving compiled data to %s...\n',mfilename,fname_out);
  save(fname_out,'-struct','output_struct');
end;

