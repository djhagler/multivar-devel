% Created:  12/06/21 by Don Hagler
% Last Mod: 12/06/21 by Don Hagler

datadir = '/home/dhagler/mvdev/output/prep/data_resid';

data_type_list = {...
  'MRI' 'MRI' 'MRI'...
  'DTI' 'DTI' 'DTI' 'DTI' 'DTI' 'DTI'...
  'DTI' 'DTI' 'DTI' 'DTI' 'DTI' 'DTI'...
};
data_instem_list = {...
  'MRI' 'MRI' 'MRI'...
  'DTI_gwcsurf' 'DTI_gwcsurf' 'DTI_gwcsurf' 'DTI_gwcsurf' 'DTI_gwcsurf' 'DTI_gwcsurf'...
  'DTI_gwcsurf' 'DTI_gwcsurf' 'DTI_gwcsurf' 'DTI_gwcsurf' 'DTI_gwcsurf' 'DTI_gwcsurf'...
};
data_meas_list = {...
  'thick' 'sulc' 'area'...
  'FA' 'MD' 'T2w' 'LD' 'TD' 'T1w'...
  'FA' 'MD' 'T2w' 'LD' 'TD' 'T1w'...
};
data_infix_list = {...
  'sm1024' 'sm1024' 'sm1024'...
  'gwcsurf_wm_sm1024' 'gwcsurf_wm_sm1024' 'gwcsurf_wm_sm1024' 'gwcsurf_wm_sm1024' 'gwcsurf_wm_sm1024' 'gwcsurf_wm_sm1024'...
  'gwcsurf_gm_sm1024' 'gwcsurf_gm_sm1024' 'gwcsurf_gm_sm1024' 'gwcsurf_gm_sm1024' 'gwcsurf_gm_sm1024' 'gwcsurf_gm_sm1024'...
};
info_infix_list = {...
  'resid_info' 'resid_info' 'resid_info'...
  'gwcsurf_wm_resid_info' 'gwcsurf_wm_resid_info' 'gwcsurf_wm_resid_info' 'gwcsurf_wm_resid_info' 'gwcsurf_wm_resid_info' 'gwcsurf_wm_resid_info'...
  'gwcsurf_gm_resid_info' 'gwcsurf_gm_resid_info' 'gwcsurf_gm_resid_info' 'gwcsurf_gm_resid_info' 'gwcsurf_gm_resid_info' 'gwcsurf_gm_resid_info'...
};
data_outstem_list = {...
  'thick' 'sulc' 'area'...
  'FA_wm' 'MD_wm' 'T2w_wm' 'LD_wm' 'TD_wm' 'T1w_wm'...
  'FA_gm' 'MD_gm' 'T2w_gm' 'LD_gm' 'TD_gm' 'T1w_gm'...
};
data_suffix = 'ico4_resid';

roidir = '/space/md8/1/data/dhagler/work/projects/multivar_devel/clusters/output/clusters_resurf';
roi_instem = 'MD1wg_sm_clusters6';
roi_inext = '.mgz';
roi_outext = '.mgh';
outdir = '/home/dhagler/mvdev/output/extract';

indir_demog = '/home/dhagler/mvdev/data';
instem_demog = 'PING_demog_150424';
merge_field = 'VisitID';
merge_outfix = 'plus_demog';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parms = [];
parms.outdir = outdir;
parms.roistem = 'ctx';
parms.hemilist = {'lh','rh'};
parms.global_flag = 0;
parms.subjlabel = 'VisitID';
parms.forceflag = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nmeas = length(data_meas_list);
nhemi = length(parms.hemilist);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set roi file names
fnames_roi = cell(nhemi,1);
parms.roinames = [];
nroi = [];
for h=1:nhemi
  hemi = parms.hemilist{h};
  fname_roi = sprintf('%s/%s-%s%s',roidir,roi_instem,hemi,roi_inext);
  fname_roi_out = sprintf('%s/%s-%s%s',roidir,roi_instem,hemi,roi_outext);
  if ~exist(fname_roi_out,'file') || parms.forceflag
    fs_copy_mgh(fname_roi,fname_roi_out);
  end
  fnames_roi{h} = fname_roi_out;
  % load roinames
  fname_roi_labels = sprintf('%s/%s-%s-labels.csv',roidir,roi_instem,hemi);
  if exist(fname_roi_labels,'file')
    roi_labels = mmil_csv2struct(fname_roi_labels);
    roinames = {roi_labels.label};  
  else
    [M,volsz] = mmil_load_mgh_info(fname_roi,parms.forceflag,outdir);
    roinames = cellfun(@(x) sprintf('roi%d',x),num2cell([1:volsz(4)]),'UniformOutput',0);
  end
  if isempty(nroi)
    nroi = length(roinames);
    parms.roinames = cell(nroi,nhemi);
  else
    if length(roinames)~=nroi
      error('number of ROIs does not match between hemispheres');
      %% NOTE: if this is the case, need to run each hemisphere separately
    end
  end
  parms.roinames(:,h) = roinames;
end

% set name of regressor file
fname_reg = sprintf('%s/%s.csv',indir_demog,instem_demog);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:nmeas
  data_type = data_type_list{i};
  data_instem = data_instem_list{i};
  parms.measname = data_outstem_list{i};

  fprintf('%s: running extraction for %s...\n',mfilename,parms.measname);

  parms.outstem = sprintf('%s-%s_%s',data_type,parms.measname,roi_instem);
  % set data file names
  fnames_data = cell(nhemi,1);
  for h=1:nhemi
    hemi = parms.hemilist{h};
    fnames_data{h} = sprintf('%s/%s_%s_%s_%s-%s.mgz',datadir,...
      data_instem,data_meas_list{i},data_infix_list{i},data_suffix,hemi);
  end
  % load subjlist from data info file
  fname_data_info = sprintf('%s/%s_%s_%s.csv',...
    datadir,data_instem,data_meas_list{i},info_infix_list{i});
    
  data_info = mmil_csv2struct(fname_data_info);
  parms.subjlist = {data_info.VisitID};
  % extract values for each ROI
  fprintf('%s: extracting values for ROIs...\n',mfilename);
  args = mmil_parms2args(parms);
  mmil_extract_fuzzy_concat(fnames_data,fnames_roi,args{:});
  
  % merge data and regressors
  flist = dir(sprintf('%s/%s_*.csv',parms.outdir,parms.outstem));
  flist = {flist.name};
  flist = flist(cellfun(@isempty,regexp(flist,merge_outfix)));
  for f=1:length(flist)
    fname_out = sprintf('%s/%s',parms.outdir,flist{f});
    [fpath,fstem] = fileparts(fname_out);
    fname_merge = sprintf('%s/%s_%s.csv',parms.outdir,fstem,merge_outfix);
    if ~exist(fname_merge,'file') || parms.forceflag
      fprintf('%s: merging data and regressors for %s...\n',mfilename,fstem);
      mmil_merge_csv(fname_out,fname_reg,fname_merge,merge_field,0,parms.forceflag);
    end
  end
end

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

