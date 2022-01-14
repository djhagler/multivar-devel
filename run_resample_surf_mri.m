indir = '/space/syn04/1/data/MMILDB/JER_PING/MetaData/MRI_SurfStats';
instem = 'MRI';
measlist = {...
  'thick' 'area' 'sulc'...
};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hemilist = {'lh','rh'};
outdir = [pwd '/data'];
%smoothing_list = [400 576 705 784 1024];
%smoothing_list = [705,1024];
smoothing_list = 1024;
ico = 4;
subj = 'fsaverage';
forceflag = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nhemi = length(hemilist);
nmeas = length(measlist);

tp = [];
tp.outdir = outdir;
tp.trgsubj = sprintf('fsaverage%d',ico);
%tp.icolevel = ico;
tp.subjdir = [getenv('FREESURFER_HOME') '/subjects'];
tp.verbose = 0;
tp.forceflag = forceflag;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mmil_mkdir(outdir);

for m=1:nmeas
  meas = measlist{m};
  for s=1:length(smoothing_list)
    smoothing = smoothing_list(s);
    for h=1:nhemi
      hemi = hemilist{h};
      % resample data
      fname_in = sprintf('%s/%s_%s_sm%d-%s.mgz',...
        indir,instem,meas,smoothing,hemi);
      tp.fname_out = sprintf('%s/%s_%s_sm%d_ico%d-%s.mgz',...
        outdir,instem,meas,smoothing,ico,hemi);
      args = mmil_parms2args(tp);
      fprintf('%s: resampling %s to ico %d...\n',mfilename,fname_in,ico);
      tic;
      fname_out = fs_surf2surf(fname_in,subj,args{:});
      toc;
    end;
  end;
  % copy info file
  fname_in_info = sprintf('%s/%s_%s_info.csv',...
    indir,instem,meas);
  fname_out_info = sprintf('%s/%s_%s_info.csv',...
    outdir,instem,meas);
  if ~exist(fname_out_info,'file') || forceflag
    [s,m] = copyfile(fname_in_info,fname_out_info);
    if ~s
      fprintf('%s: failed to copy file %s to %s:\n%s',...
        fname_in_info,fname_out_info,m);
    end;
  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


