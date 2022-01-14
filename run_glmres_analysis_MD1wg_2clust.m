indir = [pwd '/output/roi_summaries_MD1wg_2clust'];
infix = 'MD1wg_sm_clusters2';
indir_demog = '/space/md12/8/data/MMILDB/HAG_PING/analysis/PING/data';
instem_demog = 'PING_demog_150424';
results_outdir = [pwd '/output/output_glmres_MD1wg_2clust'];
data_outdir = [pwd '/output/roi_summaries_MD1wg_2clust_resid'];
merge_field = 'VisitID';
merge_outfix = 'plus_demog';
outfix = 'resid';
forceflag = 0;

measlist = {...
  'thick' 'sulc' 'area'...
  'FA_wm' 'MD_wm' 'T2w_wm' 'T1w_wm' 'LD_wm' 'TD_wm'...
  'FA_gm' 'MD_gm' 'T2w_gm' 'T1w_gm' 'LD_gm' 'TD_gm'...
};
reg_labels = {...
  'Gender'...
  'DeviceSerialNumber',...
  'GAF_africa','GAF_amerind','GAF_eastAsia','GAF_oceania','GAF_centralAsia',...
  'FDH_Highest_Education','FDH_3_Household_Income'};
age_label = 'Age_At_IMGExam';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parms = [];
parms.outstem = [];
parms.outdir = results_outdir;
parms.fname_reg = [];
parms.data_labels = [];
parms.reg_labels = reg_labels;
parms.statlist = {'mean','tstat','log10_pval'};
parms.plotflag = 0;
parms.forceflag = forceflag;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set name of regressor file
fname_reg = sprintf('%s/%s.csv',indir_demog,instem_demog);

% get list of input files
flist = dir(sprintf('%s/*I-*_%s.csv',indir,infix));

if isempty(flist)
  error('no matching files in %s with infix %s',indir,infix);
end;

for f=1:length(flist)
  fname_data = sprintf('%s/%s',indir,flist(f).name);

  % merge data and regressor files
  [tmp,fstem] = fileparts(fname_data);
  fname_resid = sprintf('%s/%s_%s.csv',data_outdir,fstem,outfix);
  if ~exist(fname_resid,'file') || forceflag
    parms.outstem = sprintf('%s_%s',fstem,outfix);

    % merge data and regressors
    fprintf('%s: merging data and regressors for %s...\n',mfilename,fstem);
    fname_merge = sprintf('%s/%s_%s.csv',data_outdir,fstem,merge_outfix);
    mmil_mkdir(data_outdir);
    mmil_merge_csv(fname_data,fname_reg,fname_merge,merge_field,0,forceflag);

    % load data file
    fprintf('%s: reloading merged data file...\n',mfilename);
    vals_all = mmil_readtext(fname_merge);
    all_labels = vals_all(1,:);

    ind_meas = find(~cellfun(@isempty,regexp(fstem,measlist)));
    meas = measlist{ind_meas};
    
    % find column headers matching meas
    ind_labels = find(~cellfun(@isempty,regexp(all_labels,meas)));
    parms.data_labels = all_labels(ind_labels);

    % run glm
    fprintf('%s: running GLM...\n',mfilename);
    args = mmil_parms2args(parms);
    results = mmil_glm_csv(fname_merge,args{:});

    % get subject IDs
    ind_ID = find(strcmp(all_labels,merge_field));
    IDs = vals_all(2:end,ind_ID);
    IDs = IDs(results.ind_included);

    % get age values
    ind_age = find(strcmp(all_labels,age_label));
    if isempty(ind_age), error('missing age column %s',age_label); end;
    age = vals_all(2:end,ind_age);
    % replace [] or string with NaN
    ind_bad = find(cellfun(@isempty,age) | cellfun(@ischar,age));
    if ~isempty(ind_bad)
      age(ind_bad) = num2cell(nan(size(ind_bad)));
    end;
    age = cell2mat(age);
    age = age(results.ind_included);

    % get parameters and data from results
    betas = results.betas;
    data = results.data;
    X = results.X;

    % calculate baseline values for each variable
    baseline = results.contrasts(1).vec*betas;

    % calculate residual
    residual = data - X*betas;
    
    % add baseline to residual
    residual = bsxfun(@plus,residual,baseline);

    % plot original values
    fname_out = sprintf('%s/%s_orig_vals.tif',parms.outdir,parms.outstem);
    if ~exist(fname_out,'file') || parms.forceflag
      figure; hold on; set(gcf,'visible','off');
      plot(age,data,'o');
      title('original values');
      xlabel('age')
      print(gcf,'-dtiff',fname_out); close(gcf);
    end;

    % plot residualized values
    fname_out = sprintf('%s/%s_resid_vals.tif',parms.outdir,parms.outstem);
    if ~exist(fname_out,'file') || parms.forceflag
      figure; hold on; set(gcf,'visible','off');
      plot(age,residual,'o');
      title('residualized values');
      xlabel('age')
      print(gcf,'-dtiff',fname_out); close(gcf);
    end;

    % save residualized values
    if ~exist(fname_resid,'file') || parms.forceflag
      labels = cat(2,{merge_field,age_label},parms.data_labels);
      vals_resid = cat(2,IDs,num2cell(age),num2cell(residual));
      vals_resid = cat(1,labels,vals_resid);
      % write output file
      mmil_write_csv(fname_resid,vals_resid);
    end;
  end;
end;

