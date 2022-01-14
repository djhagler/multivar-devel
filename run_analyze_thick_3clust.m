% Created:  02/01/15 by Don Hagler
% Prev Mod: 08/15/17 by Don Hagler
% Last Mod: 08/09/18 by Don Hagler

MRI_datadir = '/home/mmilrec4/MetaData/JER_PING/MRI_SurfStats';
DTI_datadir = '/home/mmilrec4/MetaData/JER_PING/DTI_SurfStats';
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
data_outstem_list = {...
  'thick' 'sulc' 'area'...
  'FA_wm' 'MD_wm' 'T2w_wm' 'LD_wm' 'TD_wm' 'T1w_wm'...
  'FA_gm' 'MD_gm' 'T2w_gm' 'LD_gm' 'TD_gm' 'T1w_gm'...
};
roidir = '/space/md8/1/data/dhagler/work/projects/multivar_devel/clusters/output/clusters_resurf';
roi_instem = 'thick_sm_clusters3';
roi_infix = 'ico7_sm10';
roi_inext = '.mgz';
roi_outext = '.mgh';
outdir = [pwd '/output/roi_summaries_thick_3clust'];

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
roistem = sprintf('%s_%s',roi_instem,roi_infix);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set roi file namess
fnames_roi = cell(nhemi,1);
parms.roinames = [];
nroi = [];
for h=1:nhemi
  hemi = parms.hemilist{h};
  fname_roi = sprintf('%s/%s-%s%s',roidir,roistem,hemi,roi_inext);
  fname_roi_out = sprintf('%s/%s-%s%s',roidir,roistem,hemi,roi_outext);
  if ~exist(fname_roi_out,'file') || parms.forceflag
    fs_copy_mgh(fname_roi,fname_roi_out);
  end;
  fnames_roi{h} = fname_roi_out;
  % load roinames
  fname_roi_labels = sprintf('%s/%s-%s-labels.csv',roidir,roistem,hemi);
  if exist(fname_roi_labels,'file')
    roi_labels = mmil_csv2struct(fname_roi_labels);
    roinames = {roi_labels.label};  
  else
    [M,volsz] = mmil_load_mgh_info(fname_roi,parms.forceflag,outdir);
    roinames = cellfun(@(x) sprintf('roi%d',x),num2cell([1:volsz(4)]),'UniformOutput',0);
  end;
  if isempty(nroi)
    nroi = length(roinames);
    parms.roinames = cell(nroi,nhemi);
  else
    if length(roinames)~=nroi
      error('number of ROIs does not match between hemispheres');
      %% NOTE: if this is the case, need to run each hemisphere separately
    end;
  end;
  parms.roinames(:,h) = roinames;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:nmeas
  data_type = data_type_list{i};
  data_instem = data_instem_list{i};
  switch data_type
    case 'MRI'
      datadir = MRI_datadir;
    case 'DTI'
      datadir = DTI_datadir;
  end;
  parms.measname = data_outstem_list{i};

  fprintf('%s: running analysis for %s...\n',mfilename,parms.measname);

  parms.outstem = sprintf('%s-%s_%s',data_type,parms.measname,roi_instem);
  % set data file names
  fnames_data = cell(nhemi,1);
  for h=1:nhemi
    hemi = parms.hemilist{h};
    fnames_data{h} = sprintf('%s/%s_%s_%s-%s.mgz',...
      datadir,data_instem,data_meas_list{i},data_infix_list{i},hemi);
  end;
  % load subjlist from data info file
  switch data_type
    case 'MRI'
      fname_data_info = sprintf('%s/%s_%s_info.csv',...
        datadir,data_instem,data_meas_list{i});
    case 'DTI'
      fname_data_info = sprintf('%s/%s_info.csv',...
        datadir,data_instem);
  end;
  data_info = mmil_csv2struct(fname_data_info);
  parms.subjlist = {data_info.VisitID};
  % calculate weighted averages for each ROI
  fprintf('%s: extracting values for ROIs...\n',mfilename);
  args = mmil_parms2args(parms);
  mmil_analyze_fuzzy_concat(fnames_data,fnames_roi,args{:});
end;

