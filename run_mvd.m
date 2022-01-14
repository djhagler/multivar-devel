rootdir = '/space/md8/1/data/dhagler/work/projects/multivar_devel/diff_ROI';
indir = 'output';

fname_script = '/home/dhagler/R/mvd.R';
instem = 'MDwg_aparc_sel';
outdir = 'output/mvd';
outfix = 'multivar_diff_stats';

roinames = {...
  'pericalcarine'...
  'caudalmiddlefrontal'...
  'rostralmiddlefrontal'...
  'transversetemporal'...
};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fname_reg = sprintf('%s/%s/%s_multivar_reg.csv',rootdir,indir,instem);
if ~exist(fname_reg,'file')
  error('file %s not found',fname_reg);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Pillai = [];
F = [];
p = [];
roiA_list = [];
roiB_list = [];
roipairs = [];

k = 1;

for i=1:length(roinames)
  roiA = roinames{i};
  fname_datA = sprintf('%s/%s/%s_multivar_%s.csv',rootdir,indir,instem,roiA);
  if ~exist(fname_datA,'file')
    error('file %s not found',fname_datA);
  end;
  for j=i+1:length(roinames)
    roiB = roinames{j};
    fname_datB = sprintf('%s/%s/%s_multivar_%s.csv',rootdir,indir,instem,roiB);
    if ~exist(fname_datB,'file')
      error('file %s not found',fname_datB);
    end;
    
    % save data for roiA - roiB to csv file
    fname_roi_diff = sprintf('%s/%s_%s_vs_%s.csv',...
      outdir,instem,roiA,roiB);
    if ~exist(fname_roi_diff) || forceflag
      mmil_mkdir(outdir);
      dataA = mmil_readtext(fname_datA);
      dataB = mmil_readtext(fname_datB);
      measlist = dataA(1,:);
      dataA = cell2mat(dataA(2:end,:));
      dataB = cell2mat(dataB(2:end,:));
      data = dataA - dataB;
      data = cat(1,measlist,num2cell(data));
      mmil_write_csv(fname_roi_diff,data);
    end;
    
    outstem = sprintf('%s_%s_vs_%s',instem,roiA,roiB);
    stats = r_multivar_diff(fname_reg,fname_roi_diff,...
      'fname_script',fname_script,...
      'outdir',outdir,...
      'outstem',outstem,...
      'outfix',outfix);
    
    Pillai(k) = stats.Pillai;
    F(k) = stats.F;
    p(k) = stats.p;
    roiA_list{k} = roiA;
    roiB_list{k} = roiB;
    roipairs{k} = sprintf('%s_vs_%s',roiA,roiB);
    
    k = k + 1;
  end;
end;

