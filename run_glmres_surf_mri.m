indir = '/home/dhagler/mvdev/output/prep/data';
results_outdir = '/home/dhagler/mvdev/output/prep/output_glmres_surf_mri';
data_outdir = '/home/dhagler/mvdev/output/prep/data_resid';
instem = 'MRI';
indir_demog = '/space/md12/8/data/MMILDB/HAG_PING/analysis/PING/data';
instem_demog = 'PING_demog_150424';
outfix = 'resid';
%smoothing_list = 705;
smoothing_list = 1024;
suffix = '_ico4';
hemilist = {'lh','rh'};
forceflag = 0;

measlist = {'area','thick','sulc'};
%measlist = {'thick'};
reg_labels = {...
  'DeviceSerialNumber',...
  'GAF_africa','GAF_amerind','GAF_eastAsia','GAF_oceania','GAF_centralAsia',...
  'FDH_Highest_Education','FDH_3_Household_Income'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parms = [];
parms.reg_labels = reg_labels;
parms.statlist = {'mean'};
parms.outdir = results_outdir;
parms.categ_contrast_flag = 0;
parms.write_mgh_flag = 0;
parms.forceflag = forceflag;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mmil_mkdir(results_outdir);
mmil_mkdir(data_outdir);

for s=1:length(smoothing_list)
  smoothing = smoothing_list(s);
  for m=1:length(measlist)
    meas = measlist{m};
    
    % merge demographics and info
    fname_info = sprintf('%s/%s_%s_info.csv',...
      indir,instem,meas);
    fname_demog = sprintf('%s/%s.csv',...
      indir_demog,instem_demog);
    parms.fname_reg = sprintf('%s/%s_%s_%s.csv',...
      results_outdir,instem,meas,instem_demog);
    mmil_merge_csv(fname_info,fname_demog,parms.fname_reg,...
                    'VisitID',1,forceflag);

    % loop over hemispheres
    for h=1:length(hemilist)
      hemi = hemilist{h};
      % run glm
      parms.outstem = sprintf('%s_%s_sm%d%s',...
        instem,meas,smoothing,suffix);
      fname_data = sprintf('%s/%s_%s_sm%d%s-%s.mgz',...
        indir,instem,meas,smoothing,suffix,hemi);
      fprintf('%s: running GLM for %s-%s...\n',...
        mfilename,parms.outstem,hemi);
      args = mmil_parms2args(parms);
      results = mmil_glm(fname_data,args{:});

      fname_data_out = sprintf('%s/%s_%s_sm%d%s_%s-%s.mgz',...
        data_outdir,instem,meas,smoothing,suffix,outfix,hemi);
      fname_info_out = sprintf('%s/%s_%s_%s_info.csv',...
        data_outdir,instem,meas,outfix);
        
      if ~exist(fname_data_out,'file') ||...
         ~exist(fname_info_out,'file') || forceflag
        fprintf('%s: residualizing data...\n',mfilename);
        % load original data
        Y = fs_load_mgh(fname_data);
        Y = squeeze(Y);
        % remove excluded subjects
        Y = Y(:,results.ind_included);
        % calculate fit
        Yh = (results.X*results.betas)';
        % calculate baseline
        B = (results.contrasts(1).vec*results.betas)';
        % subtract fit from data and add baseline
        Yr = bsxfun(@plus,Y-Yh,B);
        % save residualized data
        Yr = reshape(Yr,[size(Yr,1),1,1,size(Yr,2)]);
        fs_save_mgh(Yr,fname_data_out);
        % write info file for selected subjects with Age and Gender
        if ~exist(fname_info_out,'file') || forceflag
          % load merged info
          tmp_info = mmil_csv2struct(parms.fname_reg);
          tmp_info = tmp_info(results.ind_included);
          new_info = struct('SubjID',{tmp_info.SubjID},...
                            'VisitID',{tmp_info.VisitID},...
                            'Age',{tmp_info.Age_At_IMGExam},...
                            'Gender',{tmp_info.Gender});
          mmil_struct2csv(new_info,fname_info_out);
        end;        
      end;
    end;
  end;
end;

