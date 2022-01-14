% Created:  02/01/15 by Don Hagler
% Prev Mod: 06/09/17 by Don Hagler
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
  'sm0' 'sm0' 'sm0'...
  'gwcsurf_wm_sm0' 'gwcsurf_wm_sm0' 'gwcsurf_wm_sm0' 'gwcsurf_wm_sm0' 'gwcsurf_wm_sm0' 'gwcsurf_wm_sm0'...
  'gwcsurf_gm_sm0' 'gwcsurf_gm_sm0' 'gwcsurf_gm_sm0' 'gwcsurf_gm_sm0' 'gwcsurf_gm_sm0' 'gwcsurf_gm_sm0'...
};
data_outstem_list = {...
  'thick' 'sulc' 'area'...
  'FA_wm' 'MD_wm' 'T2w_wm' 'LD_wm' 'TD_wm' 'T1w_wm'...
  'FA_gm' 'MD_gm' 'T2w_gm' 'LD_gm' 'TD_gm' 'T1w_gm'...
};
roidir = '/space/syn02/1/data/MMILDB/BACKUP/md7/1/pubsw/packages/freesurfer/RH4-x86_64-R530/subjects/fsaverage/label';
roi_instem = 'aparc';
roi_inext = '.annot';
roi_outext = '.mgh';
outdir = [pwd '/output/roi_summaries_MD1wg_aparc'];

roinames_sel = {'pericalcarine','caudalmiddlefrontal',...
                'rostralmiddlefrontal','transversetemporal'};

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

mmil_mkdir(outdir);

% set roi file names
fnames_roi = cell(nhemi,1);
parms.roinames = [];
nroi = []; i_roi = [];
for h=1:nhemi
  hemi = parms.hemilist{h};
  fname_roi = sprintf('%s/%s.%s%s',roidir,hemi,roi_instem,roi_inext);
  fname_roi_out = sprintf('%s/%s-%s%s',outdir,roi_instem,hemi,roi_outext);
  [roinums,roinames,ctab] = fs_read_annotation(fname_roi);
  nverts = length(roinums);
  nroi_all = length(roinames);
  if ~isempty(roinames_sel)
    [tmp,i_roi,i_sel] = intersect(roinames,roinames_sel);
    [i_sel,i_sort] = sort(i_sel);
    i_roi = i_roi(i_sort);
    roinames = roinames(i_roi);
  else
    i_roi = 1:nroi_all;
  end;
  if isempty(nroi)
    nroi = length(i_roi);
    parms.roinames = cell(nroi,nhemi);
  else
    if length(roinames)~=nroi
      error('number of ROIs does not match between hemispheres');
      %% NOTE: if this is the case, need to run each hemisphere separately
    end;
  end;
  if ~exist(fname_roi_out,'file') || parms.forceflag
    vals = zeros(nverts,nroi);
    for r=1:nroi
      k = find(roinums==i_roi(r));
      vals(k,r) = 1;
    end;
    vals = reshape(vals,[nverts,1,1,nroi]);
    fs_save_mgh(vals,fname_roi_out);
  end;
  fnames_roi{h} = fname_roi_out;
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

